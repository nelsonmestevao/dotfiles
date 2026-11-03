// Herdr Code Review: a VS Code-style Source Control panel whose files open in tabs.
// One mod: the Source Control panel, diff/file tabs, and a branch picker.
import { View } from "gpui-kit";
import { props } from "herdr";
import { BranchPicker } from "./branch-picker.js";
import { CommentOverview } from "./comment-overview.js";
import { ReviewPaneHeader } from "./pane-header.js";
import { Panel } from "./panel.js";
import { DiffTab } from "./diff.js";
import { FileTab } from "./viewer.js";

export default class ScmTabs extends View {
  init(_props, cx) {
    const role = props()?.role;
    this.part = role === "branches" ? new BranchPicker() : role === "comments" ? new CommentOverview() :
      role === "pane-header" ? new ReviewPaneHeader() :
      role === "diff" ? new DiffTab() : role === "file" ? new FileTab() : new Panel();
    this.part.init(cx);
  }
  close() { this.part.close?.(); }
  render(cx) { return this.part.render(cx); }
}
