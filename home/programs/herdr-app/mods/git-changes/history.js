// Adapted from herdr-git-graph by Rabeeh T A (https://github.com/rabeeh-ta/herdr-git-graph), MIT:
// graphCell() (one stroked path per color, the cubic curve between lanes, the
// HEAD ring), the label look, the lane colors, the 24px whole-pixel rows and the
// paging at the end of the list follow mods/git-graph/graph.js. Lane squeezing,
// label folding and the remote toggle are this mod's. See LICENSES/MIT-herdr-git-graph.txt.
//
// The History tab as a commit graph, drawn like the git-graph mod: every
// commit on a lane, lines bending where branches fork and merge, branch, tag
// and remote labels, and the uncommitted changes as a dashed top row.
// Only the rows on screen are drawn (a virtual list); scrolling to the end
// reads the next page.
import { div, svg, PathBuilder } from "gpui-kit";
import { h_flex, Scrollbar, v_virtual_list } from "gpui-base";
import { settings } from "herdr";
import { layoutLanes } from "./lanes.js";
import * as G from "./git.js";
import { icon } from "./menu.js";

export const PAGE = 300;
const ROW = 24, LANE = 12, MIN_LANE = 6, PAD = 5, DATE = 44;
// The graph's share of the panel: lanes squeeze to fit it before any are cut off.
const GRAPH_SHARE = 0.26, GRAPH_MAX = 110, GRAPH_MIN = 28;
export const laneColors = (t) => [t.ansi4, t.ansi2, t.ansi5, t.ansi3, t.ansi6, t.ansi1, t.ansi12, t.ansi10, t.ansi13, t.ansi11, t.ansi14, t.ansi9];

export class History {
  constructor() {
    this.listId = `gc-history-${Math.random().toString(36).slice(2)}`;
    this.all = localStorage.getItem("history-all") !== "0";
    // Remote branches each take a lane: off, only the upstream shows.
    this.remotes = localStorage.getItem("history-remotes") === "1";
    this.limit = PAGE; this.clear();
  }

  clear() { this.base = []; this.commits = []; this.rows = []; this.lanes = 1; this.index = new Map(); this.labels = new Map(); this.hasMore = false; this.signature = null; }

  // One read of the log; `changes` adds the uncommitted row. Returns false when nothing moved.
  async read(git, { changes, head, upstream }) {
    const r = await git(G.historyArgs({ all: this.all, remotes: this.remotes, upstream, limit: this.limit + 1 }));
    if (r.code !== 0) { if (head) throw new Error(G.gitError(r)); this.clear(); return true; }
    const signature = `${this.all}\0${this.remotes}\0${upstream}\0${this.limit}\0${changes}\0${r.stdout}`;
    if (signature === this.signature) return false;
    const base = G.parseLog(r.stdout);
    this.hasMore = base.length > this.limit;
    this.base = base.slice(0, this.limit).map((c) => ({ ...c, area: "commit" }));
    this.commits = G.withUncommitted(this.base, changes, head);
    const { rows, width } = layoutLanes(this.commits);
    this.rows = rows; this.lanes = width; this.signature = signature;
    this.index = new Map(this.commits.map((c, i) => [c.hash, i]));
    const shown = (name) => this.remotes || name === upstream;
    this.labels = new Map(this.commits.map((c) => [c.hash, G.labelsOf(c, shown)]));
    return true;
  }

  setAll(all) { this.all = all; this.limit = PAGE; this.signature = null; localStorage.setItem("history-all", all ? "1" : "0"); }
  setRemotes(on) { this.remotes = on; this.limit = PAGE; this.signature = null; localStorage.setItem("history-remotes", on ? "1" : "0"); }
  more() { this.limit += PAGE; this.signature = null; }
  find(hash) { return this.commits[this.index.get(hash)]; }

  // Rows are a whole number of screen pixels (21.6 at zoom 0.9 leaves hairlines between them).
  zoom() { return settings().zoom ?? 1; }
  rowPx() { return Math.max(1, Math.round(ROW * this.zoom())); }
  rowH() { return this.rowPx() / this.zoom(); }
  // Lane spacing and the graph's width for a panel this wide: up to 12 px a lane, down
  // to 6 to fit the share; past that the outer lanes are cut off, as in Git Graph.
  geometry(panelWidth) {
    const max = Math.max(GRAPH_MIN, Math.min(GRAPH_MAX, Math.round(panelWidth * GRAPH_SHARE)));
    const lane = Math.max(MIN_LANE, Math.min(LANE, (max - PAD * 2) / Math.max(1, this.lanes)));
    return { lane, width: Math.min(Math.ceil(PAD * 2 + this.lanes * lane), max) };
  }

  graphCell(row, commit, colors, t, { width, lane: step }) {
    const x = (lane) => PAD + lane * step + step / 2, h = this.rowH(), stroke = step < 9 ? 1.25 : 1.5, d = step < 9 ? 6 : 8;
    // paint_path takes raw pixels while elements are zoomed: scale the lines to match the dots.
    const z = this.zoom(), px = (lane) => x(lane) * z, py = (v) => v * h * z, paths = new Map();
    // One stroked path per color: a row is a handful of paints, however many lanes cross it.
    for (const [a, ya, b, yb, c, dashed] of row.segments) {
      const color = dashed ? t.dim : colors[c % colors.length], key = `${color}${dashed ? "-" : ""}`;
      let p = paths.get(key)?.p ?? (dashed ? PathBuilder.stroke(stroke * z).dash_array([3 * z, 3 * z]) : PathBuilder.stroke(stroke * z));
      p = p.move_to(px(a), py(ya));
      if (a === b) p = p.line_to(px(b), py(yb));
      else { const mid = (py(ya) + py(yb)) / 2; p = p.cubic_bezier_to(px(b), py(yb), px(a), mid, px(b), mid); }
      paths.set(key, { p, color });
    }
    const color = commit.uncommitted ? t.dim : colors[row.lane % colors.length];
    const dot = div().absolute().left(x(row.lane) - d / 2).top(h / 2 - d / 2).size(d).rounded(d / 2);
    return div().relative().flex_none().w(width).h(h).overflow_hidden()
      .children([...paths.values()].map(({ p, color }) => window.paint_path(p.build(), color).absolute().top(0).left(0).size_full()))
      // HEAD is a ring, as in Git Graph; the uncommitted changes a gray one.
      .child(commit.head || commit.uncommitted ? dot.bg(t.background).border(d > 6 ? 2 : 1.5).border_color(color) : dot.bg(color));
  }

  label(l, color, t, mono, maxW) {
    const current = l.kind === "branch" && l.head;
    const edge = l.kind === "tag" ? t.ansi3 : l.kind === "head" ? t.accent : l.kind === "remote" ? t.muted : color;
    const fg = current || l.kind === "head" ? t.background : l.kind === "tag" ? t.ansi3 : l.kind === "remote" ? t.muted : t.foreground;
    const glyph = l.kind === "branch" ? (l.head ? "check" : "branch") : l.kind === "tag" ? "tag" : l.kind === "remote" ? "cloud" : null;
    return h_flex().flex_none().max_w(maxW).h(18).px(4).gap(3).items_center().rounded(5).border_1().border_color(edge).overflow_hidden()
      .when(current, (e) => e.bg(color)).when(l.kind === "head", (e) => e.bg(t.accent))
      .when(Boolean(glyph), (e) => e.child(svg(icon(glyph)).size(10).flex_none().text_color(fg)))
      .child(div().min_w(0).truncate().font_family(mono).text_size(11).when(current, (e) => e.font_semibold()).text_color(fg).child(l.text))
      .when(Boolean(l.synced), (e) => e.child(svg(icon("cloud")).size(10).flex_none().text_color(current ? t.background : t.muted)));
  }

  // Labels never take more than a third of the text: the first one shows, the rest count as +N.
  labelChips(commit, color, t, mono, textWidth) {
    const all = this.labels.get(commit.hash), maxW = Math.max(56, Math.min(150, Math.round(textWidth * 0.36)));
    if (!all.length) return [];
    const out = [this.label(all[0], color, t, mono, maxW)];
    if (all.length > 1) out.push(div().flex_none().px(4).h(18).flex().items_center().rounded(5).bg(t.raised).text_size(10.5).text_color(t.muted)
      .tooltip(all.slice(1).map((l) => l.text).join(", ")).child(`+${all.length - 1}`));
    return out;
  }

  row(i, t, colors, mono, geo, textWidth, selected) {
    const commit = this.commits[i], row = this.rows[i], color = colors[row.lane % colors.length];
    // Merge commits are muted, as Git Graph does.
    const fg = commit.uncommitted ? t.muted : commit.parents.length > 1 ? t.dim : t.foreground;
    return h_flex().id(`h-${commit.hash}`).w_full().h(this.rowH()).flex_none().pr(8).gap(4).items_center().overflow_hidden().cursor_pointer()
      .when(commit.head, (e) => e.bg(color + "14")).when(selected === commit.hash, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover))
      .child(this.graphCell(row, commit, colors, t, geo))
      .child(h_flex().flex_1().min_w(0).h_full().gap(4).items_center().overflow_hidden()
        .children(this.labelChips(commit, color, t, mono, textWidth))
        .child(div().flex_1().min_w(0).truncate().text_color(fg).when(commit.head, (e) => e.font_semibold()).child(commit.subject)))
      .child(div().w(DATE).flex_none().text_right().truncate().text_size(11).text_color(t.dim).child(commit.uncommitted ? "" : commit.when));
  }

  // The list. `onPick(commit, clicks)`, `onMenu(commit)` and `onMore()` are the panel's.
  view(t, { selected, panelWidth, loading, onPick, onMenu, onMore }) {
    const colors = laneColors(t), mono = settings().font_family ?? "JetBrains Mono", geo = this.geometry(panelWidth);
    const textWidth = panelWidth - geo.width - DATE - 20;
    const count = this.commits.length + (this.hasMore ? 1 : 0);
    return div().flex_1().min_h(0).relative().text_size(12.5)
      // A virtual list names the clicked row but not the click count: the press says it.
      .on_mouse_down("left", (e) => { this.clicks = e.click_count; })
      .child(v_virtual_list(this.listId, count, this.rowPx(), (i) => this.commits[i]?.hash ?? "more",
        (range, cx) => {
          if (range.end > this.commits.length && this.hasMore && !loading && this.asked !== this.limit) {
            this.asked = this.limit;
            cx.spawn(async (cx) => onMore(cx));
          }
          return Array.from({ length: range.end - range.start }, (_x, k) => range.start + k).map((i) => i < this.commits.length
            ? this.row(i, t, colors, mono, geo, textWidth, selected)
            : div().id("history-more").h(this.rowH()).flex_none().px(12).flex().items_center().text_color(t.accent).hover((s) => s.bg(t.hover))
              .child(loading ? "Loading more commits…" : `Load ${PAGE} more commits`));
        })
        .on_item_click((key, cx) => {
          const clicks = this.clicks ?? 1; this.clicks = 0;
          if (key === "more") return onMore(cx);
          const c = this.find(key);
          if (c) onPick(c, clicks, cx);
        })
        .on_item_secondary_click((key, _e, cx) => { const c = this.find(key); if (c) onMenu(c, cx); })
        .size_full())
      .child(Scrollbar.vertical(this.listId).viewport_from_layout().absolute().inset_0());
  }
}
