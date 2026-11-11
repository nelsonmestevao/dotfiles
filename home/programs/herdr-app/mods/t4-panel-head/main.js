// The top of t4's right panel: Files and Diff as
// tabs (they pick the child of the layout's "panel-body" stack), and close
// (hides the "panel" column). Add a surface: a block in that stack and a
// tab here.

import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { run, layout } from "herdr";

const SURFACES = [
  ["files", "Files", "folder-tree"],
  ["diff", "Diff", "file-diff"],
];
const C = { text: "#ececee", muted: "#a1a1aa", dim: "#71717a", chip: "#18181b", line: "#1f1f23" };
const I = (name) => `mods/t4-threads/${name}.svg`;

function find(node, id) {
  if (!node) return null;
  if (node.id === id) return node;
  for (const c of node.children ?? []) {
    const f = find(c, id);
    if (f) return f;
  }
  return null;
}

const own = (el) => el.on_mouse_down("left", (_e, cx) => cx.stop_propagation());

export default class PanelHead extends View {
  render() {
    const active = find(layout(), "panel-body")?.active ?? SURFACES[0][0];
    return h_flex()
      .size_full()
      .px(10)
      .gap(4)
      .items_center()
      .border_b(1)
      .border_color(C.line)
      .children(
        SURFACES.map(([id, label, icon]) =>
          own(
            h_flex()
              .id(`ph-${id}`)
              .h(28)
              .px(10)
              .gap(6)
              .items_center()
              .rounded(8)
              .text_size(13)
              .text_color(id === active ? C.text : C.muted)
              .when(id === active, (el) => el.bg(C.chip))
              .cursor_pointer()
              .hover((s) => s.text_color(C.text))
              .on_click(() => run("layout.select", { stack: "panel-body", child: id }))
              .child(svg(I(icon)).size(14))
              .child(label),
          ),
        ),
      )
      .child(div().flex_1())
      .child(
        own(
          div()
            .id("ph-close")
            .p(6)
            .rounded(8)
            .text_color(C.dim)
            .cursor_pointer()
            .hover((s) => s.bg(C.chip).text_color(C.text))
            .on_click(() => run("layout.toggle", { id: "panel" }))
            .child(svg(I("x")).size(14)),
        ),
      );
  }
}
