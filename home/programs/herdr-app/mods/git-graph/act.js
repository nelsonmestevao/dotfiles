import { exec, notify, setShared, openOverlay, run } from "herdr";
import { commandsFor, dialogFor, dialogHeight, doneText, gitError } from "./git.js";

// Runs an action's git commands in order, stopping at the first failure. Every
// graph copy refreshes after, whether or not its folder watch saw the change.
export async function perform(action, values, ctx, { toast = true } = {}) {
  try {
    for (const args of commandsFor(action, values, ctx)) {
      const r = await exec("git", args, { cwd: ctx.root, on: ctx.on });
      if (r.code !== 0) {
        const message = gitError(r);
        if (toast) notify({ title: `Couldn't ${action.type === "checkout" ? "check out" : "do that"}`, body: message, level: "error" });
        return { ok: false, message };
      }
    }
    notify({ title: doneText(action, values), level: "success", timeout: 3000 });
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
