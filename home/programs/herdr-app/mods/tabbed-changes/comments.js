// A retained inline thread: mounted beneath its code line, never in a separate panel.
import { View, div } from 'gpui-kit';
import { v_flex, h_flex, TextareaState, Textarea } from 'gpui-base';
import { spaces, agents, shared, setShared, theme, hc } from 'herdr';
import { makeComment, forSource, forLine, sendAndRemove, isOutdated, lineLabel, isWaiting } from './comment-model.js';
import { icon } from './ui.js';

const KEY = 'tabbed-changes.comments.v1';
const allNotes = () => shared(KEY) ?? [];
export const commentsFor = source => forSource(allNotes(), source);
export const lineComments = context => forLine(allNotes(), context);
export const idleCommentAgents = space => agents().filter(a => a.space === space && isWaiting(a));
export const removeSavedComment = id => setShared(KEY, allNotes().filter(note => note.id !== id));
export const sendSavedComment = (note, target, space) =>
  sendAndRemove({ note, target, space, agents: agents(), send: args => hc(args), read: allNotes, write: next => setShared(KEY, next) });
// The virtual row reserves the same space before and after saving.
export const INLINE_COMMENT_HEIGHT = 220;
export const commentButton = (id, text, t, action, { active = false, primary = false, enabled = true } = {}) =>
  div().id(id).flex_none().h(26).px(9).flex().items_center().rounded(5).text_size(11).font_semibold()
    .bg(primary && enabled ? t.accent : active && enabled ? t.accent + '24' : t.surface)
    .border(1).border_color((primary || active) && enabled ? t.accent : t.border)
    .text_color(enabled ? (primary ? t.accent_foreground : active ? t.accent : t.foreground) : t.muted)
    .when(enabled, e => e.cursor_pointer().hover(s => primary ? s.opacity(0.88) : s.bg(t.hover))
      .on_mouse_down('left', (_e, cx) => cx.stop_propagation())
      .on_click((_e, cx) => { cx.stop_propagation(); action(cx); }))
    .child(text);

export const commentBadge = t => div().size(30).flex_none().flex().items_center().justify_center()
  .rounded(7).bg(t.accent + '24').child(icon('comment', 16).text_color(t.accent));

export const savedCommentCard = t => v_flex().w_full().flex_none().min_w(0).px(10).py(7).gap(6)
  .rounded(6).bg(t.raised).border(1).border_color(t.border);

export function commentAgentPicker(t, { id, agents, target, enabled, select }) {
  return div().id(id).flex_1().min_w(0).h(28).overflow_x_scrollbar()
    .child(h_flex().h_full().gap(5).items_center()
      .child(div().flex_none().text_size(11).text_color(t.muted).child(agents.length ? 'Send to' : 'No idle agent available'))
      .children(agents.map(agent => commentButton(`${id}-${agent.address}`,
        `${target === agent.address ? '✓ ' : ''}${agent.program?.name ?? agent.app ?? 'Agent'} · ${agent.address}`, t,
        cx => select(agent.address, cx), { active: target === agent.address, enabled }))));
}

export class InlineComments extends View {
  init(p, cx) {
    this.context=p?.context ?? null; this.space=p?.space ?? spaces().find(s=>s.active)?.id;
    this.references=p?.references ?? [];
    this.drafts = {};
    this.target=null; this.busy=false; this.error=null; this.note=null;
    this.composing = !lineComments(this.context).length;
    this.input=TextareaState.new({placeholder:'Write your review comment…',rows:3});
    this.input.on('change',(_e,cx)=>{this.drafts[this.draftKey()]=this.input.value();cx.notify();});
  }
  draftKey() { const c=this.context; return JSON.stringify(c?[c.source,c.path,c.line,c.endLine??c.line,c.side,c.base??null,c.revision??null]:null); }
  update(p) {
    const previousKey = this.draftKey();
    this.drafts[previousKey] = this.input.value();
    this.context=p?.context ?? null; this.space=p?.space ?? this.space;
    this.references=p?.references ?? this.references;
    if (previousKey !== this.draftKey() || p?.focus) {
      this.error = null;
      this.note = null;
      this.composing = Boolean(p?.compose) || !lineComments(this.context).length;
      this.input.set_value(this.drafts[this.draftKey()] ?? '');
    }
    if (p?.focus && this.composing) this.input.focus();
  }
  save(cx) {
    if(this.busy)return;
    try {
      const note=makeComment(this.context,this.input.value(),`${Date.now()}-${Math.random().toString(36).slice(2)}`);
      setShared(KEY, [...allNotes(), note]);
      this.drafts[this.draftKey()] = '';
      this.input.set_value('');
      this.error = null;
      this.note = 'Comment saved.';
      this.composing = false;
    } catch(e) { this.error=String(e.message ?? e); }
    cx.notify();
  }
  send(note,cx) {
    if(this.busy||note.sentAt)return;
    const target=this.target, key=this.draftKey();
    this.busy=true; this.error=null; this.note=null; cx.notify();
    cx.spawn(async cx=>{
      try {
        await sendSavedComment(note, target, this.space);
        if (key === this.draftKey()) this.note='Comment and code sent to the agent.';
      } catch(e) { if (key === this.draftKey()) this.error=String(e.message ?? e); }
      finally { this.busy=false; cx.notify(); }
    });
  }
  setComposer(composing, cx) {
    this.composing = composing;
    this.error = this.note = null;
    if (composing) this.input.focus();
    cx.notify();
  }
  composer(t) {
    return v_flex().flex_1().min_h(0).gap(6)
      .child(div().h(66).flex_none().px(9).py(5).bg(t.background).border(1).border_color(t.input).rounded(6)
        .child(Textarea.new(this.input).w_full().text_size(13)))
      .child(h_flex().justify_end()
        .child(commentButton('line-comment-save', 'Save comment', t, cx => this.save(cx),
          { primary: true, enabled: Boolean(this.input.value().trim()) && !this.busy })));
  }
  saved(t, notes) {
    const idle = idleCommentAgents(this.space);
    const canSend = !this.busy && idle.some(a => a.address === this.target);
    return v_flex().flex_1().min_h(0).gap(6)
      .child(h_flex().h(28).flex_none().gap(10).items_center()
        .child(div().flex_none().text_size(11).font_semibold().text_color(t.foreground).child(`Saved comments (${notes.length})`))
        .when(notes.length > 0, e => e.child(commentAgentPicker(t, {
          id: 'line-agents', agents: idle, target: this.target, enabled: !this.busy,
          select: (address, cx) => { this.target = address; cx.notify(); },
        }))))
      .when(!notes.length, e => e.child(div().flex_1().text_color(t.dim).child('No saved comments on this line.')))
      .when(notes.length > 0, e => e.child(v_flex().id('line-thread').flex_1().min_h(0).gap(6).overflow_y_scrollbar()
        .children(notes.map(note => this.savedNote(t, note, canSend)))));
  }
  savedNote(t, note, canSend) {
    return savedCommentCard(t)
      .when(isOutdated(note, this.references), e => e.child(div().text_size(10).text_color(t.ansi3).child('Outdated · code changed since this comment')))
      .child(div().w_full().min_w(0).text_size(13).whitespace_normal().child(note.text))
      .child(h_flex().gap(6).items_center().justify_end()
        .child(commentButton(`line-delete-${note.id}`, 'Delete', t, cx => {
          removeSavedComment(note.id);
          this.note = 'Comment deleted.';
          this.error = null;
          cx.notify();
        }, { enabled: !this.busy }))
        .child(note.sentAt ? div().text_size(11).text_color(t.ansi2).child(`Sent to ${note.sentTo}`) :
          commentButton(`line-send-${note.id}`, this.busy ? 'Sending…' : 'Send to agent', t,
            cx => this.send(note, cx), { primary: true, enabled: canSend })));
  }
  render() {
    const t = theme(), context = this.context, notes = lineComments(context);
    const label = context ? `Line ${lineLabel(context)} · ${context.side === 'old' ? 'Original' : 'Current'} code` : 'Review comment';
    const hint = this.composing ? 'Saved locally · Esc to close' : 'Esc to close';
    return div().w_full().max_w(600).h(INLINE_COMMENT_HEIGHT).flex_none().p(6)
      .child(v_flex().size_full().min_h(0).px(11).py(8).gap(7).rounded(8)
        .bg(t.popover).border(1).border_color(t.border).text_color(t.foreground).text_size(12)
        .on_mouse_down('left', (_e, cx) => cx.stop_propagation())
        .child(h_flex().h(38).flex_none().gap(8).items_center()
          .child(commentBadge(t))
          .child(v_flex().flex_1().min_w(0)
            .child(div().truncate().text_size(13).font_semibold().child(this.composing ? 'New review comment' : 'Review thread'))
            .child(div().truncate().text_size(11).text_color(t.muted).child(label)))
          .when(!this.composing || notes.length > 0, e => e.child(commentButton('line-comment-mode',
            this.composing ? `Saved (${notes.length})` : 'New comment', t, cx => this.setComposer(!this.composing, cx)))))
        .child(this.composing ? this.composer(t) : this.saved(t, notes))
        .child(h_flex().h(17).flex_none().gap(5).items_center().text_size(11)
          .text_color(this.error ? t.ansi1 : this.note ? t.ansi2 : t.muted)
          .when(Boolean(this.note), e => e.child(icon('check', 12)))
          .child(div().flex_1().min_w(0).truncate().child(this.error || this.note || hint))));
  }
}
