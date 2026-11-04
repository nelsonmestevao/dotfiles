// Notes for the shown tab: one markdown file per tab in ~/.config/herdr-app/tab-notes.
// Once its tab is gone a note moves to tab-notes/archive (only judged on machines that are
// ready and have listed spaces this session, so a failed first read never touches a
// machine's notes), and an empty note lists the archived ones to bring one back.
// Vim modes: normal shows the note rendered (GitHub-flavored markdown), insert shows the
// raw text to type in. i/a/I/A/o/O enter insert and Escape leaves it; in normal mode
// j/k, ctrl-d/u, ctrl-f/b, gg and G scroll, and S sends the note to the tab's agent.
// The header counts the note's tasks and ticks them. alt-shift-n (handled by better-tabs)
// shows the panel and gives it the keyboard, or hands the keyboard back to the tab when
// the notes already have it.
import { View, div } from "gpui-kit";
import { v_flex, h_flex, TextareaState, Textarea, TextView, Popover } from "gpui-base";
import { spaces, machines, agents, readTextFile, writeTextFile, appHome, theme, settings, shared, hc, notify } from "herdr";
import * as fs from "fs/promises";

const dir = () => `${appHome()}/tab-notes`;
const archiveDir = () => `${dir()}/archive`;
const file = id => `${dir()}/${encodeURIComponent(id)}.md`;
const machineOf = id => id.includes("/") ? id.split("/")[0] : null;
const activeTab = () => spaces().find(s => s.active)?.tabs.find(t => t.active) ?? null;
const alive = id => spaces().some(s => s.tabs.some(t => t.id === id));
const ready = name => machines().some(m => m.name === name && m.layout === "ready");
const LINE = 20;
// Herdr's UI font (Geist) ships only its regular face, and the app draws a variable font
// (Noto Sans here) at its default weight, so bold needs a family with a static bold file.
const PROSE_FONT = "Liberation Sans";

// Markdown marks taken out, for a task's text or an archived note's title.
const plain = s => s.replace(/!?\[([^\]]*)\]\([^)]*\)/g, "$1").replace(/\*\*|__|~~|`/g, "").trim();
const title = line => plain(line.replace(/^\s*#+\s*/, "").replace(/^\s*(?:[-*+]|\d+[.)])\s+(?:\[[ xX]\]\s+)?/, ""));

// Archived names start with the local time, so they sort oldest first and read well in a folder.
function stamp(d = new Date()) {
  const p = n => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}.${p(d.getMinutes())}.${p(d.getSeconds())}`;
}

// GFM task items outside fenced code: where the mark between the brackets is (a UTF-16
// offset, as text ranges take), whether it is ticked, and the item's text.
function tasks(text) {
  const out = [];
  let fence = null, at = 0;
  for (const line of text.split("\n")) {
    const f = line.match(/^ {0,3}(`{3,}|~{3,})(.*)$/);
    if (fence) { if (f && f[1][0] === fence[0] && f[1].length >= fence.length && !f[2].trim()) fence = null; }
    else if (f) fence = f[1];
    else {
      const m = line.match(/^(\s*(?:[-*+]|\d+[.)])\s+\[)([ xX])\]\s+(.*)$/);
      if (m) out.push({ mark: at + m[1].length, done: m[2] !== " ", text: plain(m[3]) });
    }
    at += line.length + 1;
  }
  return out;
}

// The agent a note goes to: one in its tab (the focused one first), else the space's
// focused, idle or first agent.
function agentFor(tab) {
  const space = spaces().find(s => s.tabs.some(t => t.id === tab))?.id;
  const list = agents().filter(a => a.space === space), here = list.filter(a => a.tab === tab);
  return here.find(a => a.focused) ?? here[0] ?? list.find(a => a.focused) ?? list.find(a => a.status === "idle") ?? list[0] ?? null;
}

// writeTextFile replaces the file atomically; passing what is on disk now makes it a plain overwrite.
async function save(id, text) {
  if (text.trim()) {
    await fs.mkdir(dir(), { recursive: true });
    await writeTextFile(file(id), text, await readTextFile(file(id)).catch(() => null));
  } else if (await fs.exists(file(id))) await fs.unlink(file(id));
}

// Moves a gone tab's note into the archive. The copy is written first, so a failed write loses nothing.
async function archive(name) {
  const text = await readTextFile(`${dir()}/${name}`);
  if (text?.trim()) {
    await fs.mkdir(archiveDir(), { recursive: true });
    await fs.writeFile(`${archiveDir()}/${stamp()} ${name}`, text);
  }
  await fs.unlink(`${dir()}/${name}`);
}

export default class Notes extends View {
  init(_props, cx) {
    this.tab = null; this.input = null; this.dirty = false; this.gen = 0;
    this.pending = Promise.resolve(); this.known = new Set(); this.unsaved = new Map();
    this.handle = cx.focus_handle(); this.mode = "normal"; this.g = false;
    this.scroll = 0; this.viewH = 0; this.docH = 0;
    this.archived = []; this.tasksOpen = false; this.focusSeen = 0; this.inputFocused = false; this.letGo = false;
    cx.timer.every(800, cx => this.flush(cx));
    this.loadArchive(cx);
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
    this.input?.release(); this.input = null; this.inputFocused = false; this.tab = id; this.error = null; this.dirty = false;
    this.mode = "normal"; this.g = false; this.scroll = 0; this.tasksOpen = false;
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
      this.input.on("focus", (_e, cx) => { this.inputFocused = true; cx.notify(); });
      this.input.on("blur", (_e, cx) => { this.inputFocused = false; cx.notify(); });
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
    this.mode = "insert"; this.tasksOpen = false;
    // The textarea is drawn on the next frame, so focus it again once it is there.
    input.focus();
    cx.timer.after(50, () => { if (this.input === input && this.mode === "insert") input.focus(); });
    cx.notify();
  }

  normal(cx) {
    this.mode = "normal"; this.g = false;
    this.handle.focus(); this.flush(cx); cx.notify();
  }

  // alt-shift-n: better-tabs shows the panel and stamps this shared key with the time.
  // A stamp from before this copy started (shared values persist) is old news.
  wantFocus(cx) {
    const ask = shared("tab-notes.focus");
    if (typeof ask !== "number" || ask <= this.focusSeen) return;
    this.focusSeen = ask;
    if (Date.now() - ask > 3000) return;
    const here = this.handle.is_focused() || (this.mode === "insert" && this.inputFocused);
    if (this.mode === "insert") { this.mode = "normal"; this.g = false; this.flush(cx); }
    // Pressed while the notes have the keyboard: drop the focus target for a frame. Herdr
    // gives a keyboard whose holder left the screen back to the tab's focused pane.
    if (here) {
      this.letGo = true; this.inputFocused = false;
      cx.timer.after(50, cx => { this.letGo = false; cx.notify(); });
      return;
    }
    // The panel may only be on screen a frame or two later.
    for (const ms of [30, 200]) cx.timer.after(ms, () => { if (!this.handle.is_focused()) this.handle.focus(); });
  }

  // The rendered note sits in a clipped box and moves up by this.scroll, so keys can scroll it.
  scrollTo(y, cx) {
    const next = Math.min(Math.max(0, this.docH - this.viewH), Math.max(0, y));
    if (next !== this.scroll) { this.scroll = next; cx.notify(); }
  }

  // Ticks or unticks a task through the textarea, which keeps undo and the change event.
  toggle(task, cx) {
    const input = this.input;
    // The text may have changed since the list was drawn.
    const now = input && tasks(input.value()).find(x => x.mark === task.mark);
    if (!now) return;
    input.set_selected_range({ start: now.mark, end: now.mark + 1 });
    input.replace(now.done ? " " : "x");
    this.dirty = true; this.flush(cx); cx.notify();
  }

  send(cx) {
    const text = this.input?.value().trim();
    if (!text) return;
    const agent = agentFor(this.tab);
    if (!agent) { notify({ title: "No agent in this space", body: "Start an agent in this tab first.", level: "warning" }); return; }
    const name = agent.program?.name ?? agent.address, what = text.split("\n").map(title).find(Boolean) ?? "";
    cx.spawn(async () => {
      const r = await hc(["send", agent.address, text]).catch(e => ({ code: 1, stdout: "", stderr: String(e) }));
      if (r.code === 0) notify({ title: `Note sent to ${name}`, body: what, level: "success" });
      else notify({ title: "Send failed", body: (r.stderr || r.stdout).trim().slice(0, 200), level: "error" });
    });
  }

  key(e, cx) {
    if (!this.input) return;
    if (this.mode === "insert") {
      if (e.key === "escape") { this.normal(cx); cx.stop_propagation(); }
      return;
    }
    const m = e.modifiers, bare = !(m?.control || m?.alt || m?.platform);
    const g = this.g, page = Math.max(LINE, this.viewH - 2 * LINE);
    this.g = false;
    switch ((bare && e.key_char) || e.keystroke) {
      case "i": case "a": this.insert(null, cx); break;
      case "I": this.insert("top", cx); break;
      case "A": this.insert("end", cx); break;
      case "o": this.insert("below", cx); break;
      case "O": this.insert("above", cx); break;
      case "S": this.send(cx); break;
      case "j": case "down": this.scrollTo(this.scroll + LINE, cx); break;
      case "k": case "up": this.scrollTo(this.scroll - LINE, cx); break;
      case "ctrl-d": this.scrollTo(this.scroll + page / 2, cx); break;
      case "ctrl-u": this.scrollTo(this.scroll - page / 2, cx); break;
      case "ctrl-f": case "pagedown": this.scrollTo(this.scroll + page, cx); break;
      case "ctrl-b": case "pageup": this.scrollTo(this.scroll - page, cx); break;
      case "g": if (g) this.scrollTo(0, cx); else this.g = true; break;
      case "G": this.scrollTo(Infinity, cx); break;
      case "escape": if (!this.tasksOpen) return; this.tasksOpen = false; cx.notify(); break;
      default: return;
    }
    cx.stop_propagation();
  }

  collect(cx) {
    for (const s of spaces()) this.known.add(s.machine);
    cx.spawn(async cx => {
      const names = await fs.readdir(dir()).catch(() => []);
      let moved = false;
      for (const n of names) {
        if (!n.endsWith(".md")) continue;
        let id;
        try { id = decodeURIComponent(n.slice(0, -3)); } catch { continue; }
        const m = machineOf(id);
        if (this.known.has(m) && ready(m) && !alive(id)) moved = await archive(n).then(() => true, () => moved);
      }
      if (moved) this.loadArchive(cx);
    });
  }

  // The newest archived notes, which an empty note offers back.
  loadArchive(cx) {
    cx.spawn(async cx => {
      const names = (await fs.readdir(archiveDir()).catch(() => [])).filter(n => n.endsWith(".md")).sort().reverse().slice(0, 30);
      const list = [];
      for (const n of names) {
        const text = await readTextFile(`${archiveDir()}/${n}`).catch(() => null);
        const name = text?.split("\n").map(title).find(Boolean);
        if (name) list.push({ path: `${archiveDir()}/${n}`, title: name, when: n.slice(0, 16).replace(".", ":") });
      }
      this.archived = list;
      cx.notify();
    });
  }

  // Brings an archived note into this tab's empty note, and drops it from the archive once saved.
  restore(entry, cx) {
    const input = this.input, id = this.tab;
    cx.spawn(async cx => {
      const text = await readTextFile(entry.path).catch(e => { this.error = `Cannot read archived note: ${e}`; return null; });
      if (text === null || this.input !== input) { cx.notify(); return; }
      input.set_value(text); this.dirty = true; this.flush(cx);
      await this.pending;
      if (this.tab === id && !this.dirty && !this.error) await fs.unlink(entry.path).catch(() => {});
      this.loadArchive(cx);
    });
  }

  async close() {
    await this.pending;
    if (this.dirty && this.input && alive(this.tab)) await save(this.tab, this.input.value());
  }

  tasksChip(t, list) {
    const done = list.filter(x => x.done).length;
    const chip = div().id("notes-tasks").h(20).px(6).flex().items_center().rounded(5).text_size(11).cursor_pointer()
      .bg(this.tasksOpen ? t.selected : t.raised).text_color(done === list.length ? t.ansi2 : t.muted).hover(s => s.bg(t.hover))
      .tooltip("Tasks done").child(`${done}/${list.length}`);
    const row = (x, i) => h_flex().id(`notes-task-${i}`).px(8).py(6).gap(8).items_center().rounded(6).cursor_pointer().hover(s => s.bg(t.hover))
      .on_click((_e, cx) => this.toggle(x, cx))
      .child(div().size(14).flex_none().flex().items_center().justify_center().rounded(4).border_1()
        .border_color(x.done ? t.accent : t.border).bg(x.done ? t.accent : t.background).text_size(10).text_color(t.accent_foreground).child(x.done ? "✓" : ""))
      .child(div().flex_1().min_w(0).text_size(12).text_color(x.done ? t.dim : t.foreground).when(x.done, el => el.line_through()).child(x.text || " "));
    return Popover.new("notes-tasks-list").open(this.tasksOpen).on_open_change((open, cx) => { this.tasksOpen = open; cx.notify(); })
      .trigger(chip)
      .content(v_flex().id("notes-tasks-scroll").mt(4).min_w(240).max_w(340).max_h(360).overflow_y_scrollbar().p(6).gap(2)
        .rounded(8).border_1().border_color(t.border).bg(t.popover).shadow_md().children(list.map(row)));
  }

  empty(t) {
    return v_flex().gap(14)
      .child(div().text_color(t.dim).child("Empty note. Press i to write."))
      .when(this.archived.length > 0, el => el.child(v_flex().gap(2)
        .child(div().px(8).pb(4).text_size(11).font_semibold().text_color(t.muted).child("Archived notes"))
        .children(this.archived.map((a, i) => h_flex().id(`archived-${i}`).px(8).py(6).gap(8).items_center().rounded(6).cursor_pointer().hover(s => s.bg(t.hover))
          .tooltip("Bring this note back to this tab")
          .on_click((_e, cx) => this.restore(a, cx))
          .child(div().flex_1().min_w(0).truncate().child(a.title))
          .child(div().flex_none().text_size(11).text_color(t.dim).child(a.when))))));
  }

  rendered(t) {
    const text = this.input.value();
    return div().id("notes-view").flex_1().min_h(0).relative().overflow_hidden()
      .on_size_change((s, cx) => { this.viewH = s.height; this.scrollTo(this.scroll, cx); })
      .on_scroll_wheel((e, cx) => this.scrollTo(this.scroll - e.delta.y, cx))
      .child(div().id("notes-doc").absolute().top(-this.scroll).left(0).right(0).px(14).py(10).font_family(PROSE_FONT)
        .on_size_change((s, cx) => { this.docH = s.height; this.scrollTo(this.scroll, cx); })
        .child(text.trim() ? TextView.markdown("notes-md", text) : this.empty(t)));
  }

  render(cx) {
    const tab = activeTab();
    if ((tab?.id ?? null) !== this.tab) this.open(tab?.id ?? null, cx);
    const seen = JSON.stringify([machines(), spaces().map(s => s.tabs.map(t => t.id))]);
    if (seen !== this.seen) { this.seen = seen; this.collect(cx); }
    this.wantFocus(cx);
    const t = theme(), insert = this.mode === "insert";
    const text = this.input?.value() ?? "", list = tasks(text);
    const small = (id, label, tip, action) => div().id(id).h(20).px(6).flex().items_center().rounded(5).text_size(11).cursor_pointer()
      .bg(t.raised).text_color(t.muted).hover(s => s.bg(t.hover).text_color(t.foreground)).tooltip(tip).on_click(action).child(label);
    // An accent border while the notes have the keyboard, like a focused terminal pane's:
    // the root's own focus style in normal mode, the textarea's focus events in insert.
    return v_flex().id("notes").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1()
      .border_color(insert && this.inputFocused ? t.accent : t.border).focus(s => s.border_color(t.accent)).text_color(t.foreground).text_size(13)
      .when(!this.letGo, el => el.track_focus(this.handle)).on_key_down((e, cx) => this.key(e, cx))
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Notes"))
        .when(Boolean(this.input), el => el.child(div().id("notes-mode").h(20).px(6).flex().items_center().rounded(5).text_size(10).font_semibold().cursor_pointer()
          .bg(insert ? t.solid : t.raised).text_color(insert ? t.solid_foreground : t.dim)
          .on_click((_e, cx) => insert ? this.normal(cx) : this.insert(null, cx))
          .child(insert ? "INSERT" : "NORMAL")))
        .when(list.length > 0, el => el.child(this.tasksChip(t, list)))
        .child(div().flex_1().min_w(0).truncate().text_right().text_size(12).text_color(t.dim).child(tab?.name ?? ""))
        .when(Boolean(text.trim()), el => el.child(small("notes-send", "Send", "Send this note to the tab's agent (S)", (_e, cx) => this.send(cx)))))
      .when(Boolean(this.error), el => el.child(div().px(14).py(6).text_size(11).text_color(t.ansi1).child(this.error)))
      .child(!this.input ? div().p(12).text_color(t.dim).child(!tab ? "No tab" : this.error ? "" : "Loading note…")
        : insert ? div().flex_1().min_h(0).p(6).child(Textarea.new(this.input).size_full().px(8).py(4).font_family(settings().font_family).text_size(13).text_color(t.foreground))
        : this.rendered(t));
  }
}
