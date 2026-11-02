// Local change: what the diff tab (diff.js) and the file tab (file.js) share. Line comments go to
// the `review` mod, which keeps them per space in shared("review.comments") and opens the dialogs.
import { div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { shared, openOverlay } from "herdr";
import { icon } from "./menu.js";

export const commentsOf = (space) => (shared("review.comments") ?? {})[space] ?? [];
export const openReview = (space) => openOverlay({ mod: "review", kind: "dialog", width: 720, height: 600, props: { mode: "send", space } });
export const openComment = (space, comment) => openOverlay({ mod: "review", kind: "dialog", width: 620, height: 440, props: { mode: "add", space, comment } });

// A click picks a line; another widens the pick to it; one inside the pick clears it. `at` is a
// row index (diff) or a line number (file). A click in another group (file) starts a new pick.
export function pickRange(sel, at, sameGroup = true) {
  if (!sel || !sameGroup) return { from: at, to: at };
  if (at >= sel.from && at <= sel.to) return null;
  return { from: Math.min(sel.from, at), to: Math.max(sel.to, at) };
}

export function textButton(id, label, t, onClick, opts = {}) {
  return h_flex().id(id).h(24).px(9).flex_none().items_center().rounded(6).text_size(12).cursor_pointer()
    .bg(opts.on ? t.selected : opts.solid ? t.solid : t.raised).border_1().border_color(opts.on ? t.accent : opts.solid ? t.solid : t.border)
    .text_color(opts.solid ? t.solid_foreground : opts.on ? t.foreground : t.muted).hover((s) => s.opacity(0.85))
    .on_click((_e, cx) => onClick(cx)).child(label);
}

export function iconButton(id, name, tip, t, onClick, opts = {}) {
  return h_flex().id(id).size(24).flex_none().items_center().justify_center().rounded(6).cursor_pointer().tooltip(tip)
    .text_color(opts.on ? t.accent : t.dim).when(Boolean(opts.on), (e) => e.bg(t.selected))
    .hover((s) => s.bg(t.hover).text_color(opts.on ? t.accent : t.foreground))
    .on_click((_e, cx) => onClick(cx)).child(svg(icon(name)).size(opts.size ?? 13));
}

// Copies `path` (relative to the repository or the folder it was picked in); ✓ for 1.5 s. `view`
// holds the `copied` state.
export function copyButton(id, view, path, t) {
  const done = view.copied === path;
  return h_flex().id(id).size(22).flex_none().items_center().justify_center().rounded(5).cursor_pointer()
    .tooltip(done ? "Copied" : "Copy relative path").text_color(done ? t.ansi2 : t.muted)
    .hover((s) => s.bg(t.hover).text_color(done ? t.ansi2 : t.foreground))
    .on_click((_e, cx) => {
      cx.write_to_clipboard(path);
      view.copied = path; cx.notify();
      cx.timer.after(1500, (cx) => { if (view.copied === path) { view.copied = null; cx.notify(); } });
    })
    .child(svg(icon(done ? "check" : "copy")).size(13));
}

export const reviewButton = (id, space, t) => {
  const n = commentsOf(space).length;
  return n ? textButton(id, `Review (${n})`, t, () => openReview(space), { solid: true }) : null;
};

// The bar over the lines: what's picked, Clear and Comment…, or how to pick.
export function selectionBar(prefix, label, t, onClear, onComment) {
  return h_flex().h(32).flex_none().px(12).gap(8).items_center().border_b(1).border_color(t.border).text_size(12)
    .when(Boolean(label), (e) => e
      .child(div().font_semibold().child(label))
      .child(div().flex_1().min_w(0).truncate().text_color(t.dim).child("Click another line to widen · click the pick to clear"))
      .child(textButton(`${prefix}-clear`, "Clear", t, onClear))
      .child(textButton(`${prefix}-comment`, "Comment…", t, onComment, { solid: true })))
    .when(!label, (e) => e.child(div().text_color(t.dim).child("Click a line to comment on it; click another to make it a range")));
}
