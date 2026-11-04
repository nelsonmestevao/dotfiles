// Native tab bar, persistent action toolbar, and a separate overflow-popup view.
// Keep layout commands in event handlers or synchronization tasks, never render.
import { em } from "./typography.js";
import { find, buttons, execute, matches, isActive } from "./actions.js";
import {
  toolbarPreferences,
  toolbarPartition,
  hideToolbarAction,
  placeToolbarAction,
  tabMoveIndex,
} from "./toolbar.js";
import { View, div, svg, image } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import {
  spaces,
  panes,
  run,
  openOverlay,
  closeOverlay,
  theme,
  window,
  shared,
  setShared,
  layout,
  settings,
  nextCommand,
  props,
  notify,
} from "herdr";

const ASSETS = "mods/better-tabs/";
const DRAG_KEY = "better-tabs.action-drag";
const PREFERENCES_KEY = "better-tabs.toolbar";
const DRAG_THRESHOLD = 5; // Small pointer movements must remain ordinary clicks.
const DRAG_TIMEOUT_MS = 15000;
const MENU_WIDTH = 240;

// Each row is 32px, with 2px gaps and 5px padding on each edge.
const menuHeight = (count) => Math.min(420, Math.max(1, count) * 34 + 8);

const DEFAULTS = {
  rememberPanels: { container: "panel", stack: "panel-body" },
  buttons: [
    {
      id: "files",
      label: "Files",
      icon: "file",
      when: { node: "files" },
      action: { type: "panel", container: "panel", stack: "panel-body", target: "files" },
    },
    {
      id: "changes",
      label: "Changes",
      icon: "changes",
      when: { node: "changes" },
      action: { type: "panel", container: "panel", stack: "panel-body", target: "changes" },
    },
  ],
};

function moved(start, point) {
  return Math.hypot(point.x - start.x, point.y - start.y) >= DRAG_THRESHOLD;
}
function contains(bounds, point) {
  return (
    bounds &&
    point.x >= bounds.x &&
    point.x <= bounds.x + bounds.width &&
    point.y >= bounds.y &&
    point.y <= bounds.y + bounds.height
  );
}
function afterMiddle(event) {
  return (event.local_position?.x ?? 0) > (event.bounds?.width ?? Infinity) / 2;
}

export default class Tabs extends View {
  // ── Configuration, lifecycle, and command dispatch ────────────────────────

  config() {
    return { ...DEFAULTS, ...props() };
  }

  init(_props, cx) {
    this.tabDrag = null;
    this.panels = {};
    try {
      const saved = JSON.parse(localStorage.getItem("panels") ?? "{}");
      if (saved && typeof saved === "object" && !Array.isArray(saved)) this.panels = saved;
    } catch {
      /* Ignore malformed saved preferences. */
    }
    if (this.config().mode !== "overflow") {
      // Synchronization can issue layout commands, so it must not run in render.
      this.syncPanel();
      cx.timer.every(300, () => {
        this.syncPanel();
        const drag = shared(DRAG_KEY);
        if (drag?.scope === this.toolbarScope() && Date.now() - drag.at > DRAG_TIMEOUT_MS)
          setShared(DRAG_KEY, null);
      });
      cx.spawn(async (cx) => {
        for (;;) this.command(await nextCommand(), cx);
      });
    }
  }

  entries() {
    return buttons(this.config(), shared("better-tabs.buttons"));
  }

  command(command, cx) {
    const config = this.config();
    if (command === "toggle-sidebar") {
      this.toggleSidebar();
      return;
    }

    if (command === "overflow") {
      this.openActions(this.toolbar().overflow);
      return;
    }
    const entry = command.startsWith("button:")
      ? this.entries().find((b) => b.id === command.slice(7))
      : null;
    const action = entry?.action ?? config.commands?.[command];
    if (entry && !this.enabled(entry)) return;
    if (action) this.act(action, cx);
  }

  enabled(button) {
    return !button.disabled && (!button.enabledWhen || matches(button.enabledWhen));
  }

  act(action, cx) {
    const space = spaces().find((s) => s.active);
    const failed = (error) =>
      notify({ title: "Better Tabs", body: String(error.message ?? error), level: "error" });
    try {
      const result = execute(action, {
        space,
        tab: space?.tabs?.find((t) => t.active),
        cx,
        onError: failed,
      });
      if (result?.catch) result.catch(failed);
    } catch (error) {
      failed(error);
    }
  }

  // ── Sidebar visibility and per-space panel memory ────────────────────────

  sidebarPanel(root = layout()) {
    const config = this.config();
    const id = config.panelToggle ?? config.rememberPanels?.container ?? "panel";
    return id === false ? null : find(root, id);
  }

  toggleSidebar() {
    const panel = this.sidebarPanel();
    // Hide the container, not its active child, so reopening keeps the selection.
    if (panel) run("layout.toggle", { id: panel.id });
  }

  syncPanel() {
    const memory = this.config().rememberPanels;
    if (!memory) return;
    const space = spaces().find((s) => s.active);
    const root = layout();
    const panel = find(root, memory.container);
    const body = find(root, memory.stack);
    if (!space || !panel || !body) return;
    const key = JSON.stringify([memory.container, memory.stack, space.id]);
    const now = panel.hidden ? null : body.active;
    if (key !== this.spaceKey) {
      const first = this.spaceKey === undefined;
      this.spaceKey = key;
      this.pending = null;
      if (!(first && !Object.prototype.hasOwnProperty.call(this.panels, key))) {
        const stored = this.panels[key];
        const want = body.children?.some((c) => c.id === stored) ? stored : null;
        if (want !== now) {
          this.pending = { want, until: Date.now() + 1000 };
          if (want) {
            run("layout.select", { stack: memory.stack, child: want });
            run("layout.show", { id: memory.container });
          } else run("layout.hide", { id: memory.container });
          return;
        }
      }
    }
    // Commands are queued. Let a restore reach the layout before saving again,
    // or the old visible panel would overwrite the preference we just restored.
    if (this.pending) {
      if (this.pending.want !== now && Date.now() < this.pending.until) return;
      this.pending = null;
    }
    if (this.panels[key] === now) return;
    this.panels[key] = now;
    localStorage.setItem("panels", JSON.stringify(this.panels));
  }

  // ── Persistent toolbar arrangement ────────────────────────────────────────

  toolbarScope() {
    return (
      this.config().toolbarScope ??
      JSON.stringify([shared("layout") ?? "default", this.config().toolbarId ?? "main"])
    );
  }

  preferences() {
    return toolbarPreferences(shared(PREFERENCES_KEY)?.[this.toolbarScope()]);
  }

  savePreferences(value) {
    setShared(PREFERENCES_KEY, {
      ...(shared(PREFERENCES_KEY) ?? {}),
      [this.toolbarScope()]: value,
    });
  }

  toolbar() {
    const limit = Math.max(
      0,
      Math.min(
        this.config().maxButtons ?? Infinity,
        Math.floor(((this.width ?? 1200) - 350) / 100),
      ),
    );
    return toolbarPartition(this.entries(), this.preferences(), limit);
  }

  pinAction(entry, target = null, after = false) {
    const entries =
      this.config().mode === "overflow"
        ? (this.config().allButtons ?? this.entries())
        : this.entries();
    this.savePreferences(placeToolbarAction(entries, this.preferences(), entry.id, target, after));
  }

  openActions(entries) {
    const bounds = this.moreBounds;
    // A popup is another copy of this mod. Pass its originating scope and full
    // action list so pinning can update the toolbar after the popup closes.
    openOverlay({
      ...(bounds
        ? {
            at: {
              x: Math.max(0, bounds.x + bounds.width - MENU_WIDTH),
              y: bounds.y + bounds.height + 6,
            },
          }
        : {}),
      mod: "better-tabs",
      kind: "popup",
      width: MENU_WIDTH,
      height: menuHeight(entries.length),
      props: {
        ...this.config(),
        mode: "overflow",
        toolbarScope: this.toolbarScope(),
        allButtons: this.entries(),
        buttons: entries,
        contributions: false,
        rememberPanels: false,
      },
    });
  }

  // ── Pointer-driven tab and toolbar drags ──────────────────────────────────
  // GPUI exposes pointer events rather than an internal drag payload API. The
  // source keeps its layout slot; a floating copy follows the pointer and a
  // marker shows the exact insertion boundary. No tab.move occurs until drop.

  beginTabDrag(tab, event, cx) {
    cx.stop_propagation();
    if (this.actionDrag()) setShared(DRAG_KEY, null);
    if (event.click_count === 2) {
      this.tabDrag = null;
      run("tab.rename", { id: tab.id });
      return;
    }
    // Local change (dotfiles): select on press, not on release. On mod tabs the release can
    // go missing (the tab bar redraws between press and release, and gpui-kit drops the old
    // render's callbacks), which left a plain click as a stuck drag that never selected.
    if (!tab.active) run("tab.select", { id: tab.id });
    const point = event.position ?? { x: 0, y: 0 };
    this.tabDrag = {
      id: tab.id,
      label: tab.name,
      space: spaces().find((s) => s.active)?.id,
      start: point,
      point,
      active: false,
      target: null,
    };
  }

  hoverTab(tab, event, cx) {
    if (!this.tabDrag) return;
    const point = event.position ?? this.tabDrag.point;
    this.tabDrag.point = point;
    this.tabDrag.active ||= moved(this.tabDrag.start, point);
    if (this.tabDrag.active) {
      this.tabDrag.target = { id: tab.id, after: afterMiddle(event) };
      cx.notify();
    }
  }

  finishTabDrag(tab, event, cx) {
    const drag = this.tabDrag;
    if (!drag) return;
    cx.stop_propagation();
    this.hoverTab(tab, event, cx);
    this.commitTabDrag(cx, tab.id);
  }

  commitTabDrag(cx, clickedID = null) {
    const drag = this.tabDrag;
    this.tabDrag = null;
    if (!drag) return;
    const space = spaces().find((s) => s.active);
    if (space?.id === drag.space) {
      if (drag.active && drag.target) {
        const index = tabMoveIndex(space.tabs ?? [], drag.id, drag.target.id, drag.target.after);
        if (index !== null) run("tab.move", { id: drag.id, index });
        this.ignoreClickUntil = Date.now() + 300;
      } else if (!drag.active && drag.id === clickedID) run("tab.select", { id: clickedID });
    }
    cx.notify();
  }

  // Toolbar and popup instances exchange drag state through shared storage;
  // tab drags remain local because they never cross between those views.
  actionDrag() {
    const drag = shared(DRAG_KEY);
    return drag?.scope === this.toolbarScope() && Date.now() - drag.at < DRAG_TIMEOUT_MS
      ? drag
      : null;
  }

  beginActionDrag(entry, event, cx, fromMenu) {
    cx.stop_propagation();
    this.tabDrag = null;
    const point = event.position ?? { x: 0, y: 0 };
    setShared(DRAG_KEY, {
      scope: this.toolbarScope(),
      id: entry.id,
      label: entry.label ?? entry.id,
      icon: entry.icon,
      start: point,
      point,
      active: false,
      fromMenu,
      at: Date.now(),
      target: null,
    });
  }

  moveActionDrag(event, cx, target = undefined) {
    const drag = this.actionDrag();
    if (!drag) return;
    const point = event.position ?? drag.point;
    const active = drag.active || moved(drag.start, point);
    const next = { ...drag, point, active, at: Date.now() };
    if (target !== undefined) next.target = target;
    if (active) {
      setShared(DRAG_KEY, next);
      cx.notify();
    }
  }

  hoverAction(entry, event, cx) {
    this.moveActionDrag(event, cx, {
      kind: "toolbar",
      id: entry.id,
      after: afterMiddle(event),
      bounds: event.bounds,
    });
  }

  finishActionDrag(cx) {
    // A terminal tab dropped on an action is not a toolbar-action gesture.
    // Cancel it rather than leaving a ghost or activating the drop target.
    if (this.tabDrag) {
      this.tabDrag = null;
      this.ignoreClickUntil = Date.now() + 300;
      cx.notify();
      return true;
    }
    const drag = this.actionDrag();
    if (!drag) return false;
    setShared(DRAG_KEY, null);
    if (!drag.active) return false;
    // The click generated after a reorder must not also activate its button.
    this.ignoreClickUntil = Date.now() + 300;
    const entry = this.entries().find((item) => item.id === drag.id);
    if (entry && this.config().mode !== "overflow") {
      if (drag.target?.kind === "overflow")
        this.savePreferences(hideToolbarAction(this.preferences(), entry.id));
      else if (drag.target?.kind === "toolbar")
        this.pinAction(entry, drag.target.id, drag.target.after);
    }
    cx.notify();
    return true;
  }

  leaveMenu(_cx) {
    const drag = this.actionDrag();
    if (!drag?.fromMenu) return;
    // Closing the popup on drag-out exposes the real toolbar as a drop surface.
    setShared(DRAG_KEY, { ...drag, active: true, at: Date.now(), target: null });
    closeOverlay(props().overlay);
  }

  cancelDrags(cx) {
    const active = Boolean(this.tabDrag || this.actionDrag());
    this.tabDrag = null;
    if (this.actionDrag()) setShared(DRAG_KEY, null);
    if (active) cx.notify();
  }

  movePointer(event, cx) {
    if (event.bounds) this.barBounds = event.bounds;
    if (this.tabDrag) {
      const point = event.position ?? this.tabDrag.point;
      this.tabDrag.point = point;
      this.tabDrag.active ||= moved(this.tabDrag.start, point);
      if (this.tabDrag.active) cx.notify();
    }
    this.moveActionDrag(event, cx);
  }

  // ── Small controls and toolbar buttons ────────────────────────────────────

  icon(name, size = 14) {
    return svg(name.includes("/") ? name : `${ASSETS}${name}.svg`)
      .size(size)
      .flex_none();
  }

  simple(id, label, tooltip, action) {
    const t = theme();
    return div()
      .id(id)
      .size(26)
      .flex_none()
      .flex()
      .items_center()
      .justify_center()
      .rounded(6)
      .text_color(t.dim)
      .tooltip(tooltip)
      .accessibility_label(tooltip)
      .hover((s) => s.bg(t.hover).text_color(t.foreground))
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .on_click((event, cx) => {
        cx.stop_propagation();
        if (!(Date.now() < this.ignoreClickUntil)) action(event, cx);
      })
      .child(label);
  }

  marker(after, t) {
    return div()
      .id("drop-indicator")
      .absolute()
      .top(2)
      .bottom(2)
      .w(2)
      .rounded(1)
      .bg(t.accent)
      .when(after, (el) => el.right(-2))
      .when(!after, (el) => el.left(-2));
  }

  actionButton(entry, cx, menu = false) {
    const t = theme();
    const enabled = this.enabled(entry);
    const drag = this.actionDrag();
    const active = entry.activeWhen ? matches(entry.activeWhen) : isActive(entry.action);
    const badge = entry.badge?.shared ? shared(entry.badge.shared) : entry.badge;
    return h_flex()
      .id(`action-${entry.id}`)
      .relative()
      .h(menu ? 32 : 26)
      .px(8)
      .gap(5)
      .flex_none()
      .items_center()
      .rounded(6)
      .when(menu, (el) => el.w_full())
      .text_size(menu ? 12.8 : em(0.95))
      .bg(active ? t.selected : menu ? t.popover : t.chrome)
      .text_color(!enabled ? t.dim : active ? t.foreground : t.muted)
      .tooltip(
        menu
          ? `${entry.tooltip ?? entry.label ?? entry.id} · Drag out or pin to show in toolbar`
          : (entry.tooltip ?? entry.label ?? entry.id),
      )
      .accessibility_label(entry.label ?? entry.id)
      .when(enabled, (el) => el.cursor_pointer().hover((s) => s.bg(t.hover)))
      .when(drag?.active && drag.id === entry.id && !menu, (el) => el.opacity(0.35))
      .on_mouse_down("left", (event, cx) => this.beginActionDrag(entry, event, cx, menu))
      .on_mouse_move((event, cx) => {
        if (menu) this.moveActionDrag(event, cx);
        else this.hoverAction(entry, event, cx);
      })
      .on_mouse_up("left", (_event, cx) => {
        cx.stop_propagation();
        this.finishActionDrag(cx);
      })
      .on_click((_e, cx) => {
        cx.stop_propagation();
        if (!enabled || Date.now() < this.ignoreClickUntil) return;
        if (menu) closeOverlay(props().overlay);
        this.act(entry.action, cx);
      })
      .when(Boolean(entry.icon), (el) => el.child(this.icon(entry.icon)))
      .when(menu || !entry.iconOnly || !entry.icon, (el) =>
        el.child(
          div()
            .when(menu, (label) => label.flex_1().min_w(0).truncate())
            .child(entry.label ?? entry.id),
        ),
      )
      .when(badge !== undefined && badge !== null && badge !== false && badge !== "", (el) =>
        el.child(div().text_size(em(0.8)).text_color(t.accent).child(String(badge))),
      )
      .when(
        !menu && drag?.active && drag.target?.kind === "toolbar" && drag.target.id === entry.id,
        (el) => el.child(this.marker(drag.target.after, t)),
      )
      .when(menu, (el) =>
        el.child(
          this.simple(`pin-${entry.id}`, this.icon("pin", 13), "Show in toolbar", () => {
            setShared(DRAG_KEY, null);
            this.pinAction(entry);
            closeOverlay(props().overlay);
          })
            .size(22)
            .on_mouse_up("left", (_e, cx) => cx.stop_propagation()),
        ),
      );
  }

  renderOverflow(cx) {
    const t = theme();
    const entries = this.entries()
      .slice()
      .sort(
        (a, b) =>
          String(a.label ?? a.id).localeCompare(String(b.label ?? b.id), undefined, {
            sensitivity: "base",
          }) || a.id.localeCompare(b.id),
      );
    // A scroll container has no intrinsic content height in a native popup.
    // Give the popup a real size, then scroll only its flexing inner list.
    const list = v_flex().id("actions-menu-list").flex_1().min_h(0).gap(2).overflow_y_scrollbar();
    if (!entries.length)
      list.child(
        h_flex()
          .h(32)
          .flex_none()
          .px(8)
          .items_center()
          .text_size(12.8)
          .text_color(t.dim)
          .tooltip("Drag a toolbar action onto ⋮ to hide it here.")
          .child("No hidden actions"),
      );
    list.children(entries.map((entry) => this.actionButton(entry, cx, true)));
    return v_flex()
      .id("actions-menu")
      .w(MENU_WIDTH)
      .h(menuHeight(entries.length))
      .p(5)
      .text_color(t.foreground)
      .bg(t.popover)
      .on_hover((hovered, cx) => {
        if (!hovered) this.leaveMenu(cx);
      })
      .on_mouse_down_out((_event, cx) => this.cancelDrags(cx))
      .child(list);
  }

  // ── Tabs and the adjacent new-tab button ──────────────────────────────────

  tabItem(tab, space, ps, config, t) {
    const program =
      ps.find((p) => p.tab === tab.id && p.program?.agent)?.program ??
      ps.find((p) => p.tab === tab.id)?.program;
    // Mod panes carry no program, so their icon comes from the layout's modIcons
    // or the shared registry mods publish for themselves.
    const modPane = program?.icon ? null : ps.find((p) => p.tab === tab.id && p.mod);
    const modIcon = modPane
      ? { ...(shared("mod-icons") ?? {}), ...(config.modIcons ?? {}) }[modPane.mod]
      : null;
    const drag = this.tabDrag;
    return h_flex()
      .id(`tab-${tab.id}`)
      .relative()
      .h(29)
      .px(10)
      .gap(7)
      .rounded(7)
      .items_center()
      .flex_none()
      .text_size(em(1))
      .border(1)
      .border_color(tab.active ? t.border : t.chrome)
      .bg(tab.active ? t.raised : t.chrome)
      .text_color(tab.active ? t.foreground : t.muted)
      .hover((s) => s.bg(t.hover))
      .when(drag?.active && drag.id === tab.id, (el) => el.opacity(0.35))
      .on_mouse_down("left", (event, cx) => this.beginTabDrag(tab, event, cx))
      .on_mouse_move((event, cx) => this.hoverTab(tab, event, cx))
      .on_mouse_up("left", (event, cx) => this.finishTabDrag(tab, event, cx))
      .on_mouse_down("right", (_e, cx) => {
        cx.stop_propagation();
        this.cancelDrags(cx);
        openOverlay({
          mod: "menu",
          kind: "popup",
          width: 200,
          props: { tab: "tab", target: { id: tab.id, space: space.id } },
        });
      })
      .when(config.programIcons !== false && Boolean(program?.icon), (el) =>
        el.child(
          program.tint
            ? svg(program.icon).size(14).text_color(t.muted)
            : image(program.icon).size(14),
        ),
      )
      .when(config.programIcons !== false && Boolean(modIcon), (el) =>
        el.child(svg(modIcon).size(14).text_color(t.muted)),
      )
      .child(
        div()
          .max_w(config.tabMaxWidth ?? 170)
          .truncate()
          .tooltip(tab.name)
          .child(tab.zoomed ? `${tab.name} Z` : tab.name),
      )
      .when(config.statusIndicators !== false && tab.status === "working", (el) =>
        el.child(this.icon("spinner", 12).text_color(t.working).spin(900)),
      )
      .when(config.statusIndicators !== false && ["blocked", "done"].includes(tab.status), (el) =>
        el.child(div().size(6).rounded(3).bg(t[tab.status])),
      )
      .when(config.closeButtons !== "none" && (tab.active || config.closeButtons === "all"), (el) =>
        el.child(
          this.simple(`close-${tab.id}`, this.icon("close", 12), "Close tab", (_e, cx) => {
            this.cancelDrags(cx);
            run("tab.close", { id: tab.id });
          }).on_mouse_up("left", (_e, cx) => cx.stop_propagation()),
        ),
      )
      .when(drag?.active && drag.target?.id === tab.id, (el) =>
        el.child(this.marker(drag.target.after, t)),
      );
  }

  dragPreview(t) {
    const drag = this.tabDrag?.active ? this.tabDrag : this.actionDrag();
    if (!drag?.active) return null;
    const width = Math.min(200, Math.max(90, String(drag.label).length * em(0.6) + 32));
    const x = drag.point.x - (this.barBounds?.x ?? 0);
    // Offset the preview from the pointer so it cannot cover the drop hitbox.
    const left = x + width + 12 < (this.width ?? 1200) ? x + 12 : Math.max(0, x - width - 12);
    return h_flex()
      .id("drag-preview")
      .absolute()
      .left(left)
      .top(4)
      .h(29)
      .w(width)
      .px(9)
      .gap(5)
      .items_center()
      .rounded(7)
      .border(1)
      .border_color(t.accent)
      .bg(t.raised)
      .text_color(t.foreground)
      .opacity(0.95)
      .when(Boolean(drag.icon), (el) => el.child(this.icon(drag.icon)))
      .child(div().min_w(0).truncate().child(drag.label));
  }

  render(cx) {
    const config = this.config();
    const t = theme();
    if (config.mode === "overflow") return this.renderOverflow(cx);
    const space = spaces().find((s) => s.active);
    const shown = space?.tabs ?? [];
    const ps = panes();
    const root = layout();
    const sidebar = find(root, config.sidebar ?? "sidebar");
    const w = window();
    const padding =
      w?.platform === "macos" && w.titlebar === "none" && !w.fullscreen && root?.traffic_lights
        ? Math.max(
            10,
            (root.traffic_lights[0] + 64) / (settings().zoom || 1) -
              (sidebar?.hidden ? 0 : (sidebar?.size?.px ?? 0)),
          )
        : 10;
    const { visible, overflow } = this.toolbar();
    const bar = h_flex()
      .id("better-tabs-root")
      .relative()
      .text_size(em(1))
      .size_full()
      .min_w(0)
      .px(10)
      .pl(padding)
      .gap(3)
      .items_center()
      .bg(t.chrome)
      .border_b(1)
      .border_color(t.border)
      .on_size_change((size, cx) => {
        if (this.width !== size.width) {
          this.width = size.width;
          cx.notify();
        }
      })
      .on_mouse_move((event, cx) => this.movePointer(event, cx))
      .on_mouse_up("left", (_event, cx) => {
        this.commitTabDrag(cx);
        this.finishActionDrag(cx);
      })
      .on_mouse_down_out((_event, cx) => this.cancelDrags(cx))
      .on_hover((hovered, cx) => {
        if (!hovered) this.cancelDrags(cx);
      });
    const tabList = h_flex()
      .id("tab-scroll")
      .flex_1()
      .min_w(0)
      .h_full()
      .items_center()
      .gap(3)
      .overflow_x_scrollbar()
      .on_scroll_wheel((event) => {
        if (
          !this.tabDrag &&
          !this.actionDrag()?.active &&
          config.scrollNavigation !== false &&
          Math.abs(event.delta.y) >= 1
        )
          run(event.delta.y > 0 ? "tab.prev" : "tab.next");
      })
      .children(shown.map((tab) => this.tabItem(tab, space, ps, config, t)));
    // The + is part of the scroll content, directly after the last tab, not
    // after the flexible space separating tabs from right-side actions.
    if (config.newButton !== false)
      tabList.child(
        this.simple("tab-new", "+", "New tab", () =>
          openOverlay({ mod: "new-menu", kind: "popup", width: 250, height: 512 }),
        )
          .on_mouse_move((event, cx) => {
            if (shown.length)
              this.hoverTab(shown.at(-1), { ...event, local_position: { x: Infinity } }, cx);
          })
          .on_mouse_up("left", (event, cx) => {
            if (this.tabDrag && shown.length)
              this.finishTabDrag(shown.at(-1), { ...event, local_position: { x: Infinity } }, cx);
          }),
      );
    bar.child(tabList);

    const actions = h_flex()
      .id("action-toolbar")
      .gap(3)
      .items_center()
      .flex_none()
      .on_mouse_move((event, cx) => {
        const drag = this.actionDrag();
        if (!drag) return;
        if (!contains(drag.target?.bounds, event.position ?? drag.point)) {
          this.moveActionDrag(event, cx, {
            kind: "toolbar",
            id: visible.at(-1)?.id ?? null,
            after: true,
            bounds: event.bounds,
          });
        }
      })
      .on_hover((hovered, cx) => {
        if (!hovered && this.actionDrag()?.target) this.moveActionDrag({}, cx, null);
      });
    let group;
    for (const entry of visible) {
      if (group !== undefined && entry.group !== group)
        actions.child(div().w(1).h(16).mx(4).bg(t.border));
      group = entry.group;
      actions.child(this.actionButton(entry, cx));
    }
    const drag = this.actionDrag();
    actions.child(
      this.simple(
        "actions-more",
        this.icon("more-vertical", 16),
        "More actions · drop a toolbar action here to hide it",
        () => this.openActions(overflow),
      )
        .when(drag?.active && drag.target?.kind === "overflow", (el) =>
          el.bg(t.selected).border(1).border_color(t.accent),
        )
        .on_mouse_down("left", (event, cx) => {
          cx.stop_propagation();
          this.moreBounds = event.bounds ?? this.moreBounds;
        })
        .on_mouse_move((event, cx) => {
          this.moreBounds = event.bounds ?? this.moreBounds;
          this.moveActionDrag(event, cx, { kind: "overflow", bounds: event.bounds });
        })
        .on_mouse_up("left", (_event, cx) => {
          cx.stop_propagation();
          this.finishActionDrag(cx);
        }),
    );
    // The panel control stays outside the configurable action list, so it
    // cannot itself be hidden in overflow. Toggling preserves the active child.
    const panel = this.sidebarPanel(root);
    if (panel)
      actions.child(
        this.simple(
          "panel-toggle",
          this.icon("panel-right", 16),
          panel.hidden ? "Show sidebar" : "Hide sidebar",
          () => this.toggleSidebar(),
        ).text_color(panel.hidden ? t.dim : t.foreground),
      );
    bar.child(actions);
    if (w?.buttons)
      bar
        .child(
          this.simple(
            "minimize",
            w.platform === "windows" ? this.icon("win-min", 16) : "−",
            "Minimize",
            () => run("window.minimize"),
          ),
        )
        .child(
          this.simple(
            "maximize",
            w.platform === "windows" ? this.icon(w.maximized ? "win-restore" : "win-max", 16) : "□",
            "Maximize",
            () => run("window.maximize"),
          ),
        )
        .child(
          this.simple("close-window", this.icon("close", 13), "Close window", () =>
            run("window.close"),
          ),
        );
    const preview = this.dragPreview(t);
    if (preview) bar.child(preview);
    return bar;
  }
}
