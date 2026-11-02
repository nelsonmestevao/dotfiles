// The dropdowns and right-click menus, opened as a popup with props
// { role: "menu", owner, items }. Choosing posts { owner, id } to the shared
// "git-changes.pick", which the panel that opened it acts on: the git work
// runs there, not in this popup (a closed popup's tasks are cancelled).
// A danger item asks once more in place before it's posted.
// The look (popover, 28px rows, arrow keys) follows herdr-git-graph's menu.js
// (https://github.com/rabeeh-ta/herdr-git-graph, MIT).
import { div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { props, closeOverlay, notify, setShared, theme } from "herdr";

export const icon = (name) => `mods/git-changes/icons/${name}.svg`;
export const menuHeight = (items) => items.reduce((h, it) => h + (it.separator ? 9 : 28), 10);

export class Menu {
  init(cx) {
    this.items = props().items ?? [];
    this.at = -1; this.confirming = -1;
    this.handle = cx.focus_handle();
    this.handle.focus();
  }

  choose(i, cx) {
    const it = this.items[i], { overlay, owner } = props();
    if (!it || it.separator || it.disabled) return;
    if (it.copy !== undefined) {
      cx.write_to_clipboard(it.copy);
      notify({ title: "Copied", body: it.copy, level: "success", timeout: 2000 });
    } else if (it.danger && this.confirming !== i) {
      this.confirming = i; this.at = i; cx.notify(); return;
    } else setShared("git-changes.pick", { owner, id: it.id, at: Date.now() });
    closeOverlay(overlay);
  }

  move(step) {
    const n = this.items.length;
    for (let k = 1; k <= n; k++) {
      const i = (this.at + step * k + n * 2) % n;
      if (!this.items[i].separator && !this.items[i].disabled) { this.at = i; return; }
    }
  }

  render() {
    const t = theme();
    return v_flex().id("git-changes-menu").track_focus(this.handle).w_full().min_h(0).p(5).bg(t.popover).text_size(12.5)
      .on_key_down((e, cx) => {
        if (e.key === "down") this.move(1);
        else if (e.key === "up") this.move(-1);
        else if (e.key === "enter" || e.key === "space") this.choose(this.at, cx);
        else if (e.key === "escape") closeOverlay(props().overlay);
        else return;
        cx.stop_propagation();
        cx.notify();
      })
      .children(this.items.map((it, i) => {
        if (it.separator) return div().mx(7).my(4).h(1).flex_none().bg(t.border);
        const confirm = this.confirming === i, color = it.disabled ? t.dim : it.danger ? t.ansi1 : t.foreground;
        return h_flex().id(`gcm-${i}`).h(28).flex_none().px(8).gap(9).rounded(6).items_center().text_color(color)
          .when(!it.disabled, (el) => el.cursor_pointer().hover((s) => s.bg(t.hover)))
          .when(i === this.at || confirm, (el) => el.bg(confirm ? t.ansi1 + "22" : t.selected))
          .on_click((_e, cx) => this.choose(i, cx))
          .child(it.check !== undefined
            ? div().w(14).flex_none().text_color(t.accent).child(it.check ? "✓" : "")
            : svg(icon(it.icon ?? "commit")).size(14).flex_none().text_color(it.disabled ? t.dim : it.danger ? t.ansi1 : t.muted))
          .child(div().flex_1().min_w(0).truncate().child(confirm ? `Click again: ${it.label}` : it.label))
          .when(Boolean(it.hint), (el) => el.child(div().flex_none().text_size(11).text_color(t.dim).child(it.hint)));
      }));
  }
}
