import { View, div, image, svg } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { agents, spaces, panes, props, run, setAgentOrder } from "herdr";

const wood = "#ab7748", ink = "#414b34";
const icon = (p) => p?.icon ? (p.tint ? svg(p.icon).text_color(p.color ?? ink) : image(p.icon)).size(17) : div().size(17);

export default class Pasture extends View {
  init(_p, cx) {
    this.step = 0;
    if (!props()?.role) cx.timer.every(4200, (cx) => { this.step++; cx.notify(); });
  }
  sheep(a, i) {
    const done = a.status === "done", blocked = a.status === "blocked", working = a.status === "working";
    const x = 270 + (i % 5) * 225 + (working ? Math.sin(this.step * .8 + i) * 28 : 0);
    const y = i < 5 ? 90 : 195;
    const body = div().relative().w(136).h(102)
      .child(image(`mods/pasture/${done ? "sleep" : !working && !blocked ? "graze" : "sheep"}.svg`).w(130).h(100))
      .child(div().absolute().left(done ? 79 : 87).top(done ? 76 : 67).size(24).rounded(6).bg("#f4cc68").border(2).border_color("#b68535").flex().items_center().justify_center().child(icon(a.program)));
    if (blocked) body.id(`jump-${a.address}`).loop("top", { from: 0, to: -15, period: 850 });
    if (!working && !done && !blocked) body.id(`graze-${a.address}`).loop("top", { from: 0, to: 4, period: 2700 });
    return v_flex().id(`sheep-${a.address}`).absolute().left(x).top(y).w(168).items_center().cursor_pointer()
      .transition("left", { duration: 4200, easing: "ease-in-out" })
      .on_click(() => run("agent.focus", { terminal: a.address }))
      .when(blocked, (el) => el.child(div().absolute().top(-35).left(-5).px(12).py(5).rounded(12).bg("#fff8e1").border(2).border_color("#d47b3e").text_size(13).font_weight(700).text_color("#a44d25").child(`! ${a.program.name}`)))
      .when(done, (el) => el.child(div().absolute().top(4).right(4).text_size(18).font_weight(700).text_color("#436b5c").child("zzz")))
      .child(body)
      .child(div().text_size(12).font_weight(600).text_color(ink).child(a.tab_name));
  }
  render() {
    const p = props() ?? {};
    if (p.role === "pane") {
      const pane = panes().find((x) => x.pane === p.pane);
      return h_flex().size_full().px(12).gap(9).items_center().bg("#ceab78").text_color("#493724").text_size(12).font_weight(600)
        .child(icon(pane?.program)).child(div().child(pane?.program.name ?? "Terminal"))
        .child(div().flex_1()).child(div().child(pane?.status === "blocked" ? "needs you" : pane?.status ?? ""));
    }
    if (p.role === "rail") {
      const s = spaces().find((s) => s.active), tab = s?.tabs.find((t) => t.active);
      return h_flex().size_full().bg(wood).px(20).items_center().justify_between().text_color("#fff4d9").text_size(13).font_weight(600)
        .child(div().child(`${s?.name ?? ""}  /  ${tab?.name ?? ""}`)).child(div().text_size(11).child("THE WORKSHED"));
    }
    const list = agents();
    setAgentOrder(list.map((a) => a.address));
    const active = spaces().find((s) => s.active);
    return div().relative().size_full().overflow_hidden()
      .child(image("mods/pasture/meadow.svg").absolute().size_full())
      .child(v_flex().absolute().left(28).top(23).gap(3).text_color(ink)
        .child(div().text_size(30).font_weight(800).child("The pasture"))
        .child(div().text_size(13).child(`${list.length} sheep, one happy herd.`)))
      .child(div().absolute().left(75).top(160).w(14).h(150).bg("#8d623d"))
      .child(v_flex().absolute().left(30).top(139).w(177).py(12).px(16).gap(3).rounded(6).bg("#d2a673").border(3).border_color("#9b6b40").text_color("#573c27")
        .child(div().text_size(11).font_weight(600).child("WELCOME TO"))
        .child(div().text_size(21).font_weight(800).child(active?.name ?? "your space")))
      .children(list.map((a, i) => this.sheep(a, i)))
      .child(h_flex().absolute().right(30).top(25).gap(18).text_size(12).text_color(ink)
        .children([["working", "wandering"], ["blocked", "need you"], ["done", "resting"]].map(([state, name]) => div().child(`${list.filter((a) => a.status === state).length} ${name}`))));
  }
}
