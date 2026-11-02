// Diffs: loading one for a file, a stash, a commit or every change, and drawing
// it unified (one column) or split (before | after) in the main area.
//
// The panel doesn't draw diffs itself. Picking something posts it to
// shared("git-changes.view") under the space's id, and opens (or selects and
// renames) one tab per space whose only pane is this mod with props
// { role: "diff", space }. That tab reads the shared entry, so every later pick
// reuses it; closing the tab ends it, and the next pick makes a new one.
// The one/two-column choice is shared("git-changes.layout"), so both the
// panel's toggle and the tab's own reach every diff.
//
// diffRow() and the virtual-list layout come from Herdr's shipped `changes`
// mod (Apache-2.0). The before/after pairing follows the same rule as
// better-changes by Tawsif Aqib (https://github.com/munza/herdr-mods, Apache-2.0):
// replacements pair by position inside one block, never across a hunk or a
// context line. That code isn't used here; git.js has its own splitRows().
import { div, svg } from "gpui-kit";
import { v_flex, h_flex, Scrollbar, v_virtual_list } from "gpui-base";
import { exec, readTextFile, watchFolder, theme, settings, props, shared, setShared, spaces, panes, run, openOverlay } from "herdr";
import * as G from "./git.js";
import { icon } from "./menu.js";

const MAX = 5000;
const clip = (line) => (line.length > 4000 ? line.slice(0, 4000) + "… (line truncated)" : line);
const ROW = 20, HEAD = 24;
const mono = () => settings().font_family ?? "JetBrains Mono";

// Local change: review comments. Click diff rows to pick them, comment, and send every comment
// of the space to an agent. The `review` mod owns the comments (shared "review.comments") and
// the dialogs; the files-mods file tab adds comments to the same review.
const commentsOf = (space) => (shared("review.comments") ?? {})[space] ?? [];
const LINE_KINDS = new Set(["+", "-", " "]);
const rowKey = (r) => `${r.kind}${r.number}`;

async function untrackedLines(root, on, path) {
  const text = await readTextFile(`${root}/${path}`, { on }).catch(() => null);
  if (text === null) return ["Cannot preview this file (binary, too large, or unreadable)"];
  if (text.includes("\0")) return ["Binary file · no text diff"];
  if (!text) return ["Empty new file"];
  const n = G.countLines(text);
  return [`@@ -0,0 +1,${n} @@`, ...text.slice(0, 400000).replace(/\n$/, "").split("\n").slice(0, 3000).map((l) => `+${l}`)];
}

// The diff's lines, ready for G.diffRows. `untracked` lists the untracked paths an "all" diff shows too.
export async function loadDiff(item, { root, on, hasHead, untracked = [] }) {
  if (item.untracked) return untrackedLines(root, on, item.path);
  let lines = [];
  for (const args of G.diffArgs(item, hasHead)) {
    const r = await exec("git", [...G.READ, ...args], { cwd: root, on });
    if (r.code !== 0) throw new Error(G.gitError(r));
    lines.push(...r.stdout.replace(/\n$/, "").split("\n").filter((l, i, a) => l || i < a.length - 1));
  }
  if (item.area === "all") {
    for (const path of untracked.slice(0, 50)) lines.push(`diff --git a/${path} b/${path}`, ...(await untrackedLines(root, on, path)));
  }
  if (item.area === "file" && !lines.some((l) => l.startsWith("@@") || l.startsWith("Binary") || /^[-+ ]?Subproject/.test(l)))
    lines = [item.submodule ? `Submodule: ${item.submodule}` : item.binary ? "Binary file changed" : "No text diff available"];
  if (!lines.length) lines = ["No changes"];
  return lines.slice(0, MAX).map(clip);
}

export const itemTitle = (item) => item.area === "all" ? "All changes" : item.area === "stash" ? `${item.ref} · ${item.subject}`
  : item.area === "commit" ? `${item.short} · ${item.subject}` : item.path;
export const itemName = (item) => item.area === "all" ? "All changes" : item.area === "stash" ? item.ref
  : item.area === "commit" ? item.short : item.path.split("/").pop();
export const getLayout = () => (shared("git-changes.layout") === "split" ? "split" : "unified");
export const setLayout = (layout) => setShared("git-changes.layout", layout);

// Show `item` of the repository at { root, on } in this space's diff tab, making the tab if it's gone.
export function showInTab(spaceId, item, source) {
  const views = shared("git-changes.view") ?? {};
  const old = views[spaceId], tab = liveTab(spaceId, old?.tab);
  // Fast double picks: a tab asked for in the last 1.5 s is still coming.
  const opening = !tab && old?.opening && Date.now() - old.opening < 1500;
  // Entries of spaces that are gone are dropped on the way.
  const live = new Set(spaces().map((sp) => sp.id));
  const kept = Object.fromEntries(Object.entries(views).filter(([id]) => live.has(id)));
  setShared("git-changes.view", { ...kept, [spaceId]: { item: JSON.parse(JSON.stringify(item)), source, at: Date.now(), tab, opening: tab ? null : opening ? old.opening : Date.now() } });
  if (tab) { run("tab.rename", { id: tab, name: itemName(item) }); run("tab.select", { id: tab }); }
  else if (!opening) run("tab.new", { space: spaceId, name: itemName(item), mod: "git-changes", props: { role: "diff", space: spaceId } });
}

// The diff tab of a space, if it's still open. The tab writes its own id into its entry.
function liveTab(spaceId, id) {
  return id && spaces().find((s) => s.id === spaceId)?.tabs.some((t) => t.id === id) ? id : null;
}

export class DiffView {
  init(cx) {
    this.space = props().space;
    this.listId = `gc-diff-${Math.random().toString(36).slice(2)}`;
    this.rows = []; this.pairs = null; this.width = 300; this.offset = 0;
    this.sync(cx);
    // Picks arrive through shared state, which re-renders this copy; files change under it.
    cx.timer.every(10000, (cx) => this.reload(cx));
  }

  entry() { return (shared("git-changes.view") ?? {})[this.space]; }

  // Record this tab's id the first time it's seen, so the panel reuses it:
  // the tab in this space holding a git-changes pane, the shown one first.
  claim() {
    const e = this.entry();
    if (!e || e.tab) return;
    const space = spaces().find((s) => s.id === this.space);
    if (!space) return;
    const tabs = new Map(space.tabs.map((t) => [t.id, t]));
    const mine = panes().filter((p) => p.mod === "git-changes" && tabs.has(p.tab));
    const tab = (mine.find((p) => tabs.get(p.tab).active) ?? mine[0])?.tab;
    if (tab) setShared("git-changes.view", { ...(shared("git-changes.view") ?? {}), [this.space]: { ...e, tab, opening: null } });
  }

  sync(cx) {
    const e = this.entry();
    const id = e ? `${e.at}` : null;
    if (id === this.seen) return;
    this.seen = id;
    if (!e) { this.item = null; this.rows = []; this.pairs = null; return; }
    if (!e.tab) cx.spawn(async () => this.claim());
    this.item = e.item; this.root = e.source.root; this.on = e.source.on ?? null;
    this.rows = []; this.pairs = null; this.offset = 0; this.error = null; this.sel = null;
    if (this.root !== this.watched && !this.on) this.watch(this.root, cx);
    this.reload(cx);
  }

  watch(root, cx) {
    this.watched = root;
    cx.spawn(async (cx) => {
      try { while (this.watched === root) { await watchFolder(root); if (this.watched === root && this.item?.area !== "commit") this.reload(cx); } }
      catch { if (this.watched === root) this.watched = null; }
    });
  }

  reload(cx) {
    if (!this.item) return;
    if (this.loading) { this.again = true; return; }
    this.loading = true; this.again = false;
    const item = this.item, root = this.root, on = this.on, seen = this.seen;
    cx.spawn(async (cx) => {
      try {
        const git = (args) => exec("git", [...G.READ, ...args], { cwd: root, on });
        const head = await git(["rev-parse", "--verify", "-q", "HEAD"]);
        let untracked = [];
        if (item.area === "all") {
          const r = await git(["ls-files", "--others", "--exclude-standard", "-z"]);
          untracked = r.code === 0 ? r.stdout.split("\0").filter(Boolean) : [];
        }
        const lines = await loadDiff(item, { root, on, hasHead: head.code === 0, untracked });
        if (seen !== this.seen) return;
        this.rows = G.diffRows(lines, { headers: item.area !== "file" }); this.pairs = null; this.sel = null;
        this.width = Math.max(300, ...this.rows.map((r) => r.text.length * 7 + 20)); this.error = null;
      } catch (e) { if (seen === this.seen) this.error = String(e?.message ?? e); }
      // A pick that came in meanwhile asked for another load (`again`), or changed `seen`: load it now.
      finally { this.loading = false; cx.notify(); if (this.again || seen !== this.seen) this.reload(cx); }
    });
  }

  // --- drawing ----------------------------------------------------------------

  toggle(t, layout) {
    const cell = (id, name, tip, on) => h_flex().id(`gc-diff-${id}`).size(22).items_center().justify_center().rounded(5).cursor_pointer().tooltip(tip)
      .text_color(on ? t.accent : t.muted).when(on, (e) => e.bg(t.selected)).hover((s) => s.bg(on ? t.selected : t.hover))
      .on_click((_e, cx) => { setLayout(id); cx.notify(); })
      .child(svg(icon(name)).size(13));
    return h_flex().p(2).gap(2).flex_none().rounded(7).border_1().border_color(t.border)
      .child(cell("unified", "rows", "One column", layout === "unified"))
      .child(cell("split", "columns", "Two columns: before | after", layout === "split"));
  }

  // ---- review comments (local change) ----

  // Per row: its index and the file it belongs to (the nearest "f" header, else the picked file).
  meta() {
    if (this.metaFor !== this.rows) {
      this.metaFor = this.rows; this.index = new Map(); this.files = [];
      let file = this.item?.area === "file" ? this.item.path : "";
      this.rows.forEach((r, i) => { if (r.kind === "f") file = r.text; this.index.set(r, i); this.files[i] = file; });
    }
    return this;
  }

  // A click picks a row; another in the same file widens the pick to it; one inside clears it.
  pickRow(i, layout, cx) {
    const row = layout === "split" ? this.pairs?.[i] : this.rows[i];
    const entry = row?.kind === "pair" ? row.right ?? row.left : row;
    if (!entry || !LINE_KINDS.has(entry.kind)) return;
    const { index, files } = this.meta(), at = index.get(entry), s = this.sel;
    if (!s || files[s.from] !== files[at]) this.sel = { from: at, to: at };
    else if (at >= s.from && at <= s.to) this.sel = null;
    else this.sel = { from: Math.min(s.from, at), to: Math.max(s.to, at) };
    cx.notify();
  }

  picked() {
    const out = new Set();
    if (this.sel) for (let i = this.sel.from; i <= this.sel.to; i++) out.add(this.rows[i]);
    return out;
  }

  // Rows that already carry a comment, by file and kind+number.
  marked() {
    const { files } = this.meta(), keys = new Map(), out = new Set();
    for (const c of commentsOf(this.space)) if (c.kind === "diff" && c.root === this.root && c.keys) {
      if (!keys.has(c.path)) keys.set(c.path, new Set());
      for (const k of c.keys) keys.get(c.path).add(k);
    }
    if (keys.size) this.rows.forEach((r, i) => { if (LINE_KINDS.has(r.kind) && keys.get(files[i])?.has(rowKey(r))) out.add(r); });
    return out;
  }

  selLabel() {
    const rows = this.rows.slice(this.sel.from, this.sel.to + 1).filter((r) => LINE_KINDS.has(r.kind));
    const kept = rows.filter((r) => r.kind !== "-").map((r) => r.number), gone = rows.filter((r) => r.kind === "-").map((r) => r.number);
    const span = (a, word) => (a.length > 1 ? `${word}s ${Math.min(...a)}-${Math.max(...a)}` : `${word} ${a[0]}`);
    return kept.length ? span(kept, "line") : span(gone, "removed line");
  }

  comment(cx) {
    const { files } = this.meta(), path = files[this.sel.from], rows = this.rows.slice(this.sel.from, this.sel.to + 1);
    const lines = rows.filter((r) => LINE_KINDS.has(r.kind));
    const w = String(Math.max(...lines.map((r) => r.number))).length;
    const quote = rows.filter((r) => LINE_KINDS.has(r.kind) || r.kind === "@")
      .map((r) => (r.kind === "@" ? r.text : `${r.kind === " " ? " " : r.kind} ${String(r.number).padStart(w)}  ${r.text}`));
    openOverlay({ mod: "review", kind: "dialog", width: 620, height: 440, props: { mode: "add", space: this.space,
      comment: { kind: "diff", root: this.root, on: this.on, path, label: this.selLabel(), keys: lines.map(rowKey), quote } } });
    this.sel = null; cx.notify();
  }

  textButton(id, label, t, onClick, opts = {}) {
    return h_flex().id(id).h(24).px(9).flex_none().items_center().rounded(6).text_size(12).cursor_pointer()
      .bg(opts.solid ? t.solid : t.raised).border_1().border_color(opts.solid ? t.solid : t.border)
      .text_color(opts.solid ? t.solid_foreground : t.muted).hover((s) => s.opacity(0.85))
      .on_click((_e, cx) => onClick(cx)).child(label);
  }

  selBar(t) {
    const s = this.sel;
    return h_flex().h(32).flex_none().px(12).gap(8).items_center().border_b(1).border_color(t.border).text_size(12)
      .when(Boolean(s), (e) => e
        .child(div().font_semibold().child(this.selLabel()))
        .child(div().flex_1().min_w(0).truncate().text_color(t.dim).child("Click another line to widen · click the pick to clear"))
        .child(this.textButton("gc-sel-clear", "Clear", t, (cx) => { this.sel = null; cx.notify(); }))
        .child(this.textButton("gc-sel-comment", "Comment…", t, (cx) => this.comment(cx), { solid: true })))
      .when(!s, (e) => e.child(div().text_color(t.dim).child("Click a line to comment on it; click another to make it a range")));
  }

  // Local change: copy a file's path, relative to the repository root, from the diff tab.
  copyButton(t) {
    const path = this.item.path, done = this.copied === path;
    return h_flex().id("gc-diff-copy").size(22).flex_none().items_center().justify_center().rounded(5).cursor_pointer()
      .tooltip(done ? "Copied" : "Copy relative path").text_color(done ? t.ansi2 : t.muted)
      .hover((s) => s.bg(t.hover).text_color(done ? t.ansi2 : t.foreground))
      .on_click((_e, cx) => {
        cx.write_to_clipboard(path);
        this.copied = path; cx.notify();
        cx.timer.after(1500, (cx) => { if (this.copied === path) { this.copied = null; cx.notify(); } });
      })
      .child(svg(icon(done ? "check" : "copy")).size(13));
  }

  header(t, layout) {
    const add = this.rows.filter((r) => r.kind === "+").length, del = this.rows.filter((r) => r.kind === "-").length;
    const what = this.item.area === "commit" ? `Commit ${this.item.short} · ${this.item.author} · ${this.item.when}`
      : this.item.area === "stash" ? `Stash ${this.item.ref}` : "Working tree and index against HEAD";
    return v_flex().flex_none().border_b(1).border_color(t.border)
      .child(h_flex().h(38).px(12).gap(8).items_center()
        .child(svg(icon(this.item.area === "commit" ? "commit" : this.item.area === "stash" ? "stash" : "file")).size(14).flex_none().text_color(t.muted))
        .child(div().min_w(0).truncate().font_semibold().child(this.item.area === "commit" ? this.item.subject : itemTitle(this.item)))
        .when(this.item.area === "file", (e) => e.child(this.copyButton(t)))
        .child(div().flex_1())
        .when(add > 0, (e) => e.child(div().text_size(11.5).text_color(t.ansi2).child(`+${add}`)))
        .when(del > 0, (e) => e.child(div().text_size(11.5).text_color(t.ansi1).child(`−${del}`)))
        .when(commentsOf(this.space).length > 0, (e) => e.child(this.textButton("gc-review", `Review (${commentsOf(this.space).length})`, t,
          () => openOverlay({ mod: "review", kind: "dialog", width: 720, height: 600, props: { mode: "send", space: this.space } }), { solid: true })))
        .child(this.toggle(t, layout))
        .child(h_flex().id("gc-diff-close").size(24).items_center().justify_center().rounded(5).cursor_pointer().text_color(t.muted).tooltip("Close")
          .hover((s) => s.bg(t.hover).text_color(t.foreground))
          .on_click(() => { const tab = this.entry()?.tab; if (tab) run("tab.close", { id: tab }); })
          .child(svg(icon("x")).size(13))))
      .child(h_flex().h(22).px(12).gap(8).items_center().text_size(11).text_color(t.dim)
        .child(div().flex_1().min_w(0).truncate().child(`${what} · ${this.root}`))
        .child(div().child(this.loading ? "Loading…" : "")));
  }

  unifiedRow({ kind, old, number, text }, t) {
    if (kind === "f") return div().w_full().px(12).h(HEAD).flex_none().flex().items_center().truncate().bg(t.raised).border_t(1).border_color(t.border).font_semibold().text_color(t.foreground).child(text);
    if (kind === "@") return div().w_full().px(12).h(ROW).flex_none().truncate().bg(t.raised).text_color(t.dim).child(text);
    const color = kind === "+" ? t.ansi2 : kind === "-" ? t.ansi1 : t.foreground;
    const row = arguments[0], picked = this.hl?.picked.has(row), marked = this.hl?.marked.has(row);
    return h_flex().w_full().h(ROW).flex_none().gap(8).when(kind === "+" || kind === "-", (e) => e.bg(color + "18"))
      .when(Boolean(marked), (e) => e.bg(t.accent + "1c")).when(Boolean(picked), (e) => e.bg(t.selected))
      .child(div().w(38).flex_none().text_right().text_color(marked ? t.accent : t.dim).child(kind === "-" ? String(number) : kind === " " ? String(old) : ""))
      .child(div().w(38).flex_none().text_right().text_color(t.dim).child(kind === "+" || kind === " " ? String(number) : ""))
      .child(div().w(10).flex_none().text_color(color).child(kind === "+" || kind === "-" ? kind : ""))
      .child(div().flex_1().min_w(0).whitespace_nowrap().text_color(kind === " " ? t.foreground : color).child(text));
  }

  // One row of both columns. Both sides move by the same horizontal offset, so they stay lined up.
  splitRow(row, t) {
    if (row.kind !== "pair") return this.unifiedRow(row, t);
    const side = (entry, left) => {
      const kind = entry?.kind, color = kind === "+" ? t.ansi2 : kind === "-" ? t.ansi1 : t.foreground;
      const number = !entry ? "" : left ? String(kind === " " ? entry.old : entry.number) : String(entry.number);
      return h_flex().flex_1().min_w(0).h_full().gap(6).items_center().overflow_hidden()
        .when(!left, (e) => e.border_l(1).border_color(t.border))
        .when(kind === "+" || kind === "-", (e) => e.bg(color + "18")).when(!entry, (e) => e.bg(t.raised + "88"))
        .when(Boolean(entry && this.hl?.marked.has(entry)), (e) => e.bg(t.accent + "1c"))
        .when(Boolean(entry && this.hl?.picked.has(entry)), (e) => e.bg(t.selected))
        .child(div().w(38).flex_none().text_right().text_color(t.dim).child(number))
        .child(div().flex_1().min_w(0).overflow_hidden()
          .child(div().w(this.width).flex_none().ml(-this.offset).whitespace_nowrap().text_color(kind === " " ? t.foreground : color).child(entry?.text ?? "")));
    };
    return h_flex().w_full().h(ROW).flex_none().child(side(row.left, true)).child(side(row.right, false));
  }

  render(cx) {
    this.sync(cx);
    const t = theme(), layout = getLayout();
    const root = v_flex().id("git-changes-diff").size_full().min_h(0).bg(t.background).text_color(t.foreground).text_size(12.5);
    if (!this.item) return root.child(div().p(16).text_color(t.dim).child("Pick a file in Changes to see its diff here."));
    if (layout === "split" && !this.pairs) this.pairs = G.splitRows(this.rows);
    const rows = layout === "split" ? this.pairs : this.rows;
    const heights = rows.map((r) => (r.kind === "f" ? HEAD : ROW));
    this.hl = { picked: this.picked(), marked: this.marked() };
    const list = v_virtual_list(`${this.listId}-${layout}`, rows.length, heights, (i) => String(i),
      (range) => rows.slice(range.start, range.end).map((row) => (layout === "split" ? this.splitRow(row, t) : this.unifiedRow(row, t)))).size_full()
      .on_item_click((key, cx) => this.pickRow(Number(key), layout, cx));
    const body = div().flex_1().min_h(0).relative().font_family(mono()).text_size(12)
      .when(layout === "unified", (e) => e.child(div().id(`${this.listId}-x`).size_full().overflow_x_scrollbar()
        .child(div().w_full().min_w(this.width + 110).h_full().child(list))))
      // Split: one list for both columns keeps them level; sideways scrolling moves both texts.
      .when(layout === "split", (e) => e.child(div().id(`${this.listId}-split`).size_full()
        .on_scroll_wheel((ev, cx) => {
          const dx = ev.delta.x || (ev.modifiers?.shift ? ev.delta.y : 0);
          if (!dx) return;
          this.offset = Math.max(0, Math.min(Math.max(0, this.width - 200), this.offset - dx));
          cx.stop_propagation(); cx.notify();
        })
        .child(list)))
      .child(Scrollbar.vertical(`${this.listId}-${layout}`).viewport_from_layout().absolute().inset_0());
    return root.child(this.header(t, layout))
      .when(layout === "split", (e) => e.child(h_flex().h(22).flex_none().items_center().border_b(1).border_color(t.border).text_size(11).text_color(t.muted)
        .child(div().flex_1().px(12).child("Before")).child(div().flex_1().px(12).border_l(1).border_color(t.border).child("After"))))
      .when(Boolean(this.error), (e) => e.child(div().px(12).py(8).text_color(t.ansi1).child(this.error)))
      .child(this.selBar(t))
      .child(body);
  }
}

// What this space's diff tab shows, if it's open (or opening) on this repository.
export function shownIn(spaceId, root) {
  const e = (shared("git-changes.view") ?? {})[spaceId];
  if (!e || e.source.root !== root) return null;
  return liveTab(spaceId, e.tab) || (e.opening && Date.now() - e.opening < 1500) ? e.item : null;
}

// The repository a space's diff tab shows: a mod pane has no folder of its own.
export function shownSource(spaceId) {
  return (shared("git-changes.view") ?? {})[spaceId]?.source ?? null;
}
