// A lazy file browser for the focused pane's folder. Clicking a file opens it in a tab of its own
// in the main area; clicking a file that's already open selects its tab.
//
// Cloned from Herdr's `files`. Local changes: the click opens a file tab instead of a preview
// inside the panel; a mod pane (this file tab, git-changes' diff tab) keeps the folder it shows
// instead of falling back to the space's; the props role "view" is the file tab itself, with a
// button that copies the file's relative path (copy.svg and check.svg are Lucide's, ISC), and a
// Comment mode: the file as clickable lines, to comment on for the agent (the `review` mod).
// Markdown opens rendered (GitHub-flavored); the eye button shows its source. Shift-click in the
// panel opens the file in a pane beside the focused one instead of a tab (eye.svg is Lucide's).
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, Editor, EditorState, v_virtual_list, Scrollbar, TextView } from "gpui-base";
import { spaces, panes, focused, exec, readTextFile, watchFolder, theme, settings, window, props, shared, setShared, run, openOverlay } from "herdr";

// shared: { [space]: { [key]: { root, on, path, at, tab, opening } } }, one entry per file tab.
// `key` is in the tab's props; `tab` is the tab's id, which the tab records once it sees itself.
const VIEW = "files-mods.view";

// The space on screen: focused().space names it. A space's `active` flag can name another one
// (it read the local .dotfiles while a temis space was shown), so it's only the fallback.
const shownSpace = () => { const id = focused()?.space; return spaces().find(s => s.id === id) ?? spaces().find(s => s.active); };
const tabsOf = spaceId => { const v = (shared(VIEW) ?? {})[spaceId]; return v && typeof v.path !== "string" ? v : {}; };
const entryForTab = (spaceId, tab) => Object.values(tabsOf(spaceId)).find(e => e.tab === tab) ?? null;

// The folder of a mod pane, which has none of its own: what it shows.
function modFolder(pane, spaceId) {
  if (pane?.mod === "files-mods") { const e = entryForTab(spaceId, pane.tab); return e && { cwd: e.root, on: e.on ?? null }; }
  if (pane?.mod === "git-changes") { const s = (shared("git-changes.view") ?? {})[spaceId]?.source; return s && { cwd: s.root, on: s.on ?? null }; }
  return null;
}

function location() {
  const space = shownSpace(), f = focused();
  const pane = f?.pane ? panes().find(p => p.pane === f.pane) : null;
  const shown = modFolder(pane, space?.id);
  if (shown) return { cwd: shown.cwd, on: shown.on, space: space?.id };
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  return { cwd: pane?.cwd || f?.cwd || space?.folder, on, space: space?.id };
}
const key = () => JSON.stringify(location());
const LANG = { ts: "js", tsx: "js", mts: "js", cts: "js", jsx: "js", mjs: "js", toml: "yaml", jsonc: "json", svelte: "html", vue: "html" };
const PER_FOLDER = 500, TOTAL = 5000, MAX_TEXT = 400000, MAX_LINES = 20000, ROW = 20;

// The space's review comments (the `review` mod owns them and their dialogs).
const isMarkdown = path => /\.(md|markdown|mdx)$/i.test(path ?? "");
const PROSE_FONT = "Liberation Sans";
const commentsOf = space => (shared("review.comments") ?? {})[space] ?? [];
const openReview = space => openOverlay({ mod: "review", kind: "dialog", width: 720, height: 600, props: { mode: "send", space } });

async function directory(path, on) {
  if (!on && window()?.platform === "windows") {
    const r = await exec("powershell", ["-NoProfile", "-Command", "& { param($p) @(Get-ChildItem -LiteralPath $p -Force -ErrorAction Stop | Where-Object Name -ne '.git' | Select-Object -First 501 | ForEach-Object { @{ name=$_.Name; dir=($_.PSIsContainer -and -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)) } }) | ConvertTo-Json -Compress } '" + path.replaceAll("'", "''") + "'"]);
    if (r.code !== 0) throw new Error(r.stderr || "Cannot list this folder");
    const result = JSON.parse(r.stdout || "[]");
    return Array.isArray(result) ? result : [result];
  }
  const script = 'n=0; for p in "$1"/* "$1"/.[!.]* "$1"/..?*; do [ -e "$p" ] || [ -L "$p" ] || continue; name=${p##*/}; [ "$name" = .git ] && continue; if [ -d "$p" ] && [ ! -L "$p" ]; then kind=d; else kind=f; fi; printf "%s\\0%s\\0" "$kind" "$name"; n=$((n+1)); [ "$n" -gt 500 ] && break; done; test -d "$1"';
  const r = await exec("sh", ["-c", script, "files", path], { on });
  if (r.code !== 0) throw new Error(r.stderr || "Cannot list this folder");
  const fields = r.stdout.split("\0"), out = [];
  for (let i = 0; i + 1 < fields.length; i += 2) out.push({ name: fields[i + 1], dir: fields[i] === "d" });
  return out;
}

// ---- the file tab -----------------------------------------------------------------------------

// A tab id, if that tab is still open in the space.
function liveTab(spaceId, id) {
  return id && spaces().find(s => s.id === spaceId)?.tabs.some(t => t.id === id) ? id : null;
}

// Open `path` (relative to `root`, on machine `on`) in a tab of its own, or select its tab when it's
// already open. Entries of closed tabs and gone spaces are dropped on the way.
function showInTab(spaceId, root, on, path) {
  const all = shared(VIEW) ?? {}, live = new Set(spaces().map(s => s.id)), now = Date.now();
  const mine = Object.fromEntries(Object.entries(tabsOf(spaceId))
    .filter(([, e]) => liveTab(spaceId, e.tab) || (!e.tab && now - e.opening < 1500)));
  const same = Object.values(mine).find(e => e.root === root && (e.on ?? null) === on && e.path === path);
  const kept = Object.fromEntries(Object.entries(all).filter(([id]) => live.has(id) && id !== spaceId));
  if (same?.tab) { setShared(VIEW, { ...kept, [spaceId]: mine }); run("tab.select", { id: same.tab }); return; }
  // A tab asked for in the last 1.5 s is still coming: a fast double click opens one.
  if (same) { setShared(VIEW, { ...kept, [spaceId]: mine }); return; }
  const key = `${now.toString(36)}${Math.random().toString(36).slice(2, 6)}`;
  setShared(VIEW, { ...kept, [spaceId]: { ...mine, [key]: { root, on, path, at: now, tab: null, opening: now } } });
  run("tab.new", { space: spaceId, name: path.split("/").pop(), mod: "files-mods", props: { role: "view", space: spaceId, key } });
}

// The path the space's selected tab shows, if it's a file tab on this folder.
function shownIn(spaceId, root) {
  const tab = spaces().find(s => s.id === spaceId)?.tabs.find(t => t.active)?.id;
  const e = tab ? entryForTab(spaceId, tab) : null;
  return e && e.root === root ? e.path : null;
}

class FileView {
  init(cx) {
    // A split pane carries its file in its props; a tab's file is in shared state, under its key.
    this.space = props().space; this.key = props().key; this.split = props().split ? props() : null;
    this.showSource = false;
    this.listId = `fm-lines-${Math.random().toString(36).slice(2)}`;
    this.commenting = false; this.sel = null;
    this.sync(cx);
    // Remote files can't be watched; local ones are watched too, this is the backstop.
    cx.timer.every(10000, cx => this.reload(cx));
  }

  entry() {
    if (this.split) return { root: this.split.root, on: this.split.on ?? null, path: this.split.path, at: 0, tab: null };
    return this.key ? tabsOf(this.space)[this.key] : undefined;
  }

  // Record this tab's id once it's listed, so a click on the same file selects it: a file-tab pane
  // in this space whose tab no other entry has, the selected tab first (a new tab is selected).
  claim() {
    const e = this.entry();
    if (!e || e.tab) return;
    const space = spaces().find(s => s.id === this.space);
    if (!space) return;
    const tabs = new Map(space.tabs.map(t => [t.id, t])), all = tabsOf(this.space);
    const taken = new Set(Object.values(all).map(x => x.tab).filter(Boolean));
    const free = panes().filter(p => p.mod === "files-mods" && tabs.has(p.tab) && !taken.has(p.tab));
    const tab = (free.find(p => tabs.get(p.tab).active) ?? free[0])?.tab;
    if (tab) setShared(VIEW, { ...(shared(VIEW) ?? {}), [this.space]: { ...all, [this.key]: { ...e, tab, opening: null } } });
  }

  // A new pick arrives through shared state, which re-renders this copy.
  sync(cx) {
    const e = this.entry();
    const id = e ? `${e.at}` : null;
    if (id === this.seen) return;
    this.seen = id;
    if (!e) { this.path = null; this.release(); return; }
    this.root = e.root; this.on = e.on ?? null; this.path = e.path;
    this.text = null; this.lines = null; this.sel = null; this.error = null; this.release();
    const folder = `${this.root}/${this.path}`.replace(/\/[^/]*$/, "");
    if (!this.on && folder !== this.watched) this.watch(folder, cx);
    this.reload(cx);
  }

  release() { this.code?.release(); this.code = null; }

  watch(folder, cx) {
    this.watched = folder;
    cx.spawn(async cx => {
      try { while (this.watched === folder) { await watchFolder(folder); if (this.watched === folder) this.reload(cx); } }
      catch { if (this.watched === folder) this.watched = null; }
    });
  }

  reload(cx) {
    if (!this.path) return;
    if (this.loading) { this.again = true; return; }
    this.loading = true; this.again = false;
    const path = this.path, root = this.root, on = this.on, seen = this.seen;
    cx.spawn(async cx => {
      try {
        const text = await readTextFile(`${root}/${path}`, { on });
        if (seen !== this.seen) return;
        if (text === null) { this.error = "This file is no longer available"; this.release(); this.text = null; return; }
        if (text.includes("\0")) { this.error = "Binary file · no text preview"; this.release(); this.text = null; return; }
        // Unchanged: keep the editor, and with it the scroll position.
        if (text === this.text && this.code) return;
        this.text = text; this.lines = null; this.error = null; this.release();
        const t = theme(), ext = path.includes(".") ? path.split(".").pop() : "txt";
        this.code = EditorState.new({ language: LANG[ext] ?? ext, readonly: true,
          value: text.length > MAX_TEXT ? text.slice(0, MAX_TEXT) + "\n… (file truncated)" : text,
          font_family: settings().font_family, font_size: 12.5,
          syntax: { keyword: t.ansi5, string: t.ansi2, comment: t.dim, function: t.ansi4, type: t.ansi3, number: t.ansi1, constant: t.ansi6 } });
      } catch {
        if (seen === this.seen) { this.error = "Binary, too large, or unreadable · no text preview"; this.release(); this.text = null; }
      } finally {
        this.loading = false; cx.notify();
        if (this.again) this.reload(cx);
      }
    });
  }

  // The path relative to the folder the file was picked in (the repo root, usually).
  copyPath(cx) {
    const path = this.path;
    cx.write_to_clipboard(path);
    this.copied = path; cx.notify();
    cx.timer.after(1500, cx => { if (this.copied === path) { this.copied = null; cx.notify(); } });
  }

  copyButton(t) {
    const done = this.copied === this.path;
    return div().id("file-view-copy").size(22).flex_none().flex().items_center().justify_center().rounded(6).cursor_pointer()
      .text_color(done ? t.ansi2 : t.dim).hover(s => s.bg(t.hover).text_color(done ? t.ansi2 : t.foreground))
      .tooltip(done ? "Copied" : "Copy relative path").on_click((_e, cx) => this.copyPath(cx))
      .child(svg(`mods/files-mods/${done ? "check" : "copy"}.svg`).size(13));
  }

  // ---- comments ----

  // The file's lines for Comment mode, numbered from 1.
  fileLines() {
    if (!this.lines && this.text !== null && this.text !== undefined) {
      const all = this.text.replace(/\n$/, "").split("\n");
      this.lines = all.length > MAX_LINES ? [...all.slice(0, MAX_LINES), `… (${all.length - MAX_LINES} more lines not shown)`] : all;
      this.width = Math.min(4000, Math.max(...this.lines.slice(0, 5000).map(l => l.length), 20) * 7.4);
    }
    return this.lines ?? [];
  }

  // A click picks a line; another widens the pick to it; a click inside the pick clears it.
  pick(n, cx) {
    const s = this.sel;
    if (!s) this.sel = { from: n, to: n };
    else if (n >= s.from && n <= s.to) this.sel = null;
    else this.sel = { from: Math.min(s.from, n), to: Math.max(s.to, n) };
    cx.notify();
  }

  comment(cx) {
    const { from, to } = this.sel, lines = this.fileLines(), w = String(to).length;
    const quote = lines.slice(from - 1, to).map((l, i) => `${String(from + i).padStart(w)}  ${l}`);
    openOverlay({ mod: "review", kind: "dialog", width: 620, height: 440, props: { mode: "add", space: this.space,
      comment: { kind: "file", root: this.root, on: this.on, path: this.path, from, to, label: from === to ? `line ${from}` : `lines ${from}-${to}`, quote } } });
    this.sel = null; cx.notify();
  }

  // Lines that already carry a comment on this file.
  commented() {
    const set = new Set();
    for (const c of commentsOf(this.space)) if (c.kind === "file" && c.root === this.root && c.path === this.path)
      for (let n = c.from; n <= c.to; n++) set.add(n);
    return set;
  }

  textButton(id, label, t, onClick, opts = {}) {
    return h_flex().id(id).h(24).px(9).flex_none().items_center().rounded(6).text_size(12).cursor_pointer()
      .bg(opts.on ? t.selected : opts.solid ? t.solid : t.raised).border_1().border_color(opts.on ? t.accent : opts.solid ? t.solid : t.border)
      .text_color(opts.solid ? t.solid_foreground : opts.on ? t.foreground : t.muted).hover(s => s.opacity(0.85))
      .on_click((_e, cx) => onClick(cx)).child(label);
  }

  lineRow(n, text, t, marked) {
    const picked = this.sel && n >= this.sel.from && n <= this.sel.to;
    return h_flex().w_full().h(ROW).flex_none().gap(10).cursor_pointer()
      .when(picked, el => el.bg(t.selected)).when(!picked && marked.has(n), el => el.bg(t.accent + "14"))
      .child(div().w(46).flex_none().text_right().text_color(marked.has(n) ? t.accent : t.dim).child(String(n)))
      .child(div().flex_1().min_w(0).whitespace_nowrap().child(text));
  }

  commentBody(t) {
    const lines = this.fileLines(), marked = this.commented();
    const list = v_virtual_list(this.listId, lines.length, lines.map(() => ROW), i => String(i),
      range => lines.slice(range.start, range.end).map((l, k) => this.lineRow(range.start + k + 1, l, t, marked)))
      .size_full().on_item_click((key, cx) => this.pick(Number(key) + 1, cx));
    const s = this.sel;
    return v_flex().flex_1().min_h(0)
      .child(h_flex().h(32).flex_none().px(12).gap(8).items_center().border_b(1).border_color(t.border).text_size(12)
        .when(Boolean(s), el => el
          .child(div().font_semibold().child(s.from === s.to ? `Line ${s.from}` : `Lines ${s.from}-${s.to}`))
          .child(div().flex_1().min_w(0).truncate().text_color(t.dim).child("Click another line to widen · click the pick to clear"))
          .child(this.textButton("fm-sel-clear", "Clear", t, cx => { this.sel = null; cx.notify(); }))
          .child(this.textButton("fm-sel-comment", "Comment…", t, cx => this.comment(cx), { solid: true })))
        .when(!s, el => el.child(div().text_color(t.dim).child("Click a line to comment on it; click another to make it a range"))))
      .child(div().flex_1().min_h(0).relative().font_family(settings().font_family ?? "JetBrains Mono").text_size(12)
        .child(div().id(`${this.listId}-x`).size_full().overflow_x_scrollbar()
          .child(div().w_full().min_w(this.width + 80).h_full().child(list)))
        .child(Scrollbar.vertical(this.listId).viewport_from_layout().absolute().inset_0()));
  }

  // Markdown, rendered: GitHub-flavored, as the Notes panel shows a note.
  rendered(t) {
    return div().id("file-view-md").flex_1().min_h(0).overflow_y_scrollbar()
      .child(div().max_w(920).px(28).py(18).font_family(PROSE_FONT).text_size(14)
        .child(TextView.markdown("file-view-md-text", this.text.length > MAX_TEXT ? this.text.slice(0, MAX_TEXT) : this.text).selectable(true)));
  }

  close() {
    if (this.split) {
      const me = panes().find(p => p.mod === "files-mods" && p.focused);
      run("pane.close", me ? { pane: me.pane } : {});
      return;
    }
    const tab = this.entry()?.tab;
    if (!tab) return;
    const { [this.key]: _gone, ...rest } = tabsOf(this.space);
    setShared(VIEW, { ...(shared(VIEW) ?? {}), [this.space]: rest });
    run("tab.close", { id: tab });
  }

  render(cx) {
    this.sync(cx);
    // Until this tab has its id on record: the new pane may not be listed on the first draws.
    if (!this.split && this.entry() && !this.entry().tab) this.claim();
    const t = theme();
    const where = this.root ? `${this.on ? this.on + ":" : ""}${this.root}` : "";
    return v_flex().id("file-view").size_full().min_h(0).overflow_hidden().bg(t.background).text_color(t.foreground).text_size(13)
      .child(h_flex().h(38).flex_none().px(12).gap(8).items_center().border_b(1).border_color(t.border)
        .child(svg("mods/files-mods/file.svg").size(14).flex_none().text_color(t.muted))
        .child(div().min_w(0).truncate().font_semibold().child(this.path ?? "No file"))
        .when(Boolean(this.path), el => el.child(this.copyButton(t)))
        .child(div().flex_1())
        .when(isMarkdown(this.path) && this.text !== null && this.text !== undefined && !this.commenting, el => el.child(
          div().id("file-view-source").size(24).flex_none().flex().items_center().justify_center().rounded(6).cursor_pointer()
            .when(this.showSource, e => e.bg(t.selected).text_color(t.accent)).when(!this.showSource, e => e.text_color(t.dim))
            .hover(s => s.bg(t.hover)).tooltip(this.showSource ? "Show rendered" : "Show source")
            .on_click((_e, cx) => { this.showSource = !this.showSource; cx.notify(); })
            .child(svg("mods/files-mods/eye.svg").size(14))))
        .when(this.text !== null && this.text !== undefined, el => el.child(this.textButton("file-view-comment", "Comment", t,
          cx => { this.commenting = !this.commenting; this.sel = null; cx.notify(); }, { on: this.commenting })))
        .when(commentsOf(this.space).length > 0, el => el.child(this.textButton("file-view-review",
          `Review (${commentsOf(this.space).length})`, t, () => openReview(this.space), { solid: true })))
        .child(div().id("file-view-close").size(24).flex_none().flex().items_center().justify_center().rounded(6).cursor_pointer()
          .text_color(t.dim).hover(s => s.bg(t.hover).text_color(t.foreground)).on_click(() => this.close()).child("×")))
      .child(h_flex().h(22).flex_none().px(12).gap(8).items_center().border_b(1).border_color(t.border).text_size(11).text_color(t.dim)
        .child(div().flex_1().min_w(0).truncate().child(where))
        .when(Boolean(this.loading), el => el.child(div().child("Loading…"))))
      .child(this.commenting && this.text !== null && this.text !== undefined ? this.commentBody(t)
        : isMarkdown(this.path) && !this.showSource && this.text ? this.rendered(t)
        : this.code ? Editor.new(this.code).flex_1().min_h(0)
        : div().p(12).text_color(t.dim).child(this.error || (this.path ? "Loading file…" : this.key ? "Pick a file in the Files panel" : "Open this file again from the Files panel")));
  }
}

// ---- the panel --------------------------------------------------------------------------------

class Panel {
  init(cx) {
    this.saved = new Map();
    this.entries = new Map(); this.folders = new Set(); this.pending = new Set(); this.marks = {};
    this.refresh(cx);
    cx.timer.every(10000, cx => this.refresh(cx));
  }

  watch(root, cx) {
    if (this.on || this.watched === root) return;
    this.watched = root;
    const context = this.context;
    cx.spawn(async cx => {
      try { while (this.context === context) { await watchFolder(root); if (this.current(context)) this.refresh(cx); } }
      catch { if (this.context === context) this.watched = null; }
    });
  }

  current(context) {
    return this.context === context && key() === context.key;
  }

  async loadFolder(path, context) {
    const { on, cwd: root } = context;
    const entries = await directory(path ? `${root}/${path}` : root, on);
    if (!this.current(context) || (path && !this.folders.has(path))) return;
    const used = [...this.entries.entries()].filter(([p]) => p !== path).reduce((n, [, e]) => n + e.length, 0);
    this.entries.set(path, entries.slice(0, Math.max(0, Math.min(PER_FOLDER, TOTAL - used))).sort((a, b) => Number(b.dir) - Number(a.dir) || a.name.localeCompare(b.name)));
    if (entries.length > PER_FOLDER || used + entries.length > TOTAL) this.limited = true;
  }

  refresh(cx) {
    const { cwd, on, space } = location(), next = key();
    if (next !== this.context?.key) {
      if (this.context) this.saved.set(this.context.key, { folders: this.folders });
      const saved = this.saved.get(next);
      this.context = { key: next, cwd, on, space }; this.root = cwd; this.on = on; this.space = space;
      this.entries = new Map(); this.folders = new Set(saved?.folders);
      this.pending = new Set(); this.marks = {}; this.watched = null; this.error = null; this.limited = false;
      this.loading = false;
    }
    if (!cwd || this.loading) return;
    const context = this.context;
    this.loading = true;
    this.limited = false;
    cx.spawn(async cx => {
      try {
        for (const path of ["", ...this.folders]) {
          if (!this.current(context)) return;
          await this.loadFolder(path, context);
        }
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on }).catch(() => null);
        const marks = {};
        if (top?.code === 0) {
          // Writes nothing under .git (index lock, fsmonitor cookie): the folder watch would refresh again.
          const status = await exec("git", ["--no-optional-locks", "-c", "core.fsmonitor=false", "status", "--porcelain=v1", "-z", "--no-renames", "--untracked-files=normal"], { cwd, on }).catch(() => null);
          if (status?.code === 0) for (const entry of status.stdout.split("\0").filter(Boolean).slice(0, TOTAL)) {
            const xy = entry.slice(0, 2);
            marks[`${top.stdout.trim()}/${entry.slice(3)}`] = xy === "??" || xy.includes("A") ? "A" : xy.includes("U") ? "U" : xy.includes("D") ? "D" : "M";
          }
        }
        if (!this.current(context)) return;
        this.marks = marks; this.error = null; this.watch(cwd, cx);
      } catch (e) { if (this.current(context)) this.error = String(e); }
      finally { if (this.context === context) this.loading = false; cx.notify(); }
    });
  }

  toggle(path, cx) {
    if (this.folders.has(path)) {
      for (const folder of [...this.folders]) if (folder === path || folder.startsWith(path + "/")) {
        this.folders.delete(folder);
        this.entries.delete(folder);
      }
    } else {
      this.folders.add(path);
      if (!this.entries.has(path) && !this.pending.has(path)) {
        const context = this.context;
        this.pending.add(path);
        cx.spawn(async cx => {
          try { await this.loadFolder(path, context); }
          catch (e) { if (this.current(context)) this.error = String(e); }
          finally { if (this.context === context) this.pending.delete(path); cx.notify(); }
        });
      }
    }
    cx.notify();
  }

  // Shift-click: the file in a pane beside the focused one (right), not a tab of its own.
  open(path, cx, beside) {
    if (!this.space || !this.root) return;
    if (beside) run("pane.split", { direction: "right", mod: "files-mods",
      props: { role: "view", space: this.space, split: true, root: this.root, on: this.on ?? null, path } });
    else showInTab(this.space, this.root, this.on ?? null, path);
    cx.notify();
  }

  rows(prefix, depth, out, t, shown) {
    if (out.length >= TOTAL || depth > 40) return out;
    for (const entry of this.entries.get(prefix) ?? []) {
      if (out.length >= TOTAL) break;
      const path = prefix ? `${prefix}/${entry.name}` : entry.name, open = this.folders.has(path), mark = this.marks[`${this.root}/${path}`];
      const picked = !entry.dir && path === shown;
      out.push(h_flex().id(`file-${path}`).h(28).flex_none().pl(8 + depth * 18).pr(8).gap(7).items_center().rounded(7).cursor_pointer().hover(s => s.bg(t.hover))
        .when(picked, el => el.bg(t.selected).border_1().border_color(t.accent))
        .on_click((e, cx) => entry.dir ? this.toggle(path, cx) : this.open(path, cx, Boolean(e?.modifiers?.shift)))
        .child(entry.dir ? svg(`mods/files-mods/chevron-${open ? "down" : "right"}.svg`).size(12).flex_none().text_color(t.dim) : div().w(12).flex_none())
        .child(svg(`mods/files-mods/${entry.dir ? "folder" : "file"}.svg`).size(14).flex_none().text_color(t.muted))
        .child(div().flex_1().min_w(0).truncate().child(entry.name))
        .when(Boolean(mark), el => el.child(div().text_size(11).text_color(mark === "A" ? t.ansi2 : mark === "D" || mark === "U" ? t.ansi1 : t.blocked).child(mark))));
      if (entry.dir && open) this.rows(path, depth + 1, out, t, shown);
    }
    return out;
  }

  render(cx) {
    if (key() !== this.context?.key) this.refresh(cx);
    const t = theme(), shown = this.space && this.root ? shownIn(this.space, this.root) : null;
    return v_flex().id("files").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13)
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Files"))
        .child(div().flex_1().min_w(0).truncate().text_right().text_size(12).text_color(t.dim).child(this.root?.split(/[\\/]/).pop() ?? "")))
      .child(v_flex().id("files-tree").flex_1().min_h(0).overflow_y_scrollbar().p(6).children(this.rows("", 0, [], t, shown))
        .when(Boolean(this.error) || !this.entries.get("")?.length, el => el.child(div().p(8).text_size(12).text_color(t.dim).child(this.error || (this.loading ? "Loading files…" : this.root ? "No files" : "No folder"))))
        .when(this.limited, el => el.child(div().p(8).text_size(11).text_color(t.dim).child("File list limited to 500 entries per folder and 5,000 total"))));
  }
}

export default class Files extends View {
  init(_props, cx) {
    this.part = props()?.role === "view" ? new FileView() : new Panel();
    this.part.init(cx);
  }

  render(cx) { return this.part.render(cx); }
}
