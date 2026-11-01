// Notes for the shown tab: one markdown file per tab in ~/.config/herdr-app/tab-notes,
// deleted once its tab is gone (only judged on machines that are ready and have listed
// spaces this session, so a failed first read never wipes a machine's notes).
import { View, div } from "gpui-kit";
import { v_flex, h_flex, Editor, EditorState } from "gpui-base";
import { spaces, machines, readTextFile, writeTextFile, appHome, theme, settings } from "herdr";
import * as fs from "fs/promises";

const dir = () => `${appHome()}/tab-notes`;
const file = id => `${dir()}/${encodeURIComponent(id)}.md`;
const machineOf = id => id.includes("/") ? id.split("/")[0] : null;
const activeTab = () => spaces().find(s => s.active)?.tabs.find(t => t.active) ?? null;
const alive = id => spaces().some(s => s.tabs.some(t => t.id === id));
const ready = name => machines().some(m => m.name === name && m.layout === "ready");

// writeTextFile replaces the file atomically; passing what is on disk now makes it a plain overwrite.
async function save(id, text) {
  if (text.trim()) {
    await fs.mkdir(dir(), { recursive: true });
    await writeTextFile(file(id), text, await readTextFile(file(id)).catch(() => null));
  } else if (await fs.exists(file(id))) await fs.unlink(file(id));
}

export default class Notes extends View {
  init(_props, cx) {
    this.tab = null; this.editor = null; this.dirty = false; this.gen = 0;
    this.pending = Promise.resolve(); this.known = new Set(); this.unsaved = new Map();
    cx.timer.every(800, cx => this.flush(cx));
  }

  // Saves run one after another on this.pending, and a read waits for it, so an older
  // save never lands after a newer one and switching back never reads a half-saved note.
  // A failed save keeps its text in this.unsaved until its tab is shown again.
  flush(cx) {
    if (!this.dirty || !this.editor || !alive(this.tab)) return;
    this.dirty = false;
    const id = this.tab, text = this.editor.value();
    const prev = this.pending;
    let done;
    this.pending = new Promise(r => { done = r; });
    cx.spawn(async cx => {
      await prev;
      try { await save(id, text); this.unsaved.delete(id); if (this.tab === id) this.error = null; }
      catch (e) {
        if (this.tab === id) { this.error = `Save failed: ${e}`; this.dirty = true; }
        else this.unsaved.set(id, text);
      }
      finally { done(); }
      cx.notify();
    });
  }

  open(id, cx) {
    this.flush(cx);
    this.editor?.release(); this.editor = null; this.tab = id; this.error = null; this.dirty = false;
    if (!id) return;
    const gen = ++this.gen;
    cx.spawn(async cx => {
      await this.pending;
      let text = this.unsaved.get(id);
      if (text === undefined) {
        try { text = (await readTextFile(file(id))) ?? ""; }
        catch (e) {
          // No editor: typing into an empty one would overwrite the note that failed to load.
          if (this.gen === gen) { this.error = `Cannot read note: ${e}`; cx.notify(); }
          return;
        }
      }
      if (this.gen !== gen) return;
      this.editor = EditorState.new({ language: "md", value: text, line_numbers: false, folding: false, soft_wrap: true,
        font_family: settings().font_family, font_size: 13 });
      this.editor.on("change", () => { this.dirty = true; });
      this.dirty = this.unsaved.has(id);
      cx.notify();
    });
  }

  collect(cx) {
    for (const s of spaces()) this.known.add(s.machine);
    cx.spawn(async () => {
      const names = await fs.readdir(dir()).catch(() => []);
      for (const n of names) {
        if (!n.endsWith(".md")) continue;
        let id;
        try { id = decodeURIComponent(n.slice(0, -3)); } catch { continue; }
        const m = machineOf(id);
        if (this.known.has(m) && ready(m) && !alive(id)) await fs.unlink(`${dir()}/${n}`).catch(() => {});
      }
    });
  }

  async close() {
    await this.pending;
    if (this.dirty && this.editor && alive(this.tab)) await save(this.tab, this.editor.value());
  }

  render(cx) {
    const tab = activeTab();
    if ((tab?.id ?? null) !== this.tab) this.open(tab?.id ?? null, cx);
    const seen = JSON.stringify([machines(), spaces().map(s => s.tabs.map(t => t.id))]);
    if (seen !== this.seen) { this.seen = seen; this.collect(cx); }
    const t = theme();
    return v_flex().id("notes").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13)
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Notes"))
        .child(div().flex_1().min_w(0).truncate().text_right().text_size(12).text_color(t.dim).child(tab?.name ?? "")))
      .when(Boolean(this.error), el => el.child(div().px(14).py(6).text_size(11).text_color(t.ansi1).child(this.error)))
      .child(this.editor ? Editor.new(this.editor).flex_1().min_h(0).p(6)
        : div().p(12).text_color(t.dim).child(!tab ? "No tab" : this.error ? "" : "Loading note…"));
  }
}
