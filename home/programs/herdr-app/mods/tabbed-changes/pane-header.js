import { div, image, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { home, panes, props, run, theme } from "herdr";
import { MOD } from "./tabs.js";
import { icon } from "./ui.js";

export class ReviewPaneHeader {
  init() {
    this.hovered = false;
  }

  render() {
    const pane = panes().find(pane => pane.pane === props()?.pane);
    if (!pane) return div();
    const t = theme();
    const review = pane.mod === MOD;
    const program = pane.program;
    const name = review ? "Code Review" :
      ((program?.agent || program?.shell) && program.name) || pane.title || program?.name || "Shell";
    const root = home(), cwd = pane.cwd ?? "";
    const folder = cwd === root || cwd.startsWith(root + "/") ? "~" + cwd.slice(root.length) : cwd;
    const button = (asset, title, command, args) => div().id(`pane-${asset}`).p(3).rounded(4)
      .text_color(t.dim).hover(style => style.bg(t.hover).text_color(t.foreground)).tooltip(title)
      .on_click((_event, cx) => { cx.stop_propagation(); run(command, { pane: pane.pane, ...args }); })
      .child(svg(`mods/pane/${asset}.svg`).size(14));

    return h_flex().id(`review-pane-head-${pane.pane}`).size_full().px(10).gap(8).items_center()
      .bg(t.background).border_b(1).border_color(t.border).text_size(12)
      .on_click(() => run("pane.focus", { pane: pane.pane }))
      .on_hover((hovered, cx) => { this.hovered = hovered; cx.notify(); })
      .when(review, e => e.child(icon("layers", 14).text_color(t.accent)))
      .when(!review && program?.icon, e => e.child(program.tint
        ? svg(program.icon).size(14).flex_none().text_color(t.dim)
        : image(program.icon).size(14).flex_none()))
      .child(div().flex_none().max_w(260).truncate().font_medium().text_color(t.foreground).child(name))
      .child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(folder))
      .when(pane.status === "working", e => e.child(svg("mods/workspace-chrome/spinner.svg").size(12).flex_none().text_color(t.working).spin(900)))
      .when(pane.status === "blocked", e => e.child(div().text_color(t.blocked).text_size(11).child("Needs you")))
      .when(pane.status === "done", e => e.child(div().size(7).flex_none().rounded(4).bg(t.done)))
      .when(this.hovered, e => e
        .child(button("split-right", "Split right", "pane.split", { direction: "right" }))
        .child(button("split-down", "Split down", "pane.split", { direction: "down" }))
        .child(button(pane.zoomed ? "unzoom" : "zoom", pane.zoomed ? "Restore pane" : "Zoom pane", "pane.zoom"))
        .child(button("close", "Close pane", "pane.close")));
  }
}
