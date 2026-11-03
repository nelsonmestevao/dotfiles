import { div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { closeOverlay, props, spaces, theme } from "herdr";
import {
  commentAgentPicker, commentBadge, commentButton, commentsFor, idleCommentAgents,
  removeSavedComment, savedCommentCard, sendSavedComment,
} from "./comments.js";
import { lineLabel } from "./comment-model.js";
import { icon } from "./ui.js";

export class CommentOverview {
  init() {
    const config = props() ?? {};
    this.source = config.source;
    this.space = config.space ?? spaces().find(space => space.active)?.id;
    this.overlay = config.overlay;
    this.target = null;
    this.sending = null;
    this.message = null;
  }

  notes() {
    return this.source?.root ? commentsFor(this.source) : [];
  }

  send(id, cx) {
    if (this.sending) return;
    const note = this.notes().find(note => note.id === id);
    if (!note || note.sentAt) return;
    this.sending = id;
    this.message = null;
    cx.notify();
    cx.spawn(async cx => {
      try {
        await sendSavedComment(note, this.target, this.space);
        this.message = { text: "Comment and code sent to the agent." };
      } catch (error) {
        this.message = { text: String(error.message ?? error), error: true };
      } finally {
        this.sending = null;
        cx.notify();
      }
    });
  }

  remove(id, cx) {
    if (this.sending || !this.notes().some(note => note.id === id)) return;
    removeSavedComment(id);
    this.message = { text: "Comment removed." };
    cx.notify();
  }

  agentPicker(t, idle) {
    return h_flex().h(38).flex_none().px(9).items_center().rounded(6).border(1).border_color(t.border).bg(t.surface)
      .child(commentAgentPicker(t, {
        id: "review-comment-agents", agents: idle, target: this.target, enabled: !this.sending,
        select: (address, cx) => { this.target = address; cx.notify(); },
      }));
  }

  card(note, canSend, t) {
    const version = note.side === "old" ? note.base ?? "Original code" : "Current code";
    const location = `${note.path}:${lineLabel(note)}`;
    return savedCommentCard(t)
      .child(h_flex().gap(8).items_center()
        .child(div().flex_1().min_w(0).truncate().font_semibold().text_size(12).child(location))
        .child(div().flex_none().px(6).py(2).rounded(4).bg(t.surface).text_size(11).text_color(t.muted).child(version)))
      .child(div().w_full().min_w(0).text_size(13).whitespace_normal().child(note.text))
      .child(h_flex().justify_end().items_center().gap(6)
        .child(commentButton(`overview-remove-${note.id}`, "Remove", t, cx => this.remove(note.id, cx), { enabled: !this.sending }))
        .child(note.sentAt ? div().text_size(11).text_color(t.ansi2).child(`Sent to ${note.sentTo}`) :
          commentButton(`overview-send-${note.id}`, this.sending === note.id ? "Sending…" : "Send to agent", t,
            cx => this.send(note.id, cx), { primary: true, enabled: canSend })));
  }

  render() {
    const t = theme(), notes = this.notes(), idle = idleCommentAgents(this.space);
    const canSend = !this.sending && idle.some(agent => agent.address === this.target);
    return v_flex().size_full().min_h(0).p(14).gap(10).bg(t.popover).text_color(t.foreground).text_size(13)
      .child(h_flex().h(38).flex_none().gap(9).items_center()
        .child(commentBadge(t))
        .child(v_flex().flex_1().min_w(0)
          .child(div().truncate().text_size(14).font_semibold().child(`Review comments (${notes.length})`))
          .child(div().truncate().text_size(11).text_color(t.muted).child(this.source?.root ?? "")))
        .child(commentButton("overview-close", "Close", t, () => closeOverlay(this.overlay), { enabled: !this.sending })))
      .when(notes.length > 0, e => e.child(this.agentPicker(t, idle)))
      .child(v_flex().id("review-comments-list").flex_1().min_h(0).gap(8).overflow_y_scrollbar()
        .when(!notes.length, e => e.child(savedCommentCard(t)
          .child(div().font_semibold().child("No saved comments in this repository."))
          .child(div().text_size(12).text_color(t.muted).child("Save a comment on a code line to see it here."))))
        .children(notes.map(note => this.card(note, canSend, t))))
      .child(h_flex().h(18).flex_none().gap(5).items_center().text_size(11)
        .text_color(this.message?.error ? t.ansi1 : this.message ? t.ansi2 : t.muted)
        .when(this.message && !this.message.error, e => e.child(icon("check", 12)))
        .child(div().flex_1().min_w(0).truncate().child(this.message?.text ?? "Comments stay local until you send them.")));
  }
}
