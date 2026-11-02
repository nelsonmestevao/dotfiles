// Changes, as a working git panel after Zed's: stage with checkboxes, commit,
// stash, push and pull, the diff of what's picked, and the history.
// One mod, four roles (props.role): the panel, its menus (popups over the
// window), the diff, shown in a tab of the main area, and (local change) a
// file tab that the files-mods panel opens.
import { View } from "gpui-kit";
import { props } from "herdr";
import { Panel } from "./panel.js";
import { Menu } from "./menu.js";
import { DiffView } from "./diff.js";
import { FileView } from "./file.js";

export default class GitChanges extends View {
  init(_props, cx) {
    const role = props()?.role;
    this.part = role === "menu" ? new Menu() : role === "diff" ? new DiffView() : role === "file" ? new FileView() : new Panel();
    this.part.init(cx);
  }

  render(cx) { return this.part.render(cx); }
}
