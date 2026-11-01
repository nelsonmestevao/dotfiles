// Changes, for code review: the diff rows are syntax colored (highlight.js,
// palette.js), and the diff is reviewed like a pull request: click a line
// (two clicks for a range, a @@ header for its hunk) to open the comment
// box, add the comment, and it sits inline under those lines; comments can be
// added on several files; the comment icon on a file row comments on the
// file as a whole (an image, a deleted file). "Submit
// review" sends every comment with its
// lines to the space's agent as one message (ask.js); right-click a line to
// ask about it at once instead. Esc closes the comment box.
// The comment box is a card floating over the top-right of the diff (a
// strip under it when the panel is narrow), so the rows never move: a
// list row may hold no input, so the box can't sit between the lines.
// Keys: "reviewer.submit", "reviewer.ask" (about the whole
// diff), "reviewer.clear" (drops the draft comments); in the send
// dialog (dialog.js) "reviewer.send" and "reviewer.close".
// The header's scope picker chooses what is reviewed: the uncommitted
// changes, the last commit plus them, or everything on the branch since it
// left its base (the pull-request view); "reviewer.scope" cycles it.
// Props: { palette: "one-dark-pro" | "theme" | "dark-plus" (default: one-dark-pro),
//          font_size: px (default: the terminal's font size minus one),
//          base: the branch reviews are against (default: origin/HEAD, else main, else master) }.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, TextareaState, Textarea, Scrollbar, v_virtual_list, VirtualListScrollHandle, Popover } from "gpui-base";
import { spaces, panes, focused, exec, readTextFile, watchFolder, theme, settings, nextCommand, props, shared, setShared } from "herdr";
import { tokenize, languageOf } from "./highlight.js";
import { ask } from "./ask.js";
import { palette } from "./palette.js";
import { Dialog } from "./dialog.js";

function location() {
  const space = spaces().find((s) => s.active), f = focused();
  const pane = f?.pane ? panes().find(p => p.pane === f.pane) : null;
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  return { cwd: pane?.cwd || f?.cwd || space?.folder, on };
}
const key = () => JSON.stringify(location());
const countLines = (text) => text ? text.split("\n").length - Number(text.endsWith("\n")) : 0;
const NONE = "#00000000", SENT = "reviewer.sent", DRAFTS = "reviewer.drafts", SCOPE = "reviewer.scope";
// The review scopes, in picker order. `ref` is what the working tree is diffed against.
const SCOPES = ["work", "last", "branch"];
// The code font: the terminal's (`font` in settings, JetBrains Mono when
// unset), one size smaller than the terminal (`font_size`, 14 when unset);
// `props.font_size` overrides. Rows and widths scale with it.
const codeFont = () => (typeof settings().font === "string" && settings().font) || "JetBrains Mono";
const codeSize = () => Number(props()?.font_size) || Math.max(9, (Number(settings().font_size) || 14) - 1);
const rowOf = (size) => Math.round(size * 1.8);
const charOf = (size) => size * 0.62;

// A row's identity across reloads: its kind, number and text.
const desc = (r) => ({ kind: r.kind, number: r.number ?? null, text: r.text });
const descKey = (d) => `${d.kind}|${d.number}|${d.text}`;

// Numbers each diff line once and tokenizes it, so a frame only draws the rows on screen.
function diffRows(lines, lang) {
  let old = 0, next = 0, state = null, hunk = -1;
  return lines.map((line, i) => {
    const match = /^@@ -(\d+)(?:,\d+)? \+(\d+)/.exec(line);
    if (match) { old = +match[1]; next = +match[2]; state = null; hunk = i; return { kind: "@", text: line, hunk: i, spans: [{ text: line, cls: "" }] }; }
    const kind = line[0];
    let row;
    if (kind === "-") row = { kind, number: old++, text: line.slice(1) || " " };
    else if (kind === "+") row = { kind, number: next++, text: line.slice(1) || " " };
    else if (kind === " ") { old++; row = { kind, number: next++, text: line.slice(1) || " " }; }
    else row = { kind: "", text: line };
    row.hunk = hunk;
    const t = tokenize(row.text.replace(/\t/g, "    "), lang, state);
    row.spans = t.spans; state = t.state;
    return row;
  });
}

export default class Changes extends View {
  init(_props, cx) {
    // Opened as the send dialog (ask.js): this copy is the dialog, nothing else.
    if (props()?.dialog) { this.dialog = Object.create(Dialog.prototype); this.dialog.init(_props, cx); return; }
    this.files = []; this.rows = []; this.index = new Map(); this.items = []; this.sizes = []; this.diffWidth = 0; this.gutter = 30; this.message = "";
    this.comments = []; this.composer = null; this.handle = cx.focus_handle(); this.scroll = VirtualListScrollHandle.new();
    this.fontSize = codeSize(); this.row = rowOf(this.fontSize);
    this.scope = "work"; this.scopeInfo = null; this.choosingScope = false; this.ref = "HEAD";
    this.input = InputState.new({ placeholder: "Commit message" });
    this.input.on("change", (_e, cx) => {
      const hadMessage = Boolean(this.message.trim());
      this.message = this.input.value();
      if (hadMessage !== Boolean(this.message.trim())) cx.notify();
    });
    this.input.on("submit", (_e, cx) => this.commit(cx));
    this.input.on("focus", (_e, cx) => { this.typing = true; cx.notify(); });
    this.input.on("blur", (_e, cx) => { this.typing = false; cx.notify(); });
    this.note = TextareaState.new({ placeholder: "Leave a comment on these lines…", rows: 4 });
    this.note.set_auto_grow(4, 14);
    // Enter adds; shift-enter is the textarea's own newline, so its submit is ignored.
    this.note.on("submit", (e, cx) => { if (!e?.shift) this.addComment(cx); });
    this.note.on("change", (_e, cx) => { this.noteText = this.note.value(); if (this.composer?.editing) this.rebuild(); cx.notify(); });
    this.noteText = "";
    this.refresh(cx);
    cx.timer.every(10000, (cx) => this.refresh(cx));
    cx.spawn(async (cx) => {
      for (;;) {
        const c = await nextCommand();
        if (c === "ask") this.askAbout(null, cx);
        else if (c === "submit") this.submit(cx);
        else if (c === "clear") this.setComments([], cx);
        else if (c === "scope") this.cycleScope(cx);
        cx.notify();
      }
    });
  }

  watch(root, cx) {
    if (this.on || this.watched === root) return;
    this.watched = root;
    cx.spawn(async (cx) => {
      try {
        while (this.watched === root) {
          await watchFolder(root);
          if (this.watched === root) this.refresh(cx);
        }
      } catch { this.watched = null; }
    });
  }

  refresh(cx) {
    if (this.loading || this.busy) return;
    const { cwd, on } = location(), context = key();
    if (context !== this.context) {
      this.context = context; this.root = null; this.files = []; this.open = null; this.comments = []; this.composer = null;
      this.setLines([]); this.message = ""; this.input.set_value(""); this.error = null; this.note_ = null; this.watched = null; this.closed = false; this.limited = false;
    }
    if (!cwd) return;
    this.loading = true;
    cx.spawn(async (cx) => {
      try {
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on });
        if (key() !== context) return;
        if (top.code !== 0) { this.root = null; this.files = []; this.setLines([]); this.open = null; this.error = "Not a git repository"; return; }
        const root = top.stdout.trim(), git = (args) => exec("git", args, { cwd: root, on });
        const status = await git(["status", "--porcelain=v1", "-z", "--no-renames", "--untracked-files=all"]);
        if (status.code !== 0) throw new Error(status.stderr);
        const head = await git(["rev-parse", "--verify", "HEAD"]);
        const hasHead = head.code === 0;
        // The scopes this repo offers, and the one in use (remembered per repo).
        const info = hasHead ? await this.scopes(git) : { branch: null, base: null, last: null, merge: null };
        const scopeKey = `${on ?? ""}:${root}`, remembered = (shared(SCOPE) ?? {})[scopeKey];
        let scope = root === this.root ? this.scope : (remembered ?? (info.merge ? "branch" : "work"));
        if (scope === "branch" && !info.merge) scope = "work";
        if (scope === "last" && !info.last) scope = "work";
        const ref = scope === "branch" ? info.merge : scope === "last" ? `${info.last}~1` : "HEAD";
        // Files: what differs from the scope's ref, plus untracked files and conflicts from the status.
        const stats = {}, changed = new Map();
        const results = hasHead ? [await git(["diff", ref, "--numstat", "-z", "--no-renames"])] : [await git(["diff", "--cached", "--numstat", "-z", "--no-renames"]), await git(["diff", "--numstat", "-z", "--no-renames"])];
        for (const result of results) {
          if (result.code !== 0) throw new Error(result.stderr);
          for (const entry of result.stdout.split("\0")) {
            const [a, d, ...parts] = entry.split("\t");
            if (!parts.length) continue;
            const path = parts.join("\t"), old = stats[path] ?? { add: 0, del: 0 };
            stats[path] = { add: old.add + (Number(a) || 0), del: old.del + (Number(d) || 0), binary: a === "-" };
          }
        }
        if (hasHead) {
          const names = await git(["diff", ref, "--name-status", "-z", "--no-renames"]);
          if (names.code !== 0) throw new Error(names.stderr);
          const parts = names.stdout.split("\0");
          for (let i = 0; i + 1 < parts.length && parts[i]; i += 2) changed.set(parts[i + 1], parts[i][0]);
        }
        const entries = status.stdout.split("\0").filter(Boolean);
        for (const entry of entries) {
          const xy = entry.slice(0, 2), path = entry.slice(3);
          if (xy === "??") changed.set(path, "?");
          else if (xy.includes("U") || xy === "AA" || xy === "DD") changed.set(path, "U");
          else if (!hasHead) changed.set(path, xy.includes("D") ? "D" : xy.includes("A") ? "A" : "M");
        }
        const files = [];
        for (const [path, s0] of [...changed.entries()].sort((a, b) => a[0].localeCompare(b[0])).slice(0, 1000)) {
          const fresh = s0 === "?", s = fresh ? "A" : s0 === "D" || s0 === "A" || s0 === "U" ? s0 : "M";
          const stat = stats[path] ?? { add: 0, del: 0 };
          files.push({ path, status: s, fresh, ...stat });
        }
        if (key() !== context) return;
        if (root !== this.root || scope !== this.scope || ref !== this.ref) { this.setLines([]); }
        const changedSet = root !== this.root || scope !== this.scope;
        this.root = root; this.on = on; this.hasHead = hasHead; this.scope = scope; this.scopeInfo = info; this.ref = ref;
        // Each scope keeps its own comments: switching swaps the set, the others stay saved.
        if (changedSet) { this.comments = this.loadDrafts(scope); this.composer = null; }
        this.files = files; this.limited = changed.size > 1000; this.error = null;
        this.watch(root, cx);
        if (this.open && !files.some((f) => f.path === this.open)) { this.open = null; this.setLines([]); }
        // The first file's diff shows until you pick another.
        if (!this.open && !this.closed && files.length) this.open = files[0].path;
        if (this.open) {
          try { await this.load(this.open, context); }
          catch { if (key() === context) this.setLines(["Cannot preview this diff (too large or unreadable)"]); }
        }
      } catch (e) { if (key() === context) this.error = String(e); }
      finally { this.loading = false; cx.notify(); }
    });
  }

  // The draft comments of one scope of the shown repo. Drafts saved before
  // scopes existed (keyed by repo alone) were all on the uncommitted changes.
  draftKey(scope = this.scope) { return `${this.on ?? ""}:${this.root}:${scope}`; }
  loadDrafts(scope) {
    const drafts = { ...(shared(DRAFTS) ?? {}) }, old = `${this.on ?? ""}:${this.root}`;
    if (drafts[old]) { drafts[`${old}:work`] = [...(drafts[`${old}:work`] ?? []), ...drafts[old]]; delete drafts[old]; setShared(DRAFTS, drafts); }
    return drafts[this.draftKey(scope)] ?? [];
  }

  // What this repo can be reviewed against: its branch, the base branch
  // (props.base, else origin/HEAD, else main, else master), the merge
  // base with it (null when on the base itself), and HEAD's short hash
  // when it has a parent.
  async scopes(git) {
    const out = async (args) => { const r = await git(args); return r.code === 0 ? r.stdout.trim() : null; };
    const branch = await out(["rev-parse", "--abbrev-ref", "HEAD"]);
    let base = typeof props()?.base === "string" ? props().base : null;
    if (!base) { const h = await out(["symbolic-ref", "-q", "refs/remotes/origin/HEAD"]); if (h) base = h.replace(/^refs\/remotes\/origin\//, ""); }
    if (!base) for (const b of ["main", "master"]) { if (await out(["rev-parse", "--verify", "-q", `refs/heads/${b}`]) !== null) { base = b; break; } }
    let merge = null;
    if (base && branch !== base) {
      const baseRef = (await out(["rev-parse", "--verify", "-q", `refs/heads/${base}`])) !== null ? base : `origin/${base}`;
      merge = await out(["merge-base", baseRef, "HEAD"]);
      if (merge && (await out(["rev-parse", "HEAD"])) === merge) merge = null;
    }
    const last = (await out(["rev-parse", "--verify", "-q", "HEAD~1"])) !== null ? await out(["rev-parse", "--short", "HEAD"]) : null;
    const subject = last ? await out(["log", "-1", "--format=%s"]) : null;
    return { branch, base, merge, last, subject };
  }

  // The scope's name for the header and the submit message.
  scopeLabel(scope = this.scope) {
    const i = this.scopeInfo ?? {};
    return scope === "branch" ? `vs ${i.base}` : scope === "last" ? "Last commit" : "Uncommitted";
  }
  scopeWords() {
    const i = this.scopeInfo ?? {};
    return this.scope === "branch" ? `all changes on branch ${i.branch} since it left ${i.base} (merge base ${(i.merge ?? "").slice(0, 7)}), committed or not`
      : this.scope === "last" ? `the last commit (${i.last}${i.subject ? `, "${i.subject}"` : ""}) plus the uncommitted changes`
      : "uncommitted changes";
  }
  setScope(scope, cx) {
    if (!this.root || scope === this.scope) { this.choosingScope = false; cx.notify(); return; }
    const all = { ...(shared(SCOPE) ?? {}) }; all[`${this.on ?? ""}:${this.root}`] = scope; setShared(SCOPE, all);
    this.scope = scope; this.choosingScope = false; this.composer = null; this.setLines([]);
    this.comments = this.loadDrafts(scope); this.rebuild();
    this.refresh(cx); cx.notify();
  }
  cycleScope(cx) {
    const ok = SCOPES.filter((s) => s === "work" || (s === "last" ? this.scopeInfo?.last : this.scopeInfo?.merge));
    this.setScope(ok[(ok.indexOf(this.scope) + 1) % ok.length], cx);
  }

  async load(path, context) {
    const file = this.files.find((f) => f.path === path), root = this.root, on = this.on;
    if (!file) return;
    let lines;
    if (file.fresh || (!this.hasHead && file.status === "A")) {
      const text = await readTextFile(`${root}/${path}`, { on }).catch(() => null);
      if (text === null) lines = ["Cannot preview this file (binary, too large, or unreadable)"];
      else if (text.includes("\0")) lines = ["Binary file · no text diff"];
      else {
        file.add = countLines(text);
        lines = [`@@ -0,0 +1,${file.add} @@`, ...text.slice(0, 400000).replace(/\n$/, "").split("\n").slice(0, 1500).map(l => `+${l}`)];
      }
    } else {
      const r = await exec("git", ["diff", ...(this.hasHead ? [this.ref ?? "HEAD"] : []), "--no-ext-diff", "--no-textconv", "--no-color", "--", path], { cwd: root, on });
      if (r.code !== 0) throw new Error(r.stderr);
      const all = r.stdout.replace(/\n$/, "").split("\n"), first = all.findIndex((l) => l.startsWith("@@"));
      lines = first < 0 ? [file.binary ? "Binary file changed" : "No text diff available"] : all.slice(first);
    }
    if (key() === context && this.open === path) this.setLines(lines.slice(0, 1500).map(line => line.length > 4000 ? line.slice(0, 4000) + "… (line truncated)" : line), path);
  }

  setLines(lines, path) {
    const same = this.lines && lines.length === this.lines.length && lines.every((l, i) => l === this.lines[i]);
    if (same) return;
    this.lines = lines;
    this.rows = diffRows(lines, languageOf(path));
    this.index = new Map();
    this.rows.forEach((r, i) => { const k = descKey(desc(r)); if (!this.index.has(k)) this.index.set(k, i); });
    this.measure();
  }

  // Sizes that depend on the font: the gutter (wide enough for the largest
  // line number), the diff's width, and the rows.
  measure() {
    const ch = charOf(this.fontSize), digits = String(Math.max(0, ...this.rows.map((r) => r.number ?? 0))).length;
    this.gutter = Math.max(30, Math.ceil(digits * ch + 10));
    this.diffWidth = Math.max(300, ...(this.lines ?? []).map((line) => Math.ceil(line.length * ch) + this.gutter + 36));
    this.rebuild();
  }

  // Where a row descriptor is in the current diff, or -1.
  at(d) { return d ? (this.index.get(descKey(d)) ?? -1) : -1; }

  // The list's items: diff rows, with each comment under its last line;
  // comments on the whole file come first. The comment being edited stays
  // in place as a live preview of what is typed in the box.
  rebuild() {
    const items = this.rows.map((_r, i) => ({ key: `r:${i}`, kind: "row", i, height: this.row }));
    const under = new Map(), editing = this.composer?.editing ?? null;
    this.items = [];
    for (const c of this.comments) {
      if (c.path !== this.open) continue;
      const live = c.id === editing, text = live ? this.noteText : c.text;
      const it = { key: `c:${c.id}`, kind: "comment", id: c.id, live, text, height: this.commentHeight(text) };
      if (c.whole) { this.items.push({ ...it, whole: true, from: -1, to: -1 }); continue; }
      const from = this.at(c.from), to = this.at(c.to);
      if (from < 0 || to < 0 || to < from) continue;
      (under.get(to) ?? under.set(to, []).get(to)).push({ ...it, from, to });
    }
    for (const item of items) { this.items.push(item); for (const c of under.get(item.i) ?? []) this.items.push(c); }
    this.sizes = this.items.map((it) => it.height);
  }

  commentHeight(text) {
    const cpl = Math.max(24, Math.floor(((this.size?.width ?? 368) - 90) / charOf(this.fontSize)));
    const lines = text.split("\n").reduce((n, l) => n + Math.max(1, Math.ceil(l.length / cpl)), 0);
    return 44 + lines * Math.round(this.fontSize * 1.45);
  }
  // The composer's target rows in the current diff, or null (also for a whole-file comment).
  target() {
    if (!this.composer || this.composer.whole || this.composer.path !== this.open) return null;
    const from = this.at(this.composer.from), to = this.at(this.composer.to);
    return from < 0 || to < 0 ? null : { from: Math.min(from, to), to: Math.max(from, to) };
  }

  // Click on a diff row: open the comment box there, or widen it to a range.
  clickRow(i, cx) {
    const row = this.rows[i];
    if (!row || row.kind === "") return;
    let from = i, to = i;
    if (row.kind === "@") {
      const members = this.rows.map((r, j) => j).filter((j) => j !== i && this.rows[j].hunk === i && this.rows[j].kind !== "");
      if (!members.length) return;
      from = members[0]; to = members[members.length - 1];
    }
    const t = this.target();
    if (t && !this.composer.editing && !this.noteText.trim()) {
      // A click inside the highlighted lines clears them; outside, it widens them.
      if (from >= t.from && to <= t.to) { this.closeComposer(cx); return; }
      from = Math.min(t.from, from); to = Math.max(t.to, to);
    }
    // Editing a line comment keeps its identity when retargeted; a whole-file comment stays what it is.
    const editing = this.composer?.editing && !this.composer.whole && this.composer.path === this.open ? this.composer.editing : null;
    this.composer = { path: this.open, from: desc(this.rows[from]), to: desc(this.rows[to]), editing };
    this.openBox(cx);
  }

  // Opening the box: rebuild and give the textarea the keyboard (again
  // once the frame is drawn). The list is not scrolled: what was clicked
  // is on screen already, and a scroll would make the rows jump.
  // `scrollTo`: an item index to bring on screen anyway (a whole-file
  // comment, whose card is at the top of the diff).
  openBox(cx, scrollTo = -1) {
    this.rebuild();
    this.note.focus();
    if (scrollTo >= 0) this.scroll.scroll_to_item(scrollTo);
    cx.timer.after(300, () => this.note.focus());
    cx.notify();
  }

  // Comment on a file as a whole (an image, a deleted file, anything without lines to click).
  commentFile(path, cx) {
    if (this.composer?.whole && this.composer.path === path && !this.composer.editing && !this.noteText.trim()) { this.closeComposer(cx); return; }
    if (this.open !== path) this.pick(path, cx);
    this.composer = { path, whole: true, editing: null };
    this.openBox(cx, 0);
  }

  editComment(id, cx) {
    const c = this.comments.find((c) => c.id === id);
    if (!c) return;
    this.composer = c.whole ? { path: c.path, whole: true, editing: id } : { path: c.path, from: c.from, to: c.to, editing: id };
    this.note.set_value(c.text); this.noteText = c.text;
    this.openBox(cx);
  }

  closeComposer(cx) {
    this.composer = null; this.note.set_value(""); this.noteText = ""; this.rebuild(); this.handle.focus(); cx.notify();
  }

  setComments(list, cx) {
    this.comments = list; this.rebuild();
    const drafts = { ...(shared(DRAFTS) ?? {}) }, k = this.draftKey();
    if (list.length) drafts[k] = list; else delete drafts[k];
    setShared(DRAFTS, drafts);
    cx?.notify();
  }

  addComment(cx) {
    const text = this.note.value().trim(), c = this.composer;
    if (!c || !text) return;
    const list = this.comments.filter((x) => x.id !== c.editing);
    const id = c.editing ?? `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;
    const comment = c.whole ? { id, path: c.path, whole: true, text } : { id, path: c.path, from: c.from, to: c.to, text };
    const t = this.target();
    if (t) { comment.from = desc(this.rows[t.from]); comment.to = desc(this.rows[t.to]); comment.quote = this.quote(this.rows.slice(t.from, Math.min(t.to, t.from + 60) + 1)); }
    else if (c.editing) { const old = this.comments.find((x) => x.id === c.editing); if (old?.quote) comment.quote = old.quote; }
    list.push(comment);
    this.setComments(list);
    this.closeComposer(cx);
  }

  deleteComment(cx) {
    const id = this.composer?.editing;
    if (id) this.setComments(this.comments.filter((c) => c.id !== id));
    this.closeComposer(cx);
  }

  // The text the agent gets for a set of rows (indexes; null: every row of the open diff).
  quote(rows) {
    return rows.map((r) => r.kind === "@" ? r.text : `${r.number === undefined ? "" : String(r.number).padStart(5)} ${r.kind || " "} ${r.text}`).join("\n");
  }
  span(rows) {
    const nums = rows.filter((r) => r.number !== undefined && r.kind !== "-").map((r) => r.number), olds = rows.filter((r) => r.kind === "-").map((r) => r.number);
    const range = (a) => a.length > 1 ? `lines ${Math.min(...a)}-${Math.max(...a)}` : `line ${a[0]}`;
    return nums.length ? range(nums) : olds.length ? `removed ${range(olds)}` : "";
  }
  where(path) { return `${this.root}/${path}${this.on ? ` (on ${this.on})` : ""}`; }
  // A file's change in words, for a whole-file comment: "added, binary".
  describe(path) {
    const f = this.files.find((f) => f.path === path);
    if (!f) return "no longer changed";
    const what = f.status === "A" ? "added" : f.status === "D" ? "deleted" : f.status === "U" ? "conflict" : "modified";
    return f.binary ? `${what}, binary` : f.add || f.del ? `${what}, +${f.add} −${f.del}` : what;
  }

  askAbout(indexes, cx) {
    if (!this.open || !this.rows.length) return;
    const rows = (indexes ? indexes.sort((a, b) => a - b).map((i) => this.rows[i]) : this.rows).filter(Boolean).slice(0, 400);
    const span = this.span(rows), title = `${this.open}${span ? `:${span.replace(/^(removed )?lines? /, "")}` : ""}`;
    const head = indexes ? `In ${this.where(this.open)}, ${span || "these lines"} of the diff (${this.scopeWords()}; new-file line numbers; - lines are removed):` : `The diff of ${this.where(this.open)} (${this.scopeWords()}):`;
    cx.spawn(async (cx) => { try { await ask({ title, context: `${head}\n${this.quote(rows)}` }); } catch (e) { this.note_ = `Ask failed: ${e}`; } cx.notify(); });
  }

  // Every comment, with its lines, as one review message.
  submit(cx) {
    if (!this.comments.length || !this.root) return;
    const list = [...this.comments].sort((a, b) => a.path.localeCompare(b.path) || (a.from?.number ?? -1) - (b.from?.number ?? -1));
    const parts = list.map((c) => {
      if (c.whole) return `### ${c.path}, whole file (${this.describe(c.path)})\n\nComment: ${c.text}`;
      let body;
      if (c.path === this.open) {
        const from = this.at(c.from), to = this.at(c.to);
        body = from >= 0 && to >= from ? this.quote(this.rows.slice(from, to + 1)) : null;
      }
      const span = c.from.number === c.to.number ? `line ${c.from.number}` : `lines ${c.from.number}-${c.to.number}`;
      // Lines gone from the diff: the ones captured when the comment was made.
      if (body === undefined || body === null) body = c.quote ?? (c.from.text === c.to.text ? `${String(c.from.number).padStart(5)} ${c.from.kind} ${c.from.text}` : `${String(c.from.number).padStart(5)} ${c.from.kind} ${c.from.text}\n      …\n${String(c.to.number).padStart(5)} ${c.to.kind} ${c.to.text}`);
      return `### ${c.path}, ${span}\n${body}\n\nComment: ${c.text}`;
    });
    const n = list.length, title = `Review · ${n} comment${n > 1 ? "s" : ""}`;
    const context = `Code review of ${this.root}${this.on ? ` (on ${this.on})` : ""}: ${this.scopeWords()}. ${n} comment${n > 1 ? "s" : ""}. Line numbers are new-file numbers; "-" lines are removed.\n\n${parts.join("\n\n")}`;
    this.submitting = Date.now();
    cx.spawn(async (cx) => {
      try { const r = await ask({ title, context, sent: SENT }); if (r === "sent") this.setComments([], cx); else if (r === "none") this.submitting = null; }
      catch (e) { this.note_ = `Submit failed: ${e}`; this.submitting = null; }
      cx.notify();
    });
  }

  commit(cx) {
    if (!this.message.trim() || !this.root || this.busy || this.loading || this.context !== key()) return;
    const root = this.root, on = this.on, context = this.context, message = this.message.trim();
    this.busy = true; this.note_ = null;
    cx.spawn(async (cx) => {
      try {
        for (const args of [["add", "-A"], ["commit", "-m", message]]) {
          const r = await exec("git", args, { cwd: root, on });
          if (r.code !== 0) throw new Error((r.stderr || r.stdout).trim());
        }
        if (key() === context) { this.message = ""; this.input.set_value(""); }
      } catch (e) { if (key() === context) this.note_ = `Commit failed: ${e}`; }
      finally { this.busy = false; this.refresh(cx); cx.notify(); }
    });
    cx.notify();
  }

  // The scope picker: a small select-looking box with the scope's name; a
  // Popover lists the scopes the repo offers, with a check on the current one.
  scopePicker(t) {
    const i = this.scopeInfo ?? {};
    const options = [
      { scope: "work", label: "Uncommitted", detail: "working tree vs HEAD", ok: true },
      { scope: "last", label: "Last commit", detail: i.last ? `${i.last}${i.subject ? ` · ${i.subject}` : ""}, plus uncommitted` : "HEAD has no parent", ok: Boolean(i.last) },
      { scope: "branch", label: i.base ? `vs ${i.base}` : "vs base branch", detail: i.merge ? `everything on ${i.branch} since it left ${i.base}` : i.base ? `on ${i.base} itself` : "no main or master branch", ok: Boolean(i.merge) },
    ];
    const box = h_flex().id("scope-box").h(24).px(8).gap(6).items_center().rounded(6).border_1().border_color(this.choosingScope ? t.accent : t.border).bg(t.raised).cursor_pointer().hover((s) => s.bg(t.hover))
      .tooltip("What is reviewed: the uncommitted changes, the last commit, or the whole branch").child(div().text_size(12).child(this.scopeLabel())).child(svg("mods/reviewer/chevron-down.svg").size(11).text_color(t.dim));
    return Popover.new("scope").open(this.choosingScope).on_open_change((open, cx) => { this.choosingScope = open; cx.notify(); })
      .trigger(box)
      .content(v_flex().mt(4).min_w(260).p(6).gap(2).rounded(8).border_1().border_color(t.border).bg(t.popover).shadow_md().children(options.map((o) =>
        h_flex().id(`scope-${o.scope}`).px(10).py(7).gap(10).items_center().rounded(6).when(o.ok, (e) => e.cursor_pointer().hover((s) => s.bg(t.hover)).on_click((_e, cx) => this.setScope(o.scope, cx))).when(!o.ok, (e) => e.opacity(0.5))
          .child(v_flex().flex_1().min_w(0).gap(2).child(div().text_size(12).child(o.label)).child(div().text_size(11).text_color(t.dim).truncate().child(o.detail)))
          .child(o.scope === this.scope ? svg("mods/reviewer/check.svg").size(12).text_color(t.accent) : div().w(12)))));
  }

  // A panel under 600px has no room for a column beside the diff.
  narrow() { return (this.size?.width ?? 368) < 600; }

  // The comment box: title, the lines it is about, the textarea, Add / Cancel / Delete.
  // `docked`: a strip under the diff (narrow panel) instead of a 300px card over its top-right.
  box(t, target, docked) {
    const c = this.composer, editing = Boolean(c.editing);
    const where = c.whole ? `whole file (${this.describe(c.path)})` : target ? (target.from === target.to ? `line ${this.rows[target.from].number ?? ""}` : `lines ${this.rows[target.from].number}–${this.rows[target.to].number}`) : "those lines are no longer in the diff";
    const hint = [c.whole ? "Click a line to comment on lines instead." : editing ? "" : "Click a line to widen the range; click a highlighted line to clear it.", "Enter adds, shift-enter starts a new line, Esc cancels."].filter(Boolean).join("\n");
    // Every press inside the box stops here: the box floats over the list, and a click that
    // fell through to the row underneath would reopen the box the moment Add closed it.
    const stop = (action) => (e, cx) => { cx.stop_propagation(); action(e, cx); };
    const button = (id, label, primary, action, tip) => div().id(id).h(26).px(10).flex().items_center().rounded(6).bg(primary ? t.solid : t.raised).text_color(primary ? t.solid_foreground : t.foreground).text_size(11).font_medium().cursor_pointer().hover((s) => s.opacity(0.88)).on_click(stop(action)).tooltip(tip).child(label);
    const link = (id, label, color, action, tip) => div().id(id).h(26).px(7).flex().items_center().rounded(6).text_size(11).text_color(color).cursor_pointer().hover((s) => s.bg(t.hover)).on_click(stop(action)).tooltip(tip).child(label);
    return v_flex().id("comment-box").flex_none().gap(8).p(10).text_size(12).when(docked, (e) => e.bg(t.surface))
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation()).on_mouse_up("left", (_e, cx) => cx.stop_propagation()).on_click((_e, cx) => cx.stop_propagation())
      .when(!docked, (e) => e.absolute().top(12).right(14).w(300).rounded(10).border_1().border_color(t.border).bg(t.surface + "eb").shadow_lg())
      .when(docked, (e) => e.w_full().border_t(1).border_color(t.border))
      .child(h_flex().items_center().gap(6)
        .child(div().font_semibold().child(editing ? "Edit comment" : "Comment"))
        // The how-to lives on this "?": a tooltip on hover, and a click shows it in the box.
        .child(div().id("comment-help").size(16).flex().items_center().justify_center().rounded(8).border_1().border_color(this.help ? t.accent : t.border).text_size(10).text_color(this.help ? t.accent : t.dim).cursor_pointer().hover((s) => s.text_color(t.foreground).border_color(t.foreground)).tooltip(hint)
          .on_click(stop((_e, cx) => { this.help = !this.help; cx.notify(); })).child("?"))
        .child(div().flex_1())
        .child(div().id("comment-close").size(20).flex().items_center().justify_center().rounded(5).cursor_pointer().text_color(t.muted).hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click(stop((_e, cx) => this.closeComposer(cx))).tooltip("Close (Esc)").child("×")))
      .child(div().text_size(11).text_color(t.dim).whitespace_normal().child(`${c.path.split("/").pop()} · ${where}`))
      .when(Boolean(this.help), (e) => e.child(v_flex().gap(2).px(8).py(6).rounded(6).bg(t.raised).text_size(10.5).text_color(t.dim).children(hint.split("\n").map((l) => div().whitespace_normal().child(l)))))
      .child(div().w_full().child(Textarea.new(this.note).w_full().px(8).py(6).rounded(8).border_1().border_color(t.input).bg(t.background).text_size(12).text_color(t.foreground)))
      .child(h_flex().items_center().gap(6).flex_wrap()
        .child(button("comment-add", editing ? "Save" : "Add comment", true, (_e, cx) => this.addComment(cx), "Enter"))
        .child(link("comment-cancel", "Cancel", t.dim, (_e, cx) => this.closeComposer(cx), "Esc"))
        .when(editing, (e) => e.child(div().flex_1()).child(link("comment-delete", "Delete", t.ansi1, (_e, cx) => this.deleteComment(cx), "Remove this comment from the review"))));
  }

  item(it, t, colors, target, commented) {
    const width = (this.size?.width ?? 368) - 60;
    if (it.kind === "comment") {
      const span = it.whole ? "whole file" : it.from === it.to ? `line ${this.rows[it.from].number}` : `lines ${this.rows[it.from].number}–${this.rows[it.to].number}`;
      return div().w_full().h(it.height).flex_none().pl(42).pr(12).py(4).cursor_pointer()
        .child(v_flex().max_w(width).rounded(8).border_1().border_color(it.live ? t.accent : t.accent + "66").bg(t.surface).px(10).py(6).gap(3)
          .child(div().text_size(10).text_color(it.live ? t.accent : t.dim).child(it.live ? `Comment · ${span} · editing` : `Comment · ${span} · click to edit`))
          .child(div().text_size(this.fontSize).whitespace_normal().text_color(it.text ? t.foreground : t.dim).child(it.text || "(empty)")));
    }
    const { kind, number, spans } = this.rows[it.i], i = it.i;
    const on = target && i >= target.from && i <= target.to, mark = commented.has(i);
    if (kind === "@") {
      return h_flex().w_full().h(this.row).flex_none().items_center().cursor_pointer().bg(t.raised).border_l(2).border_color(on ? t.accent : NONE)
        .child(div().w(this.gutter + 16).flex_none()).child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(spans[0].text));
    }
    // Added and removed rows get a clear tint (stronger when targeted), a
    // colored sign column and a tinted gutter, like a GitHub diff.
    const tint = kind === "+" ? colors.added : kind === "-" ? colors.removed : null;
    return h_flex().w_full().h(this.row).flex_none().cursor_pointer().border_l(2).border_color(on ? t.accent : mark ? t.accent + "66" : NONE)
      .when(Boolean(tint), (e) => e.bg(tint + (on ? "5c" : "30")))
      .when(!tint && on, (e) => e.bg(t.selected))
      .child(div().w(this.gutter).flex_none().text_right().pr(4).when(Boolean(tint), (e) => e.bg(tint + "26")).text_color(on ? t.foreground : tint ? t.foreground + "cc" : t.dim).child(number === undefined ? "" : String(number)))
      .child(div().w(16).flex_none().text_center().font_bold().text_color(tint ?? NONE).child(kind === "+" ? "+" : kind === "-" ? "−" : " "))
      .child(h_flex().flex_1().min_w(0).whitespace_nowrap().children(spans.map((s) => s.cls ? div().text_color(colors[s.cls] ?? t.foreground).child(s.text) : div().child(s.text))));
  }

  render(cx) {
    if (this.dialog) return this.dialog.render(cx);
    if (key() !== this.context) this.refresh(cx);
    const size = codeSize();
    if (size !== this.fontSize) { this.fontSize = size; this.row = rowOf(size); this.measure(); }
    // The dialog reports a sent review through a shared key; the draft goes.
    const sentAt = shared(SENT);
    if (this.submitting && typeof sentAt === "number" && sentAt >= this.submitting) { this.submitting = null; cx.timer.after(1, (cx) => this.setComments([], cx)); }
    const t = theme(), colors = palette(props()?.palette, t), add = this.files.reduce((n, f) => n + f.add, 0), del = this.files.reduce((n, f) => n + f.del, 0);
    const enabled = Boolean(this.message.trim() && this.root && !this.busy && !this.loading);
    const target = this.target(), n = this.comments.length, canAsk = Boolean(this.open && this.rows.length);
    const commented = new Set();
    for (const it of this.items) if (it.kind === "comment") for (let j = it.from; j <= it.to; j++) commented.add(j);
    const perFile = {};
    for (const c of this.comments) perFile[c.path] = (perFile[c.path] ?? 0) + 1;
    const button = (id, label, primary, action) => div().id(id).h(24).px(10).flex().items_center().rounded(6).bg(primary ? t.solid : t.raised).text_color(primary ? t.solid_foreground : t.foreground).text_size(12).font_medium().cursor_pointer().hover((s) => s.opacity(0.88)).on_click(action).child(label);
    const link = (id, label, action) => div().id(id).h(24).px(8).flex().items_center().rounded(6).text_size(12).text_color(t.dim).cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click(action).child(label);
    return v_flex().id("changes").size_full().min_h(0).relative().rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13).track_focus(this.handle)
      .on_size_change((size, cx) => { const w = this.size?.width; this.size = size; if (w !== size.width) { this.rebuild(); cx.notify(); } })
      .on_key_down((e, cx) => {
        if (e.key === "escape" && this.typing) { this.typing = false; this.handle.focus(); cx.stop_propagation(); cx.notify(); }
        else if (e.key === "escape" && this.composer) { this.closeComposer(cx); cx.stop_propagation(); }
        else if (e.key === "enter" && (e.modifiers?.platform || e.modifiers?.control) && this.composer) { this.addComment(cx); cx.stop_propagation(); }
      })
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Changes"))
        .child(div().h(24).px(8).flex().items_center().rounded(6).border_1().border_color(t.border).text_size(12).text_color(t.muted).child(`${this.files.length} files`))
        .when(Boolean(this.root) && this.hasHead, (e) => e.child(this.scopePicker(t)))
        .child(div().flex_1()).child(div().text_size(11).text_color(t.ansi2).child(`+${add}`)).child(div().text_size(11).text_color(t.ansi1).child(`−${del}`))
        .when(n > 0, (e) => e.child(link("review-discard", "Discard", (_e, cx) => this.setComments([], cx))).child(button("review-submit", `Submit review · ${n}`, true, (_e, cx) => this.submit(cx))))
        .when(n === 0 && canAsk, (e) => e.child(button("ask", "Ask about diff", false, (_e, cx) => this.askAbout(null, cx)))))
      .child(v_flex().id("changes-list").flex_none().h(Math.min(200, Math.max(44, this.files.length * 28 + 12))).overflow_y_scrollbar().p(6).border_b(1).border_color(t.border).children(this.files.map((f) => {
        const parts = f.path.split("/"), name = parts.pop(), k = perFile[f.path];
        return h_flex().id(`change-${f.path}`).h(28).flex_none().px(8).gap(8).items_center().rounded(7).cursor_pointer().when(this.open === f.path, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover)).on_click((_e, cx) => this.pick(f.path, cx))
          .child(div().w(14).text_size(11).text_color(f.status === "A" ? t.ansi2 : f.status === "D" ? t.ansi1 : f.status === "U" ? t.ansi1 : t.blocked).child(f.status))
          .child(h_flex().flex_1().min_w(0).child(div().text_color(t.dim).truncate().child(parts.length ? parts.join("/") + "/" : "")).child(div().max_w(260).min_w(0).truncate().child(name)))
          // One speech bubble: the draft count when there are drafts, and a click comments on the whole file.
          .child(h_flex().id(`comment-file-${f.path}`).h(18).min_w(18).px(k ? 5 : 0).gap(3).items_center().justify_center().rounded(4).cursor_pointer()
            .when(Boolean(k), (e) => e.bg(t.accent + "33").text_size(10).text_color(t.foreground))
            .when(!k, (e) => e.text_color(t.muted))
            .hover((s) => s.bg(k ? t.accent + "55" : t.hover).text_color(t.foreground))
            .tooltip(k ? `${k} draft comment${k > 1 ? "s" : ""} · click to comment on the whole file` : "Comment on the whole file")
            .on_click((_e, cx) => { cx.stop_propagation(); this.commentFile(f.path, cx); })
            .when(Boolean(k), (e) => e.child(String(k))).child(svg("mods/reviewer/comment.svg").size(k ? 10 : 12)))
          .when(f.add > 0, (e) => e.child(div().text_size(11).text_color(t.ansi2).child(`+${f.add}`))).when(f.del > 0, (e) => e.child(div().text_size(11).text_color(t.ansi1).child(`−${f.del}`)));
      })).when(!this.files.length, (e) => e.child(div().p(8).text_color(t.dim).child(this.error || (this.loading ? "Loading changes…" : this.root ? "No uncommitted changes" : "No folder")))))
      .when(this.limited, el => el.child(div().px(12).py(4).text_size(11).text_color(t.dim).child("Showing the first 1,000 changed files")))
      .child(h_flex().flex_1().min_h(0).items_stretch()
        .child(div().flex_1().min_w(0).min_h(0).relative().font_family(codeFont()).text_size(this.fontSize)
        .child(div().id("changes-diff-x").size_full().overflow_x_scrollbar()
          .child(div().w_full().min_w(this.diffWidth).h_full().child(v_virtual_list("changes-diff", this.items.length, this.sizes.length ? this.sizes : this.row, (i) => this.items[i].key,
            (range) => this.items.slice(range.start, range.end).map((it) => this.item(it, t, colors, target, commented))).size_full().track_scroll(this.scroll)
            .on_item_click((k, cx) => { if (k.startsWith("c:")) { if (k.slice(2) !== this.composer?.editing) this.editComment(k.slice(2), cx); } else this.clickRow(Number(k.slice(2)), cx); })
            .on_item_secondary_click((k, _e, cx) => { if (!k.startsWith("r:")) return; const i = Number(k.slice(2)); const r = this.rows[i]; if (!r || r.kind === "") return; this.askAbout(r.kind === "@" ? this.rows.map((_r, j) => j).filter((j) => this.rows[j].hunk === i && this.rows[j].kind !== "") : [i], cx); }))))
        .child(Scrollbar.vertical("changes-diff").viewport_from_layout().absolute().inset_0())
        .when(!this.open && this.files.length > 0, (e) => e.child(div().absolute().top(6).px(12).text_color(t.dim).child("Select a file to view its changes")))
        .when(canAsk && !this.composer && n === 0, (e) => e.child(div().absolute().bottom(6).right(14).px(8).py(3).rounded(6).bg(t.raised + "e0").text_size(10).text_color(t.dim).child("Click a line to comment · right-click to ask"))))
        // The comment box, a card floating over the top-right of the diff while it is open (a strip below it on a narrow panel).
        .when(Boolean(this.composer) && !this.narrow(), (e) => e.child(this.box(t, target, false))))
      // Narrow panel: the comment box is a strip under the diff instead of a column beside it.
      .when(Boolean(this.composer) && this.narrow(), (e) => e.child(this.box(t, target, true)))
      .when(Boolean(this.note_), (e) => e.child(div().px(10).pb(8).text_size(11).text_color(t.ansi1).child(this.note_)))
      .child(h_flex().flex_none().p(10).gap(8).border_t(1).border_color(t.border)
        .child(div().id("commit-message").flex_1().min_w(0).h(32).px(10).flex().items_center().rounded(8).border_1().border_color(this.typing ? t.accent : t.border).cursor_text().on_mouse_down("left", (_e, cx) => cx.stop_propagation()).child(Input.new(this.input).h_full().text_size(12).text_color(t.foreground)))
        .child(div().id("commit").h(32).px(14).flex().items_center().rounded(8).bg(enabled ? t.solid : t.raised).text_color(enabled ? t.solid_foreground : t.dim).text_size(12).when(enabled, (e) => e.cursor_pointer()).on_click((_e, cx) => this.commit(cx)).child(this.busy ? "Committing…" : "Commit")));
  }

  pick(path, cx) {
    this.open = this.open === path ? null : path; this.setLines([]); this.note_ = null;
    this.closed = !this.open;
    const context = this.context;
    if (this.open) cx.spawn(async (cx) => {
      try { await this.load(path, context); }
      catch (e) { if (key() === context && this.open === path) this.note_ = `Cannot preview this diff (too large or unreadable): ${e}`; }
      cx.notify();
    });
    cx.notify();
  }
}
