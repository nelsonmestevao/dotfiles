// The composer under the thread, as a chat-first agent app draws it: a
// rounded box to write to the agent, and a row with the agent, the access
// mode, attach and a round send button. Enter sends the text to the focused
// pane's agent (hc send) and clears the box.

import { View, div, svg, image } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { agents, focused, hc } from "herdr";

const C = { bg: "#09090b", card: "#141417", line: "#26262b", text: "#ececee", dim: "#71717a", muted: "#a1a1aa", accent: "#60a5fa" };
const I = (n) => `mods/t4-threads/${n}.svg`;

export default class Composer extends View {
  init(_p, cx) {
    this.handle = cx.focus_handle();
    this.text = "";
  }

  agent() {
    const f = focused();
    return agents().find((a) => a.address === f?.terminal) ?? agents().find((a) => a.focused) ?? null;
  }

  send(cx) {
    const a = this.agent(), text = this.text.trim();
    if (!a || !text) return;
    this.text = "";
    cx.notify();
    hc(["send", a.address, text]);
  }

  key(e, cx) {
    if (e.key === "enter") return this.send(cx);
    if (e.key === "backspace") this.text = this.text.slice(0, -1);
    else if (e.key_char && !e.modifiers?.control) this.text += e.key_char;
    cx.notify();
  }

  render(cx) {
    const a = this.agent();
    const name = a?.program?.name ?? "Agent";
    const pill = (child) => h_flex().h(28).px(10).gap(6).items_center().rounded(14).border_1().border_color(C.line).text_size(12.5).text_color(C.muted).child(child);
    return div().size_full().bg(C.bg).flex().justify_center().px(24).pt(4).pb(14)
      .child(v_flex().id("composer").track_focus(this.handle).on_key_down((e, cx) => this.key(e, cx))
        .on_click((_e, cx) => { this.handle.focus(); cx.notify(); })
        .w_full().max_w(980).h_full().rounded(18).bg(C.card).border_1().border_color(C.line).px(18).pt(14).pb(10).cursor_text()
        .child(div().flex_1().text_size(15).text_color(this.text ? C.text : C.dim)
          .child(this.text || `Ask ${name} for changes, send follow-ups, or attach images`))
        .child(h_flex().gap(8).items_center()
          .child(pill(h_flex().gap(6).items_center()
            .when(Boolean(a?.program?.icon), (el) => el.child(image(a.program.icon).w(14).h(14)))
            .child(div().text_color(C.text).child(name)).child(div().child("⌄"))))
          .child(pill(div().child("Full access  ⌄")))
          .child(pill(div().child("Plan")))
          .child(div().flex_1())
          .child(div().size(28).flex().items_center().justify_center().text_color(C.muted).child(svg("mods/workspace-chrome/plus.svg").size(16)))
          .child(div().id("send").size(32).rounded(16).bg(this.text ? C.accent : "#2a2a30").flex().items_center().justify_center()
            .text_color(this.text ? "#09090b" : C.muted).text_size(16).font_weight(700).cursor_pointer()
            .on_click((_e, cx) => this.send(cx)).child("↑"))));
  }
}
