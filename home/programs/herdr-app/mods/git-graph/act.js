import { exec, notify, setShared, openOverlay, run } from "herdr";
import { dialogFor, dialogHeight, doneText } from "./git.js";
import { executeAction } from "./execute.js";

// Runs an action's git commands in order, stopping at the first failure. Every
// graph copy refreshes after, whether or not its folder watch saw the change.
export async function perform(action, values, ctx, { toast = true } = {}) {
  try {
    const result = await executeAction(action, values, ctx, exec);
    if (!result.ok) {
      if (toast) notify({ title: "Couldn't do that", body: result.message, level: "error" });
      return result;
    }
    notify({ title: doneText(action, values), level: "success", timeout: 3000 });
    // A Manygit row that failed in Fetch all reads as fetched again.
    if (action.type === "fetch") setShared("git-graph.fetched", { root: ctx.root, at: Date.now() });
    return { ok: true };
  } catch (e) {
    const message = String(e?.message ?? e);
    if (toast) notify({ title: "Git didn't run", body: message, level: "error" });
    return { ok: false, message };
  } finally {
    setShared("git-graph.changed", Date.now());
  }
}

// Opens the action's dialog; false when it has none and should run at once.
export function openDialog(action, ctx) {
  const spec = dialogFor(action, ctx);
  if (!spec) return false;
  openOverlay({ mod: "git-graph", kind: "dialog", width: 420, height: dialogHeight(spec), props: { role: "dialog", action, ctx } });
  return true;
}

export function showChanges() {
  run("layout.select", { stack: "panel-body", child: "changes" });
  run("layout.show", { id: "panel" });
}
