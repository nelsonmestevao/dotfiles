// An action's dialog, opened with props { role: "dialog", action, ctx }: names
// to type, options to tick, a mode to pick. Styled like Herdr's prompt and
// confirm dialogs. Git's error stays in the dialog so the person can fix it.
import { div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { props, closeOverlay, theme } from "herdr";
import { dialogFor, initialValues, validate } from "./git.js";
import { perform } from "./act.js";
import { icon } from "./menu.js";

export class Dialog {
  init(cx) {
    const { action, ctx } = props();
    this.spec = dialogFor(action, ctx);
    this.values = initialValues(action, ctx);
    this.focusedInput = 0;
    this.inputs = (this.spec.inputs ?? []).map((field, i) => {
      const state = InputState.new({ value: field.value ?? "" });
      state.on("change", (_e, cx) => { this.values[field.id] = state.value(); this.error = null; cx.notify(); });
      state.on("submit", (_e, cx) => this.confirm(cx));
      state.on("focus", (_e, cx) => { this.focusedInput = i; cx.notify(); });
      state.on("blur", (_e, cx) => { if (this.focusedInput === i) this.focusedInput = -1; cx.notify(); });
      return { field, state };
    });
    this.handle = cx.focus_handle();
    const first = this.inputs[0]?.state;
    if (first) {
      if (this.inputs[0].field.value) first.set_selected_range({ start: 0, end: this.inputs[0].field.value.length });
      first.focus();
      cx.timer.after(600, () => first.focus());
    } else this.handle.focus();
  }

  confirm(cx) {
    if (this.busy) return;
    const { action, ctx, overlay } = props();
    const problem = validate(action, this.values, ctx);
    if (problem) { this.error = problem; cx.notify(); return; }
    this.busy = true; this.error = null;
    cx.spawn(async (cx) => {
      const result = await perform(action, this.values, ctx, { toast: false });
      this.busy = false;
      if (result.ok) closeOverlay(overlay);
      else { this.error = result.message; cx.notify(); }
    });
    cx.notify();
  }

  danger() {
    const choice = this.spec.choice;
    return Boolean(this.spec.danger || choice?.options.find((o) => o.value === this.values[choice.id])?.danger);
  }

  render() {
    const t = theme(), s = this.spec, danger = this.danger();
    const label = (text) => div().pt(14).pb(7).text_size(11.5).text_color(t.dim).child(text);
    const button = (id, text, primary, action) => h_flex().id(id).h(32).px(14).items_center().rounded(8).border_1()
      .border_color(primary ? (danger ? t.ansi1 : t.solid) : t.input).bg(primary ? (danger ? t.ansi1 : t.solid) : t.raised)
      .text_color(primary ? (danger ? t.background : t.solid_foreground) : t.foreground).text_size(12.5).font_medium().cursor_pointer()
      .hover((st) => st.opacity(0.88)).on_click(action).child(text);
    return v_flex().id("git-graph-dialog").track_focus(this.handle).size_full().min_h(0).p(18).bg(t.popover).text_color(t.foreground).text_size(12.8)
      .on_key_down((e, cx) => {
        if (e.key === "escape") closeOverlay(props().overlay);
        else if (e.key === "enter" && this.focusedInput < 0) this.confirm(cx);
        else return;
        cx.stop_propagation();
      })
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().child(s.title)).child(div().text_size(11).text_color(t.dim).child("Esc")))
      .when(Boolean(s.detail), (el) => el.child(div().pt(8).text_color(t.muted).child(s.detail)))
      .children(this.inputs.map(({ field, state }, i) => v_flex()
        .child(label(field.label))
        .child(Input.new(state).h(36).px(10).rounded(9).border_1().border_color(this.focusedInput === i ? t.accent : t.input).bg(t.background).text_size(12.8).text_color(t.foreground))))
      .when(Boolean(s.choice), (el) => el.child(label(s.choice.label)).children(s.choice.options.map((o) => {
        const on = this.values[s.choice.id] === o.value;
        return h_flex().id(`gd-choice-${o.value}`).h(38).mb(4).px(10).gap(10).items_center().rounded(8).border_1().cursor_pointer()
          .border_color(on ? (o.danger ? t.ansi1 : t.accent) : t.border).when(on, (e) => e.bg(t.selected)).hover((st) => st.bg(t.hover))
          .on_click((_e, cx) => { this.values[s.choice.id] = o.value; this.error = null; cx.notify(); })
          .child(div().size(14).flex_none().rounded(7).border_1().border_color(on ? (o.danger ? t.ansi1 : t.accent) : t.input).flex().items_center().justify_center()
            .when(on, (e) => e.child(div().size(6).rounded(3).bg(o.danger ? t.ansi1 : t.accent))))
          .child(div().font_medium().child(o.label))
          .when(Boolean(o.detail), (e) => e.child(div().text_size(11.5).text_color(o.danger ? t.ansi1 : t.dim).child(o.detail)));
      })))
      .children((s.checks ?? []).map((c) => {
        const on = Boolean(this.values[c.id]);
        return h_flex().id(`gd-check-${c.id}`).pt(12).gap(9).items_center().cursor_pointer()
          .on_click((_e, cx) => { this.values[c.id] = !on; cx.notify(); })
          .child(div().size(15).flex_none().rounded(4).border_1().border_color(on ? t.accent : t.input).when(on, (e) => e.bg(t.accent)).flex().items_center().justify_center()
            .when(on, (e) => e.child(svg(icon("check")).size(11).text_color(t.accent_foreground))))
          .child(div().text_color(t.foreground).child(c.label));
      }))
      .when(Boolean(this.error), (el) => el.child(div().pt(12).text_size(12).text_color(t.ansi1).child(this.error)))
      .child(div().flex_1())
      .child(h_flex().pt(16).gap(8).justify_end()
        .child(button("gd-cancel", "Cancel", false, () => closeOverlay(props().overlay)))
        .child(button("gd-ok", this.busy ? "Working…" : s.confirm, true, (_e, cx) => this.confirm(cx))));
  }
}
