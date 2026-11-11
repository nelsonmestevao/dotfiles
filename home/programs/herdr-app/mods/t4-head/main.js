// t4's top: on the left the brand over the sidebar (the name; the layout
// paints the blue band), in the middle "project / thread" over the
// terminal (the project is the repo, from git), and on the right three
// toggles: thread details (the floating card, shared "t4.details"), the
// terminal drawer (shells under the agent: a first one splits in, then
// zooming the agent hides or shows them), the right panel (the layout's
// hidden "panel" column); then the window buttons where the system draws
// none. Both halves are this mod with props { part: "brand" | "crumbs" };
// the layout makes them drag the window, and the controls here keep their
// press.

import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { spaces, panes, run, theme, shared, props, layout, window as win, setShared, exec } from "herdr";

const I = (name) => `mods/t4-threads/${name}.svg`;
const C = { text: "#ececee", muted: "#a1a1aa", dim: "#71717a", chip: "#18181b", line: "#1f1f23" };

function own(el) {
  return el.on_mouse_down("left", (_e, cx) => cx.stop_propagation());
}

// Space colors, kept by space id in shared "space.colors": a theme
// color name ("ansi6") or a picked #rrggbb. A space seen without one gets
// the theme color fewest spaces use, once; every mod does the same in the
// same order, so they agree, and adding or renaming spaces moves nothing.
const PROJECT_COLORS = ["ansi6", "ansi3", "ansi4", "ansi5", "ansi2", "ansi1"];
function spaceColors() {
  const ids = new Set(spaces().map((p) => p.id));
  const kept = Object.fromEntries(Object.entries(shared("space.colors") ?? {}).filter(([id]) => ids.has(id)));
  let changed = Object.keys(kept).length !== Object.keys(shared("space.colors") ?? {}).length;
  for (const p of spaces()) {
    if (kept[p.id] || p.name === "~") continue;
    const uses = (c) => Object.values(kept).filter((v) => v === c).length;
    kept[p.id] = PROJECT_COLORS.reduce((best, c) => (uses(c) < uses(best) ? c : best));
    changed = true;
  }
  if (changed) setShared("space.colors", kept);
  return kept;
}
function spaceColor(t, p) {
  if (p.name === "~") return t.dim;
  const c = spaceColors()[p.id] ?? PROJECT_COLORS[0];
  return c.startsWith("#") ? c : t[c];
}

// Whether a layout node is shown.
function shown(node, id) {
  if (!node) return false;
  if (node.id === id) return !node.hidden;
  return (node.children ?? []).some((c) => shown(c, id));
}

// The drawer: the shown tab's panes beside its agent's, and whether they show.
function drawer() {
  const p = spaces().find((x) => x.active);
  const c = p?.tabs.find((x) => x.active);
  const mine = panes().filter((x) => x.tab === c?.id && x.terminal);
  const lead = mine.find((x) => x.program?.agent) ?? mine[0];
  return { mine, lead, open: mine.length > 1 && !lead?.zoomed };
}

function toggleDrawer() {
  const { mine, lead } = drawer();
  if (!lead) return;
  if (mine.length === 1) run("pane.split", { direction: "down", pane: lead.pane });
  else {
    run("pane.zoom", { pane: lead.pane });
    if (!lead.zoomed) run("pane.focus", { pane: lead.pane });
  }
}

function button(id, icon, label, onClick, on = false, frame = true) {
  return own(
    h_flex()
      .id(id)
      .h(28)
      .px(label ? 10 : 7)
      .gap(6)
      .items_center()
      .rounded(8)
      .when(frame, (el) => el.border_1().border_color(C.line))
      .text_size(13)
      .text_color(on ? C.text : C.muted)
      .when(on, (el) => el.bg(C.chip))
      .cursor_pointer()
      .hover((s) => s.bg(C.chip).text_color(C.text))
      .on_click(onClick)
      .child(svg(I(icon)).size(14))
      .when(Boolean(label), (el) => el.child(label)),
  );
}

export default class Head extends View {
  init(_props, cx) {
    this.repos = {}; // folder -> repo name | null
  }

  // Name the repo where the thread's terminal is now, else the space's folder.
  project(p, cx) {
    const at = drawer().lead?.cwd || p.folder;
    const location = JSON.stringify([p.machine ?? null, at]);
    if (!(location in this.repos)) {
      this.repos[location] = undefined;
      cx.spawn(async (cx) => {
        const r = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd: at, on: p.machine }).catch(() => ({ code: 1 }));
        const key = r.code === 0 ? r.stdout.trim() : null;
        this.repos[location] = key && (key.endsWith("/.git") ? key.slice(0, -5) : key).split("/").pop();
        cx.notify();
      });
    }
    return this.repos[location] ?? p.name;
  }

  brand(w) {
    const mac = w.platform === "macos" && !w.fullscreen;
    return h_flex()
      .size_full()
      .pl(mac ? 80 : 18)
      .gap(10)
      .items_center()
      .text_size(16)
      .font_semibold()
      .text_color(C.text)
      .child(svg("icons/agent.svg").size(16).text_color("#93c5fd"))
      .child("Herdr")
      ;
  }

  crumbs(t, w, cx) {
    const p = spaces().find((x) => x.active);
    const c = p?.tabs.find((x) => x.active);
    const toggle = (id, icon, on, onClick) => button(id, icon, "", onClick, on, false);
    return h_flex()
      .size_full()
      .pl(20)
      .pr(10)
      .gap(10)
      .items_center()
      .text_size(15)
      .when(Boolean(p), (el) =>
        el
          .child(div().w(10).h(10).rounded(3).bg(spaceColor(t, p)))
          .child(div().text_color(C.muted).child(this.project(p, cx)))
          .child(div().text_color(C.dim).child("/"))
          .child(div().flex_1().truncate().font_medium().text_color(C.text).child(c?.name ?? "")),
      )
      .when(!p, (el) => el.child(div().flex_1()))
      .child(
        h_flex()
          .gap(2)
          .child(toggle("t4-h-details", "file-text", shared("t4.details") === true, () => setShared("t4.details", shared("t4.details") !== true)))
          .child(toggle("t4-h-drawer", "panel-bottom", drawer().open, toggleDrawer))
          .child(toggle("t4-h-panel", "panel-right", shown(layout(), "panel"), () => run("layout.toggle", { id: "panel" }))),
      )
      .when(Boolean(w.buttons), (el) =>
        el.child(
          h_flex()
            .pl(8)
            .gap(6)
            .child(button("t4-h-min", "minus", "", () => run("window.minimize")))
            .child(button("t4-h-max", "square", "", () => run("window.maximize")))
            .child(button("t4-h-close", "x", "", () => run("window.close"))),
        ),
      );
  }

  render(cx) {
    const w = win() ?? {};
    return props()?.part === "brand" ? this.brand(w) : this.crumbs(theme(), w, cx);
  }
}
