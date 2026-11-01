// Sends a question to the agent in the current space through the send
// dialog (dialog.js, opened as an overlay of this mod: the person adds a
// note and can pick the agent); should the overlay fail to open, the text
// goes straight to the space's agent with `hc send`.
import { agents, focused, hc, notify, openOverlay, setShared } from "herdr";

/** The agent a question goes to: the focused one, else an idle one, else the first in the space. */
export function pickAgent() {
  const space = focused()?.space, list = agents().filter((a) => a.space === space);
  return list.find((a) => a.focused) ?? list.find((a) => a.status === "idle") ?? list[0] ?? null;
}

/** `title`: a short label (the file and lines). `context`: the text the agent gets, already formatted.
 *  `sent`: a shared key the dialog sets to the send time once the text went out.
 *  Resolves "dialog" (opened), "sent" (sent directly) or "none" (nowhere to send). */
export async function ask({ title, context, sent }) {
  try { openOverlay({ mod: "reviewer", kind: "dialog", width: context ? 680 : 560, height: context ? 560 : 250, props: { dialog: true, title, context, sent } }); return "dialog"; }
  catch (e) { console.log(`the send dialog could not open, sending directly: ${e}`); }
  const agent = pickAgent();
  if (!agent) { notify({ title: "No agent in this space", body: "Start Claude in this space first.", level: "warning" }); return "none"; }
  const r = await hc(["send", agent.address, context]).catch((e) => ({ code: 1, stdout: "", stderr: String(e) }));
  if (r.code === 0) {
    notify({ title: `Sent to ${agent.program?.name ?? agent.address}`, body: title, level: "success" });
    if (sent) setShared(sent, Date.now());
    return "sent";
  }
  notify({ title: "Send failed", body: (r.stderr || r.stdout).trim().slice(0, 200), level: "error" });
  return "none";
}
