import { div, svg, image } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { tokenize, extOf } from "./highlight.js";
import { Memo } from "./read-cache.js";
import { splitTokens, wrapTokens } from "./review-model.js";
import { iconFor } from "./fileicons.js";

const syntax=new Memo(128,4096);

export const DIR = "mods/tabbed-changes/icons";
export const icon = (name, size = 14) => svg(`${DIR}/${name}.svg`).size(size).flex_none();

// A square icon button. Presses never reach the row under it.
export function iconButton(id, name, t, onClick, { color, active, size = 22, title } = {}) {
  return div().id(id).w(size).h(size).flex_none().flex().items_center().justify_center().rounded(5).cursor_pointer()
    .text_color(active ? t.accent : color ?? t.muted)
    .when(active, (e) => e.bg(t.selected))
    .hover((s) => s.bg(t.raised).text_color(active ? t.accent : t.foreground))
    .when(Boolean(title), (e) => e.tooltip(title))
    .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
    .on_click((_e, cx) => { cx.stop_propagation(); onClick(cx); })
    .child(icon(name));
}

// An icon with a label, for a tab's header bar.
export function toolButton(id, name, label, t, onClick, { active } = {}) {
  return h_flex().id(id).h(24).px(8).gap(5).flex_none().items_center().rounded(6).cursor_pointer().text_size(12)
    .text_color(active ? t.accent : t.muted).when(active, (e) => e.bg(t.selected))
    .hover((s) => s.bg(t.raised).text_color(active ? t.accent : t.foreground))
    .on_click((_e, cx) => onClick(cx))
    .child(icon(name, 13)).child(div().child(label));
}

// One line of code with syntax colours.
export const CODE_ROW = 20;
export const COMMENT_GUTTER = 22;

// A virtual row uses native hover styling to reveal this glyph. Its list
// handles the click since deferred rows cannot register event listeners.
// The row and its gutter need IDs so GPUI retains their hover state.
export function commentGutter(t, count, stale, selected) {
  const color = stale ? t.ansi3 : t.accent;
  return div().id("comment-gutter").w(COMMENT_GUTTER).h(CODE_ROW).flex_none().flex().items_center().justify_center()
    .rounded(4).cursor_pointer().hover(style => style.bg(t.selected).text_color(t.accent))
    .when(count > 0 || selected, element => element.text_color(color))
    .when(count > 0, element => element.bg(color + "38"))
    .child(count ? h_flex().items_center()
      .child(icon("comment", count === 1 ? 16 : count > 9 ? 12 : 15))
      .when(count > 1, e => e.child(div().text_size(8).child(count > 9 ? "9+" : String(count)))) : "+");
}

export function inCommentGutter(x, start) {
  return x >= start && x < start + COMMENT_GUTTER;
}

export function codeLine(text, path, t, spans=[], tone=t.accent, breaks=null) {
  const ext = extOf(path ?? ""), color = { keyword: t.ansi5, string: t.ansi2, comment: t.dim, function: t.ansi4, type: t.ansi3, number: t.ansi6, constant: t.ansi6, punct: t.muted };
  const tokens = splitTokens(syntax.get(`${ext}\0${text}`, () => tokenize(text, ext)), spans);
  return v_flex().flex_1().min_w(0).overflow_hidden().text_color(t.foreground).children(wrapTokens(tokens, breaks).map(row =>
    h_flex().w_full().h(CODE_ROW).flex_none().whitespace_nowrap()
      .children(row.map((tok) => div().flex_none().child(tok.text.replace(/\t/g, "    ")).when(Boolean(tok.kind), (e) => e.text_color(color[tok.kind]))
      .when(tok.kind === "keyword", (e) => e.font_semibold()).when(Boolean(tok.changed),e=>e.bg(tone+"77"))))));
}

// The file-type icon for a path (Material Icon Theme subset), in colour.
export const fileIcon = (path, size = 16) => image(`mods/tabbed-changes/icons/files/${iconFor(path)}.svg`).size(size).flex_none();
