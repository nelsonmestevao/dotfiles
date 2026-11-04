// Declarative action engine. No eval, shell execution, or mod-source imports.
import { layout, panes, run, openOverlay, shared, setShared } from "herdr";
import { hooks } from "./hooks.js";

const MAX_ACTION_DEPTH = 12;
const MOD_TAB_PENDING_MS = 1500;

// ── Layout lookup and declarative predicates ───────────────────────────────

export function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const result = find(child, id);
    if (result) return result;
  }
  return null;
}

export function matches(condition, root = layout()) {
  if (!condition) return true;
  if (condition.shared) {
    const value = shared(condition.shared);
    // An explicit equals:false or equals:0 is not a truthiness test.
    return Object.prototype.hasOwnProperty.call(condition, "equals")
      ? value === condition.equals
      : Boolean(value);
  }
  if (condition.node) {
    const node = find(root, condition.node);
    return Boolean(node) && (condition.child ? node.active === condition.child : !node.hidden);
  }
  return false;
}

export function isActive(action, root = layout()) {
  if (action?.type === "panel") {
    const panel = find(root, action.container);
    const stack = find(root, action.stack);
    return Boolean(panel && !panel.hidden && stack?.active === action.target);
  }
  if (action?.type === "toggle-stack") return find(root, action.stack)?.active === action.child;
  return false;
}

// Contributions are opt-in and declarative. Layout entries win ID collisions.
// A publisher must remove its entries explicitly; shared state survives restarts.
export function buttons(config, contributions = {}) {
  const own = Array.isArray(config.buttons) ? config.buttons : [];
  const extra = config.contributions
    ? Object.entries(contributions ?? {})
        .sort(([a], [b]) => a.localeCompare(b))
        .flatMap(([, entries]) => (Array.isArray(entries) ? entries : []))
    : [];
  const ids = new Set();
  return [...own, ...extra]
    .filter((button) => {
      if (!button || typeof button.id !== "string" || !button.id || ids.has(button.id))
        return false;
      // Reserve the layout-owned ID even when hidden, so a contribution cannot
      // bypass the owner's visibility predicate by publishing the same ID.
      ids.add(button.id);
      return matches(button.when);
    })
    .sort((a, b) => (Number(a.order) || 0) - (Number(b.order) || 0));
}

// ── Reusable mod tabs ─────────────────────────────────────────────────────

function openModTab(action, space) {
  if (!space || typeof action.mod !== "string")
    throw Error("A mod tab requires a current space and mod");

  const ids = new Set((space.tabs ?? []).map((tab) => tab.id));
  const allPanes = panes();
  const existingTab = allPanes.find((pane) => pane.mod === action.mod && ids.has(pane.tab))?.tab;
  if (existingTab) return run("tab.select", { id: existingTab });

  // tab.new is queued. Guard the gap before the new pane appears in panes().
  const key = JSON.stringify([space.id, action.mod]);
  const entries = shared("better-tabs.mod-tabs") ?? {};
  if (entries[key]?.pending && Date.now() - entries[key].pending < MOD_TAB_PENDING_MS) return;

  // Pin the new mod to the focused checkout; the mod tab itself has no cwd.
  const activeTab = space.tabs?.find((tab) => tab.active)?.id;
  const candidates = allPanes.filter((pane) => pane.tab === activeTab && pane.cwd);
  const terminal = candidates.find((pane) => pane.focused) ?? candidates[0];
  const source = { cwd: terminal?.cwd ?? space.folder, on: space.machine ?? null };
  setShared("better-tabs.mod-tabs", { ...entries, [key]: { source, pending: Date.now() } });

  return run("tab.new", {
    space: space.id,
    name: action.name ?? action.mod,
    mod: action.mod,
    props: { ...(action.props ?? {}), space: space.id, source },
  });
}

// ── Action dispatch ───────────────────────────────────────────────────────

export function execute(action, context = {}, depth = 0) {
  if (!action || depth > MAX_ACTION_DEPTH)
    throw Error("Invalid or excessively nested Better Tabs action");
  const root = layout();
  switch (action.type) {
    case "command":
      if (typeof action.name !== "string" || !action.name) throw Error("Command name is required");
      return run(action.name, action.args ?? {});
    case "mod-tab":
      return openModTab(action, context.space);
    case "panel": {
      const panel = find(root, action.container);
      const stack = find(root, action.stack);
      if (!panel || !stack?.children?.some((child) => child.id === action.target))
        throw Error("Panel action references a missing container, stack, or child");
      if (isActive(action, root)) return run("layout.hide", { id: action.container });
      run("layout.select", { stack: action.stack, child: action.target });
      return run("layout.show", { id: action.container });
    }
    case "toggle-stack": {
      const stack = find(root, action.stack);
      const child = stack?.active === action.child ? action.fallback : action.child;
      if (!stack?.children?.some((node) => node.id === child))
        throw Error("Missing stack or child");
      return run("layout.select", { stack: action.stack, child });
    }
    case "overlay":
      if (typeof action.mod !== "string") throw Error("Overlay mod is required");
      return openOverlay({
        mod: action.mod,
        kind: action.kind ?? "popup",
        props: action.props ?? {},
        ...(action.width ? { width: action.width } : {}),
        ...(action.height ? { height: action.height } : {}),
      });
    case "sequence": {
      if (!Array.isArray(action.actions)) throw Error("Sequence actions must be an array");
      // Herdr run() queues commands; this preserves dispatch order, not async completion.
      // Observe hook rejections even inside sequences, without awaiting each step.
      const pending = [];
      for (const step of action.actions) {
        const result = execute(step, context, depth + 1);
        if (result?.then) {
          // Attach a rejection observer immediately if a later step throws.
          pending.push(
            result.catch((error) => {
              context.onError?.(error);
            }),
          );
        }
      }
      return pending.length ? Promise.all(pending) : undefined;
    }
    case "shared":
      if (typeof action.key !== "string" || !action.key) throw Error("Shared key is required");
      return setShared(action.key, action.toggle ? !shared(action.key) : action.value);
    case "hook": {
      const handler =
        Object.prototype.hasOwnProperty.call(hooks, action.name) && hooks[action.name];
      if (typeof handler !== "function") throw Error(`Unknown Better Tabs hook: ${action.name}`);
      return handler(action.args ?? {}, context);
    }
    default:
      throw Error(`Unknown Better Tabs action type: ${action.type}`);
  }
}
