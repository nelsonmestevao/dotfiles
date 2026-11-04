// Optional trusted JavaScript extensions local to this mod. Declarative buttons
// invoke {type:"hook", name:"example", args:{...}}. Do not store callback cx.
// Handlers receive (args, {space, tab, cx}); use cx.spawn for async work.
// Do not import another mod's source. Prefer its public Herdr command instead.
import { run, setShared } from "herdr";

export const hooks = {
  // Local change (dotfiles): the alt-shift-f/c/g/n keys (better-tabs.<panel> in keys.json) show
  // that side panel and never hide it, unlike a panel button. With `focus`, they also stamp
  // that shared key so the panel takes the keyboard (filetree.focus, tab-notes.focus); pressed
  // again, the panel gives the keyboard back to the tab.
  showPanel({ panel, focus }) {
    run("layout.select", { stack: "panel-body", child: panel });
    run("layout.show", { id: "panel" });
    if (focus) setShared(focus, Date.now());
  },
};
