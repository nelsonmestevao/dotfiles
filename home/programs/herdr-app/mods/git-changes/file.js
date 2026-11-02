// Local change: the file tab (props.role "file"). The files-mods panel opens one per click, as a tab
// or, with shift, a pane beside the focused one: props { space, root, on, path }. It shows the file
// read-only (Markdown rendered, the eye shows its source), copies its path, and has a Comment mode:
// the file as clickable lines, to comment on for the agent.
import { div, svg } from "gpui-kit";
import { v_flex, h_flex, Editor, EditorState, v_virtual_list, Scrollbar, TextView } from "gpui-base";
import { readTextFile, watchFolder, theme, settings, props, panes, focused, run } from "herdr";
import { icon } from "./menu.js";
import { commentsOf, openComment, pickRange, textButton, iconButton, copyButton, reviewButton, selectionBar } from "./common.js";

const LANG = { ts: "js", tsx: "js", mts: "js", cts: "js", jsx: "js", mjs: "js", toml: "yaml", jsonc: "json", svelte: "html", vue: "html" };
const MAX_TEXT = 400000, MAX_LINES = 20000, ROW = 20;
const PROSE_FONT = "Liberation Sans";
const mono = () => settings().font_family ?? "JetBrains Mono";
const isMarkdown = (path) => /\.(md|markdown|mdx)$/i.test(path ?? "");

export class FileView {
  init(cx) {
    const p = props() ?? {};
    this.space = p.space; this.root = p.root; this.on = p.on ?? null; this.path = p.path;
    this.listId = `gc-file-${Math.random().toString(36).slice(2)}`;
    this.text = null; this.code = null; this.showSource = false; this.commenting = false; this.sel = null;
    if (!this.path) return;
    if (!this.on) this.watch(`${this.root}/${this.path}`.replace(/\/[^/]*$/, ""), cx);
    this.reload(cx);
    // Remote files can't be watched: read them again every 10 s (local ones too, as a backstop).
    cx.timer.every(10000, (cx) => this.reload(cx));
  }

  watch(folder, cx) {
    cx.spawn(async (cx) => {
      try { for (;;) { await watchFolder(folder); this.reload(cx); } } catch {}
    });
  }

  release() { this.code?.release(); this.code = null; }

  reload(cx) {
    if (this.loading) { this.again = true; return; }
    this.loading = true; this.again = false;
    cx.spawn(async (cx) => {
      try {
        const text = await readTextFile(`${this.root}/${this.path}`, { on: this.on });
        if (text === null) { this.error = "This file is no longer available"; this.release(); this.text = null; return; }
        if (text.includes("\0")) { this.error = "Binary file · no text preview"; this.release(); this.text = null; return; }
        // Unchanged: keep the editor, and with it the scroll position.
        if (text === this.text && this.code) return;
        this.text = text; this.lines = null; this.error = null; this.release();
        const t = theme(), ext = this.path.includes(".") ? this.path.split(".").pop() : "txt";
        this.code = EditorState.new({ language: LANG[ext] ?? ext, readonly: true,
          value: text.length > MAX_TEXT ? text.slice(0, MAX_TEXT) + "\n… (file truncated)" : text,
          font_family: mono(), font_size: 12.5,
          syntax: { keyword: t.ansi5, string: t.ansi2, comment: t.dim, function: t.ansi4, type: t.ansi3, number: t.ansi1, constant: t.ansi6 } });
      } catch {
        this.error = "Binary, too large, or unreadable · no text preview"; this.release(); this.text = null;
      } finally {
        this.loading = false; cx.notify();
        if (this.again) this.reload(cx);
      }
    });
  }

  // The pane holding this tab: clicking it focused it, so the × closes the focused pane.
  close() {
    const f = focused()?.pane, me = f && panes().find((p) => p.pane === f && p.mod === "git-changes");
    if (me) run("pane.close", { pane: me.pane });
  }

  // ---- comments ----

  fileLines() {
    if (!this.lines && this.text !== null) {
      const all = this.text.replace(/\n$/, "").split("\n");
      this.lines = all.length > MAX_LINES ? [...all.slice(0, MAX_LINES), `… (${all.length - MAX_LINES} more lines not shown)`] : all;
      this.width = Math.min(4000, Math.max(...this.lines.slice(0, 5000).map((l) => l.length), 20) * 7.4);
    }
    return this.lines ?? [];
  }

  comment(cx) {
    const { from, to } = this.sel, w = String(to).length;
    const quote = this.fileLines().slice(from - 1, to).map((l, i) => `${String(from + i).padStart(w)}  ${l}`);
    openComment(this.space, { kind: "file", root: this.root, on: this.on, path: this.path, from, to,
      label: from === to ? `line ${from}` : `lines ${from}-${to}`, quote });
    this.sel = null; cx.notify();
  }

  // Lines that already carry a comment on this file.
  commented() {
    const set = new Set();
    for (const c of commentsOf(this.space)) if (c.kind === "file" && c.root === this.root && c.path === this.path)
      for (let n = c.from; n <= c.to; n++) set.add(n);
    return set;
  }

  lineRow(n, text, t, marked) {
    const picked = this.sel && n >= this.sel.from && n <= this.sel.to;
    return h_flex().w_full().h(ROW).flex_none().gap(10).cursor_pointer()
      .when(Boolean(picked), (e) => e.bg(t.selected)).when(!picked && marked.has(n), (e) => e.bg(t.accent + "14"))
      .child(div().w(46).flex_none().text_right().text_color(marked.has(n) ? t.accent : t.dim).child(String(n)))
      .child(div().flex_1().min_w(0).whitespace_nowrap().child(text));
  }

  commentBody(t) {
    const lines = this.fileLines(), marked = this.commented(), s = this.sel;
    const list = v_virtual_list(this.listId, lines.length, lines.map(() => ROW), (i) => String(i),
      (range) => lines.slice(range.start, range.end).map((l, k) => this.lineRow(range.start + k + 1, l, t, marked)))
      .size_full().on_item_click((key, cx) => { this.sel = pickRange(this.sel, Number(key) + 1); cx.notify(); });
    return v_flex().flex_1().min_h(0)
      .child(selectionBar("gc-file-sel", s ? (s.from === s.to ? `Line ${s.from}` : `Lines ${s.from}-${s.to}`) : null, t,
        (cx) => { this.sel = null; cx.notify(); }, (cx) => this.comment(cx)))
      .child(div().flex_1().min_h(0).relative().font_family(mono()).text_size(12)
        .child(div().id(`${this.listId}-x`).size_full().overflow_x_scrollbar()
          .child(div().w_full().min_w(this.width + 80).h_full().child(list)))
        .child(Scrollbar.vertical(this.listId).viewport_from_layout().absolute().inset_0()));
  }

  // Markdown, rendered: GitHub-flavored, as the Notes panel shows a note.
  rendered() {
    return div().id("gc-file-md").flex_1().min_h(0).overflow_y_scrollbar()
      .child(div().max_w(920).px(28).py(18).font_family(PROSE_FONT).text_size(14)
        .child(TextView.markdown("gc-file-md-text", this.text.length > MAX_TEXT ? this.text.slice(0, MAX_TEXT) : this.text).selectable(true)));
  }

  render(cx) {
    const t = theme(), loaded = this.text !== null, md = isMarkdown(this.path);
    const root = v_flex().id("gc-file").size_full().min_h(0).overflow_hidden().bg(t.background).text_color(t.foreground).text_size(13);
    if (!this.path) return root.child(div().p(16).text_color(t.dim).child("Open this file again from the Files panel."));
    const review = reviewButton("gc-file-review", this.space, t);
    return root
      .child(h_flex().h(38).flex_none().px(12).gap(8).items_center().border_b(1).border_color(t.border)
        .child(svg(icon("file")).size(14).flex_none().text_color(t.muted))
        .child(div().min_w(0).truncate().font_semibold().child(this.path))
        .child(copyButton("gc-file-copy", this, this.path, t))
        .child(div().flex_1())
        .when(md && loaded && !this.commenting, (e) => e.child(iconButton("gc-file-source", "eye", this.showSource ? "Show rendered" : "Show source", t,
          (cx) => { this.showSource = !this.showSource; cx.notify(); }, { on: this.showSource, size: 14 })))
        .when(loaded, (e) => e.child(textButton("gc-file-comment", "Comment", t,
          (cx) => { this.commenting = !this.commenting; this.sel = null; cx.notify(); }, { on: this.commenting })))
        .when(Boolean(review), (e) => e.child(review))
        .child(iconButton("gc-file-close", "x", "Close", t, () => this.close())))
      .child(h_flex().h(22).flex_none().px(12).gap(8).items_center().border_b(1).border_color(t.border).text_size(11).text_color(t.dim)
        .child(div().flex_1().min_w(0).truncate().child(`${this.on ? this.on + ":" : ""}${this.root}`))
        .child(div().child(this.loading ? "Loading…" : "")))
      .child(this.commenting && loaded ? this.commentBody(t)
        : md && !this.showSource && this.text ? this.rendered()
        : this.code ? Editor.new(this.code).flex_1().min_h(0)
        : div().p(12).text_color(t.dim).child(this.error || "Loading file…"));
  }
}
