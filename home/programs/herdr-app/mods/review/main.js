// Line comments for the agent. The files-mods file tab and the git-changes diff tab let you pick
// lines and comment on them; this mod is their two dialogs:
//   props.mode "add":  write (or edit) one comment on the picked lines.
//   props.mode "send": every comment of the space, a pick of its agent, and Send.
// Comments live in shared("review.comments"): { [space]: [comment] }, one review per space, so
// comments from both tabs go out together. A comment is
//   { id, kind: "file" | "diff", root, on, path, from, to, label, quote: [line], text, at }
// where from/to are line numbers (file) or row keys (diff), `label` says which lines in words
// and `quote` holds the lines as they read when the comment was made.
import { View, div } from "gpui-kit";
import { v_flex, h_flex, TextareaState, Textarea } from "gpui-base";
import { agents, hc, notify, props, shared, setShared, closeOverlay, theme, settings } from "herdr";

const KEY = "review.comments";
const mono = () => settings().font_family ?? "JetBrains Mono";

export const commentsOf = (space) => (shared(KEY) ?? {})[space] ?? [];
function saveComments(space, list) {
  const all = { ...(shared(KEY) ?? {}) };
  if (list.length) all[space] = list; else delete all[space];
  setShared(KEY, all);
}

// The agent picked first: the focused one, else an idle one, else the one that changed last.
function agentsOf(space) {
  const list = agents().filter(a => a.space === space);
  const first = list.find(a => a.focused) ?? list.find(a => a.status === "idle") ?? [...list].sort((a, b) => b.seq - a.seq)[0];
  return { list, first: first?.address ?? null };
}
const agentName = a => `${a.program?.name ?? a.app ?? "agent"} · ${a.tab_name || `tab ${a.tab_index + 1}`}`;

// Every comment as one message: a heading per comment with its file and lines, the lines in a
// fence, then the comment.
function message(list) {
  const roots = [...new Set(list.map(c => `${c.on ? c.on + ":" : ""}${c.root}`))];
  const sorted = [...list].sort((a, b) => a.root.localeCompare(b.root) || a.path.localeCompare(b.path) || a.at - b.at);
  const parts = sorted.map(c => {
    const where = roots.length > 1 ? `${c.on ? c.on + ":" : ""}${c.root}/${c.path}` : c.path;
    return `### ${where}, ${c.label}${c.kind === "diff" ? " (diff)" : ""}\n\`\`\`\n${c.quote.join("\n")}\n\`\`\`\n${c.text.trim()}`;
  });
  const n = list.length;
  return `Review comments on ${roots.join(", ")}: ${n} comment${n > 1 ? "s" : ""}. File quotes show line numbers; diff quotes mark added lines "+" and removed lines "-", with new-file line numbers.\n\n${parts.join("\n\n")}`;
}

export default class Review extends View {
  init(_props, cx) {
    const p = props() ?? {};
    this.p = p; this.space = p.space;
    if (p.mode === "add") {
      const old = p.editing ? commentsOf(this.space).find(c => c.id === p.editing) : null;
      this.box = TextareaState.new({ placeholder: "Your comment on these lines…", value: old?.text ?? "", rows: 6 });
      // ctrl/cmd-enter adds; plain enter is a new line, so comments can span several.
      this.box.on("submit", (e, cx) => { if (e?.secondary) this.add(cx); });
      this.box.focus();
    } else {
      this.agent = agentsOf(this.space).first;
    }
  }

  close() { if (this.p.overlay) closeOverlay(this.p.overlay); }

  add(cx) {
    const text = this.box.value();
    if (!text.trim()) return;
    const c = this.p.comment, list = commentsOf(this.space).filter(x => x.id !== this.p.editing);
    list.push({ ...c, id: this.p.editing ?? `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`, text, at: Date.now() });
    saveComments(this.space, list);
    this.close();
  }

  remove(id) {
    if (id === this.p.editing) this.close();
    saveComments(this.space, commentsOf(this.space).filter(c => c.id !== id));
  }

  send(cx) {
    const list = commentsOf(this.space), agent = agents().find(a => a.address === this.agent);
    if (!list.length || !agent || this.sending) return;
    this.sending = true; this.error = null; cx.notify();
    // A dialog's tasks end when it closes: close only once the text went out.
    cx.spawn(async cx => {
      const r = await hc(["send", agent.address, message(list)]).catch(e => ({ code: 1, stdout: "", stderr: String(e) }));
      this.sending = false;
      if (r.code === 0) {
        saveComments(this.space, []);
        notify({ title: `Sent to ${agentName(agent)}`, body: `${list.length} comment${list.length > 1 ? "s" : ""}`, level: "success" });
        this.close();
      } else { this.error = (r.stderr || r.stdout).trim().slice(0, 200) || "Send failed"; cx.notify(); }
    });
  }

  button(id, label, t, onClick, opts = {}) {
    return h_flex().id(id).h(28).px(12).flex_none().items_center().justify_center().rounded(7).text_size(12.5)
      .bg(opts.solid ? t.solid : t.raised).text_color(opts.solid ? t.solid_foreground : opts.danger ? t.ansi1 : t.foreground)
      .border_1().border_color(opts.solid ? t.solid : t.border)
      .when(!opts.disabled, el => el.cursor_pointer().hover(s => s.opacity(0.85)).on_click((_e, cx) => onClick(cx)))
      .when(Boolean(opts.disabled), el => el.opacity(0.5))
      .child(label);
  }

  quote(lines, t, max = 8) {
    const shown = lines.slice(0, max);
    return v_flex().px(10).py(6).rounded(7).bg(t.raised).font_family(mono()).text_size(11.5).text_color(t.muted).overflow_hidden()
      .children(shown.map(l => div().whitespace_nowrap().truncate().child(l || " ")))
      .when(lines.length > max, el => el.child(div().text_color(t.dim).child(`… ${lines.length - max} more`)));
  }

  renderAdd(t) {
    const c = this.p.comment, editing = Boolean(this.p.editing);
    return v_flex().size_full().p(16).gap(10)
      .child(h_flex().gap(8).items_center()
        .child(div().font_semibold().text_size(14).child(editing ? "Edit comment" : "Comment"))
        .child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(`${c.path} · ${c.label}`)))
      .child(this.quote(c.quote, t))
      .child(div().flex_1().min_h(0).p(8).rounded(8).border_1().border_color(t.accent).child(Textarea.new(this.box).w_full().text_size(13)))
      .child(h_flex().gap(8).items_center()
        .child(div().flex_1().text_size(11).text_color(t.dim).child("Enter starts a new line · ctrl/cmd-enter adds · Esc cancels"))
        .when(editing, el => el.child(this.button("rv-delete", "Delete", t, () => this.remove(this.p.editing), { danger: true })))
        .child(this.button("rv-cancel", "Cancel", t, () => this.close()))
        .child(this.button("rv-add", editing ? "Save" : "Add comment", t, cx => this.add(cx), { solid: true })));
  }

  renderSend(t) {
    const list = commentsOf(this.space), { list: agentList } = agentsOf(this.space);
    if (this.agent && !agentList.some(a => a.address === this.agent)) this.agent = agentsOf(this.space).first;
    const n = list.length;
    const card = c => v_flex().gap(6).p(10).rounded(8).border_1().border_color(t.border).bg(t.surface ?? t.background)
      .child(h_flex().gap(8).items_center()
        .child(div().flex_1().min_w(0).truncate().font_semibold().text_size(12.5).child(`${c.path} · ${c.label}${c.kind === "diff" ? " (diff)" : ""}`))
        .child(div().id(`rv-rm-${c.id}`).px(6).rounded(5).cursor_pointer().text_color(t.dim).hover(s => s.bg(t.hover).text_color(t.ansi1))
          .on_click(() => this.remove(c.id)).child("×")))
      .child(this.quote(c.quote, t, 4))
      .child(div().text_size(12.5).whitespace_normal().child(c.text));
    return v_flex().size_full().min_h(0)
      .child(h_flex().h(46).flex_none().px(16).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().text_size(14).child("Review"))
        .child(div().text_color(t.dim).child(`${n} comment${n === 1 ? "" : "s"}`))
        .child(div().flex_1())
        .when(n > 0, el => el.child(this.button("rv-clear", "Clear all", t, () => saveComments(this.space, []), { danger: true }))))
      .child(v_flex().id("rv-list").flex_1().min_h(0).overflow_y_scrollbar().p(12).gap(8)
        .children(list.map(card))
        .when(!n, el => el.child(div().p(8).text_color(t.dim).child("No comments yet. Pick lines in a file or diff tab and comment on them."))))
      .child(v_flex().flex_none().p(12).gap(8).border_t(1).border_color(t.border)
        .child(div().text_size(11).font_semibold().text_color(t.dim).child("SEND TO"))
        .child(h_flex().flex_wrap().gap(6)
          .children(agentList.map(a => {
            const on = a.address === this.agent;
            return h_flex().id(`rv-agent-${a.address}`).h(26).px(9).gap(6).items_center().rounded(6).cursor_pointer().text_size(12)
              .bg(on ? t.selected : t.raised).border_1().border_color(on ? t.accent : t.border).text_color(on ? t.foreground : t.muted)
              .hover(s => s.bg(t.hover)).on_click((_e, cx) => { this.agent = a.address; cx.notify(); })
              .child(div().size(7).rounded(4).bg(a.status === "working" ? t.working : a.status === "blocked" ? t.blocked : t.idle))
              .child(agentName(a));
          }))
          .when(!agentList.length, el => el.child(div().text_size(12).text_color(t.dim).child("No agent in this space. Start one first."))))
        .when(Boolean(this.error), el => el.child(div().text_size(12).text_color(t.ansi1).child(this.error)))
        .child(h_flex().gap(8).justify_end()
          .child(this.button("rv-close", "Close", t, () => this.close()))
          .child(this.button("rv-send", this.sending ? "Sending…" : "Send", t, cx => this.send(cx),
            { solid: true, disabled: !n || !this.agent || this.sending }))));
  }

  render(cx) {
    const t = theme();
    return div().id("review").size_full().bg(t.popover ?? t.background).text_color(t.foreground).text_size(13)
      .child(this.p.mode === "add" ? this.renderAdd(t) : this.renderSend(t));
  }
}
