// Notes for the shown tab: one markdown file per tab in ~/.config/herdr-app/tab-notes,
// deleted once its tab is gone (only judged on machines that are ready and have listed
// spaces this session, so a failed first read never wipes a machine's notes).
// Vim modes: normal shows the note rendered (GitHub-flavored markdown), insert shows the
// raw text to type in. i/a/I/A/o/O enter insert and Escape leaves it; in normal mode
// j/k, ctrl-d/u, ctrl-f/b, gg and G scroll.
import { View, div } from "gpui-kit";
import { v_flex, h_flex, TextareaState, Textarea, TextView } from "gpui-base";
import { spaces, machines, readTextFile, writeTextFile, appHome, theme, settings } from "herdr";
import * as fs from "fs/promises";

const dir = () => `${appHome()}/tab-notes`;
const file = id => `${dir()}/${encodeURIComponent(id)}.md`;
const machineOf = id => id.includes("/") ? id.split("/")[0] : null;
const activeTab = () => spaces().find(s => s.active)?.tabs.find(t => t.active) ?? null;
const alive = id => spaces().some(s => s.tabs.some(t => t.id === id));
const ready = name => machines().some(m => m.name === name && m.layout === "ready");
const LINE = 20;
// Herdr's UI font (Geist) ships only its regular face, and the app draws a variable font
// (Noto Sans here) at its default weight, so bold needs a family with a static bold file.
const PROSE_FONT = "Liberation Sans";

// writeTextFile replaces the file atomically; passing what is on disk now makes it a plain overwrite.
async function save(id, text) {
  if (text.trim()) {
    await fs.mkdir(dir(), { recursive: true });
    await writeTextFile(file(id), text, await readTextFile(file(id)).catch(() => null));
  } else if (await fs.exists(file(id))) await fs.unlink(file(id));
}

export default class Notes extends View {
  init(_props, cx) {
    this.tab = null; this.input = null; this.dirty = false; this.gen = 0;
    this.pending = Promise.resolve(); this.known = new Set(); this.unsaved = new Map();
    this.handle = cx.focus_handle(); this.mode = "normal"; this.g = false;
    this.scroll = 0; this.viewH = 0; this.docH = 0;
    cx.timer.every(800, cx => this.flush(cx));
  }

  // Saves run one after another on this.pending, and a read waits for it, so an older
  // save never lands after a newer one and switching back never reads a half-saved note.
  // A failed save keeps its text in this.unsaved until its tab is shown again.
  flush(cx) {
    if (!this.dirty || !this.input || !alive(this.tab)) return;
    this.dirty = false;
    const id = this.tab, text = this.input.value();
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
    this.input?.release(); this.input = null; this.tab = id; this.error = null; this.dirty = false;
    this.mode = "normal"; this.g = false; this.scroll = 0;
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
      // A textarea rather than an Editor: only a textarea can take the keyboard from a key press.
      this.input = TextareaState.new({ value: text });
      this.input.on("change", () => { this.dirty = true; });
      this.dirty = this.unsaved.has(id);
      cx.notify();
    });
  }

  // The textarea keeps its cursor while hidden, so i and a go back to where it was.
  // The rendered view has no cursor of its own: I and O mean the top, A and o the end.
  insert(where, cx) {
    const input = this.input, text = input.value(), at = n => input.set_selected_range({ start: n, end: n });
    if (where === "top") at(0);
    else if (where === "end") at(text.length);
    else if (where === "above") { at(0); input.replace("\n"); at(0); this.dirty = true; }
    else if (where === "below") { at(text.length); if (text && !text.endsWith("\n")) { input.replace("\n"); this.dirty = true; } }
    this.mode = "insert";
    // The textarea is drawn on the next frame, so focus it again once it is there.
    input.focus();
    cx.timer.after(50, () => { if (this.input === input && this.mode === "insert") input.focus(); });
    cx.notify();
  }

  normal(cx) {
    this.mode = "normal"; this.g = false;
    this.handle.focus(); this.flush(cx); cx.notify();
  }

  // The rendered note sits in a clipped box and moves up by this.scroll, so keys can scroll it.
  scrollTo(y, cx) {
    const next = Math.min(Math.max(0, this.docH - this.viewH), Math.max(0, y));
    if (next !== this.scroll) { this.scroll = next; cx.notify(); }
  }

  key(e, cx) {
    if (!this.input) return;
    if (this.mode === "insert") {
      if (e.key === "escape") { this.normal(cx); cx.stop_propagation(); }
      return;
    }
    const m = e.modifiers, plain = !(m?.control || m?.alt || m?.platform);
    const g = this.g, page = Math.max(LINE, this.viewH - 2 * LINE);
    this.g = false;
    switch ((plain && e.key_char) || e.keystroke) {
      case "i": case "a": this.insert(null, cx); break;
      case "I": this.insert("top", cx); break;
      case "A": this.insert("end", cx); break;
      case "o": this.insert("below", cx); break;
      case "O": this.insert("above", cx); break;
      case "j": case "down": this.scrollTo(this.scroll + LINE, cx); break;
      case "k": case "up": this.scrollTo(this.scroll - LINE, cx); break;
      case "ctrl-d": this.scrollTo(this.scroll + page / 2, cx); break;
      case "ctrl-u": this.scrollTo(this.scroll - page / 2, cx); break;
      case "ctrl-f": case "pagedown": this.scrollTo(this.scroll + page, cx); break;
      case "ctrl-b": case "pageup": this.scrollTo(this.scroll - page, cx); break;
      case "g": if (g) this.scrollTo(0, cx); else this.g = true; break;
      case "G": this.scrollTo(Infinity, cx); break;
      default: return;
    }
    cx.stop_propagation();
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
    if (this.dirty && this.input && alive(this.tab)) await save(this.tab, this.input.value());
  }

  rendered(t) {
    const text = this.input.value();
    return div().id("notes-view").flex_1().min_h(0).relative().overflow_hidden()
      .on_size_change((s, cx) => { this.viewH = s.height; this.scrollTo(this.scroll, cx); })
      .on_scroll_wheel((e, cx) => this.scrollTo(this.scroll - e.delta.y, cx))
      .child(div().id("notes-doc").absolute().top(-this.scroll).left(0).right(0).px(14).py(10).font_family(PROSE_FONT)
        .on_size_change((s, cx) => { this.docH = s.height; this.scrollTo(this.scroll, cx); })
        .child(text.trim() ? TextView.markdown("notes-md", text)
          : div().text_color(t.dim).child("Empty note. Press i to write.")));
  }

  render(cx) {
    const tab = activeTab();
    if ((tab?.id ?? null) !== this.tab) this.open(tab?.id ?? null, cx);
    const seen = JSON.stringify([machines(), spaces().map(s => s.tabs.map(t => t.id))]);
    if (seen !== this.seen) { this.seen = seen; this.collect(cx); }
    const t = theme(), insert = this.mode === "insert";
    return v_flex().id("notes").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13)
      .track_focus(this.handle).on_key_down((e, cx) => this.key(e, cx))
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Notes"))
        .when(Boolean(this.input), el => el.child(div().id("notes-mode").h(20).px(6).flex().items_center().rounded(5).text_size(10).font_semibold().cursor_pointer()
          .bg(insert ? t.solid : t.raised).text_color(insert ? t.solid_foreground : t.dim)
          .on_click((_e, cx) => insert ? this.normal(cx) : this.insert(null, cx))
          .child(insert ? "INSERT" : "NORMAL")))
        .child(div().flex_1().min_w(0).truncate().text_right().text_size(12).text_color(t.dim).child(tab?.name ?? "")))
      .when(Boolean(this.error), el => el.child(div().px(14).py(6).text_size(11).text_color(t.ansi1).child(this.error)))
      .child(!this.input ? div().p(12).text_color(t.dim).child(!tab ? "No tab" : this.error ? "" : "Loading note…")
        : insert ? div().flex_1().min_h(0).p(6).child(Textarea.new(this.input).size_full().px(8).py(4).font_family(settings().font_family).text_size(13).text_color(t.foreground))
        : this.rendered(t));
  }
}
