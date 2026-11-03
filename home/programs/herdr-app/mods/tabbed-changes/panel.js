// The Source Control panel, after VS Code's: Merge / Staged / Changes sections, per-file stage,
// unstage and discard, a commit box and push / pull. Clicking a file shows its diff in a tab
// (single click reuses one preview tab, double click gets a tab of its own).
import { div } from "gpui-kit";
import { v_flex, h_flex, TextareaState, Textarea } from "gpui-base";
import { spaces, panes, focused, exec, watchFolder, theme, shared, openOverlay } from "herdr";
import { pushCurrent, pullCurrent, branchTarget, BRANCH_EVENT } from "./branches.js";
import { Coalescer } from "./read-cache.js";
import { readGit, invalidateReads, invalidateRepository, REPOSITORY_EVENT } from "./repository.js";
import { resolveOrigin } from "./comparison.js";
import * as G from "./git.js";
import { VIEW_KEY, showDiff, updatePreview, openFileTab, openInEditor } from "./tabs.js";
import { iconButton, toolButton, icon, fileIcon } from "./ui.js";
import { commentsFor } from "./comments.js";

// Where the panel looks: the focused terminal's folder. A diff or file tab (a mod pane with no
// folder) keeps whatever repository the panel already shows.
function location(previous, root) {
  const space = spaces().find((s) => s.active), f = focused();
  const pane = f?.pane ? panes().find((p) => p.pane === f.pane) : null;
  if (pane?.mod === "tabbed-changes" && space) {
    const entry = shared(VIEW_KEY)?.[space.id];
    const source = entry?.tab === pane.tab ? entry.view?.source : null;
    if (source?.root) {
      const on = source.on ?? null;
      if (previous && root === source.root && previous.on === on) return previous;
      return { cwd: source.root, on };
    }
  }
  if (pane && pane.terminal === null && previous) return previous;
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  return { cwd: pane?.cwd || f?.cwd || space?.folder, on };
}

export class Panel {
  init(cx) {
    this.staged = []; this.changes = []; this.conflicts = []; this.branch = null; this.originBase=null;
    this.message = ""; this.collapsed = {}; this.hover = null; this.confirm = null; this.loc = null;
    this.handle = cx.focus_handle(); this.refreshQueue=new Coalescer();
    this.input = TextareaState.new({ placeholder: "Message (⌘Enter to commit)" });
    this.input.set_auto_grow(2, 6);
    this.input.on("change", (_e, cx) => {
      const had = Boolean(this.message.trim());
      this.message = this.input.value();
      if (had !== Boolean(this.message.trim())) cx.notify();
    });
    this.input.on("submit", (_e, cx) => this.commit(cx));
    this.input.on("focus", (_e, cx) => { this.typing = true; cx.notify(); });
    this.input.on("blur", (_e, cx) => { this.typing = false; cx.notify(); });
    this.refresh(cx);
    cx.timer.every(10000, (cx) => this.refresh(cx));
  }

  get all() { return [...this.conflicts, ...this.staged, ...this.changes]; }
  key() { this.loc = location(this.loc, this.root); return JSON.stringify(this.loc); }
  source() { return { root: this.root, on: this.on ?? null }; }

  watch(root, cx) {
    if (this.on || this.watched === root) return;
    this.watched = root;
    cx.spawn(async (cx) => {
      try { while (this.watched === root) { await watchFolder(root); if (this.watched === root) this.requestRefresh(cx); } }
      catch { this.watched = null; }
    });
  }

  requestRefresh(cx) {
    this.refreshQueue.request(fn=>cx.timer.after(150,fn),cx=>{invalidateReads();this.refresh(cx);});
  }
  close(){this.watched=null;this.refreshQueue.cancel();this.input.release();}

  reset() {
    this.root = null; this.staged = []; this.changes = []; this.conflicts = []; this.branch = null; this.originBase=null;
    this.message = ""; this.input.set_value(""); this.error = null; this.note = null; this.watched = null; this.limited = false; this.confirm = null;
  }

  refresh(cx) {
    if (this.loading || this.busy) { this.dirty = true; return; }
    const context = this.key(), { cwd, on } = this.loc;
    if (context !== this.context) { this.context = context; this.reset(); }
    if (!cwd) return;
    this.loading = true; this.dirty = false;
    cx.spawn(async (cx) => {
      try {
        const top = await readGit({root:cwd,on},["rev-parse", "--show-toplevel"]);
        if (this.key() !== context) return;
        if (top.code !== 0) { this.root = null; this.staged = []; this.changes = []; this.conflicts = []; this.branch = null; this.originBase=null; this.error = "Not a git repository"; return; }
        const root = top.stdout.trim(), git = (args) => readGit({root,on},args);
        const status = await git(["status", "--porcelain=v1", "-z", "-b", "--no-renames", "--untracked-files=all"]);
        if (status.code !== 0) throw new Error(status.stderr);
        const head = await git(["rev-parse", "--verify", "HEAD"]);
        const numstat = async (args) => {
          const r = await git(["diff", ...args, "--numstat", "-z", "--no-renames"]);
          if (r.code !== 0) throw new Error(r.stderr);
          return G.parseNumstat(r.stdout);
        };
        const parsed = G.parseStatus(status.stdout, await numstat(["--cached"]), await numstat([]));
        if(parsed.branch && !parsed.branch.detached){
          const target=await branchTarget(async args=>{const r=await git(args);if(r.code!==0)throw new Error(r.stderr);return r.stdout;},parsed.branch.name);
          parsed.branch.upstream=target?.label??null;
        }
        let originBase=null;
        try {originBase=await resolveOrigin(async args=>{const r=await git(args);if(r.code!==0)throw new Error(r.stderr);return r.stdout;},"origin");}catch { /* No conventional origin base has been fetched yet. */ }
        if (this.key() !== context) return;
        this.originBase=originBase;
        this.root = root; this.on = on; this.hasHead = head.code === 0;
        Object.assign(this, { branch: parsed.branch, staged: parsed.staged, changes: parsed.changes, conflicts: parsed.conflicts, limited: parsed.limited, error: null });
        this.watch(root, cx);
        this.followPick();
      } catch (e) { if (this.key() === context) this.error = String(e); }
      finally {
        this.loading = false;
        if (this.dirty) this.refresh(cx);
        cx.notify();
      }
    });
  }

  // Staging moves a file between sections: keep the preview tab on it.
  followPick() {
    const space = spaces().find((s) => s.active), entry = space && shared(VIEW_KEY)?.[space.id];
    const shown = entry?.view?.file;
    if (!shown || (entry.view.comparison && entry.view.comparison!=="local") || entry.view.mode === "all" || entry.view.source?.root !== this.root) return;
    if (this.all.some((f) => f.group === shown.group && f.path === shown.path)) return;
    const moved = this.all.find((f) => f.path === shown.path);
    if (moved) updatePreview({ ...entry.view, file: { group: moved.group, path: moved.path, status: moved.status, fresh: moved.fresh } });
  }

  // --- opening ----------------------------------------------------------------------------------
  pick(f, clicks, cx) {
    if (!this.root) return;
    this.confirm = null;
    showDiff({ source: this.source(), mode: "file", file: { group: f.group, path: f.path, status: f.status, fresh: f.fresh } }, { pinned: clicks >= 2 });
    cx.notify();
  }
  compareOrigin(cx) { if(this.root&&this.originBase&&!this.busy&&!this.loading)showDiff({source:this.source(),mode:"all",comparison:this.originBase.name});cx.notify(); }
  openAll(cx) { if (this.root) showDiff({ source: this.source(), mode: "all" }); cx.notify(); }
  openFile(f) { if (this.root) openFileTab(this.source(), `${this.root}/${f.path}`); }
  openEditor(f, cx) { if (this.root) openInEditor(cx, this.source(), `${this.root}/${f.path}`, 1); }

  chooseBranch() {
    if(!this.root||this.busy||this.loading)return;
    openOverlay({mod:"tabbed-changes",kind:"dialog",width:520,height:420,props:{role:"branches",source:this.source()}});
  }
  fetch(cx) { this.work(cx,"Fetch",git=>git(["fetch","--no-tags","origin"],["GIT_TERMINAL_PROMPT=0"])); }

  // --- git writes -------------------------------------------------------------------------------
  // Runs git writes one after another, then refreshes. Failures show under the list.
  work(cx, label, job) {
    if (!this.root || this.busy || this.context !== this.key()) return;
    const root = this.root, on = this.on, context = this.context;
    this.busy = label; this.note = null; this.confirm = null;
    const git = async (args, env = []) => {
      const r = env.length ? await exec("env", [...env, "git", ...G.WRITE, ...args], { cwd: root, on }) : await exec("git", [...G.WRITE, ...args], { cwd: root, on });
      if (r.code !== 0) throw new Error(G.tidy(r.stderr || r.stdout) || `git ${args[0]} failed`);
      return r;
    };
    cx.spawn(async (cx) => {
      try { await job(git); }
      catch (e) { if (this.key() === context) this.note = `${label} failed: ${e.message ?? e}`; }
      finally { invalidateRepository({root,on}); this.busy = null; this.refresh(cx); cx.notify(); }
    });
    cx.notify();
  }

  async paths(git, prefix, files) {
    const paths = files.map((f) => f.path);
    for (let i = 0; i < paths.length; i += G.CHUNK) await git([...prefix, "--", ...paths.slice(i, i + G.CHUNK)]);
  }

  stage(files, cx) { this.work(cx, "Stage", (git) => this.paths(git, ["add"], files)); }
  unstage(files, cx) {
    const prefix = this.hasHead ? ["reset", "-q"] : ["rm", "--cached", "-r", "-f", "-q"];
    this.work(cx, "Unstage", (git) => this.paths(git, prefix, files));
  }
  discard(files, cx) {
    this.work(cx, "Discard", async (git) => {
      const fresh = files.filter((f) => f.fresh), tracked = files.filter((f) => !f.fresh);
      if (tracked.length) await this.paths(git, ["checkout"], tracked);
      if (fresh.length) await this.paths(git, ["clean", "-fq"], fresh);
    });
  }
  commit(cx) {
    if (!this.message.trim() || !this.staged.length || this.busy || this.loading) return;
    const message = this.message.trim(), context = this.context;
    this.work(cx, "Commit", async (git) => {
      await git(["commit", "-m", message]);
      if (this.key() === context) { this.message = ""; this.input.set_value(""); }
    });
  }
  push(cx) {
    const b = this.branch;
    if (!b || b.detached) return;
    this.work(cx, "Push", git => pushCurrent(async args => (await git(args,["GIT_TERMINAL_PROMPT=0"])).stdout,{name:b.name,upstream:b.upstream}));
  }
  pull(cx) {
    const b=this.branch;if(!b||b.detached||!b.upstream)return;
    this.work(cx,"Pull",git=>pullCurrent(async args=>(await git(args,["GIT_TERMINAL_PROMPT=0"])).stdout,{name:b.name,upstream:b.upstream}));
  }

  // --- drawing ----------------------------------------------------------------------------------
  pill(id, label, t, onClick) {
    return div().id(id).h(20).px(8).flex_none().flex().items_center().rounded(5).cursor_pointer().bg(t.ansi1).text_color(t.background).text_size(11).font_semibold()
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .on_click((_e, cx) => { cx.stop_propagation(); onClick(cx); })
      .child(label);
  }

  statusColor(s, t) { return s === "A" || s === "U" ? t.ansi2 : s === "D" || s === "!" ? t.ansi1 : t.blocked; }

  fileRow(f, t, shown) {
    const parts = f.path.split("/"), name = parts.pop(), id = `${f.group}:${f.path}`;
    const selected = shown?.group === f.group && shown?.path === f.path && shown?.mode !== "all";
    const hovered = this.hover === id, confirming = this.confirm === id;
    const actions = [];
    if (confirming) {
      actions.push(this.pill(`ok-${id}`, f.fresh ? "Delete file" : "Discard", t, (cx) => this.discard([f], cx)));
    } else if (hovered) {
      if (f.status !== "D") {
        actions.push(iconButton(`nvim-${id}`, "terminal", t, (cx) => this.openEditor(f, cx), { title: "Open in Neovim" }));
        actions.push(iconButton(`open-${id}`, "file-open", t, () => this.openFile(f), { title: "Open file in a tab" }));
      }
      if (f.group === "changes") actions.push(iconButton(`discard-${id}`, "undo", t, (cx) => { this.confirm = id; cx.notify(); }, { title: "Discard changes" }));
      if (f.group === "staged") actions.push(iconButton(`unstage-${id}`, "minus", t, (cx) => this.unstage([f], cx), { title: "Unstage" }));
      else actions.push(iconButton(`stage-${id}`, "plus", t, (cx) => this.stage([f], cx), { title: "Stage" }));
    }
    return h_flex().id(`row-${id}`).h(26).flex_none().pl(22).pr(8).gap(6).items_center().rounded(6).cursor_pointer()
      .when(selected, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover))
      .on_hover((on, cx) => {
        if (on) this.hover = id;
        else { if (this.hover === id) this.hover = null; if (this.confirm === id) this.confirm = null; }
        cx.notify();
      })
      .on_click((e, cx) => this.pick(f, e.click_count ?? 1, cx))
      .child(fileIcon(f.path, 16))
      .child(h_flex().flex_1().min_w(0).overflow_hidden().gap(6)
        .child(div().max_w(220).min_w(24).truncate().text_color(f.status === "D" ? t.dim : t.foreground).child(name))
        .child(div().flex_1().min_w(0).truncate().text_size(11).text_color(t.dim).child(parts.join("/"))))
      .when(actions.length > 0, (e) => e.child(h_flex().flex_none().gap(2).children(actions)))
      .when(actions.length === 0 && (f.add > 0 || f.del > 0), (e) => e.child(h_flex().flex_none().gap(5).text_size(11)
        .when(f.add > 0, (r) => r.child(div().text_color(t.ansi2).child(`+${f.add}`)))
        .when(f.del > 0, (r) => r.child(div().text_color(t.ansi1).child(`−${f.del}`)))))
      .child(div().w(14).flex_none().text_right().text_size(11).font_semibold().text_color(this.statusColor(f.status, t)).child(f.status));
  }

  sectionHeader(section, files, t) {
    const id = section.id, closed = Boolean(this.collapsed[id]), all = `all:${id}`;
    const actions = [];
    if (this.confirm === all) {
      actions.push(this.pill(`ok-${all}`, "Discard all", t, (cx) => this.discard(files, cx)));
    } else {
      if (id === "changes") actions.push(iconButton("discard-all", "undo", t, (cx) => { this.confirm = all; cx.notify(); }, { title: "Discard all changes" }));
      if (id === "staged") actions.push(iconButton("unstage-all", "minus", t, (cx) => this.unstage(files, cx), { title: "Unstage all" }));
      else actions.push(iconButton(`stage-all-${id}`, "plus", t, (cx) => this.stage(files, cx), { title: "Stage all" }));
    }
    return h_flex().id(`section-${id}`).h(26).flex_none().px(4).gap(4).items_center().rounded(6).cursor_pointer().hover((s) => s.bg(t.hover))
      .on_hover((on, cx) => { if (!on && this.confirm === all) { this.confirm = null; cx.notify(); } })
      .on_click((_e, cx) => { this.collapsed[id] = !closed; cx.notify(); })
      .child(icon(closed ? "chevron-right" : "chevron-down", 13).text_color(t.dim))
      .child(div().font_semibold().text_size(11).text_color(t.muted).child(section.title.toUpperCase()))
      .child(div().min_w(16).h(16).px(4).flex().items_center().justify_center().rounded(8).bg(t.raised).text_size(10).text_color(t.muted).child(String(files.length)))
      .child(div().flex_1())
      .child(h_flex().flex_none().gap(2).children(actions));
  }

  headerBar(t) {
    return h_flex().h(36).flex_none().px(10).gap(4).items_center().border_b(1).border_color(t.border)
      .child(div().flex_1().text_size(11).font_semibold().text_color(t.muted).child("SOURCE CONTROL"))
      .when(Boolean(this.root), e => e
        .child(iconButton("all-changes","file-diff",t,cx=>this.openAll(cx),{title:"Open all changes"}))
        .child(iconButton("refresh","refresh",t,cx=>this.refresh(cx),{title:"Refresh Source Control"})));
  }
  branchBar(t) {
    const b=this.branch;
    return h_flex().flex_none().px(10).py(6).gap(5).items_center().border_b(1).border_color(t.border)
        .child(h_flex().id("checkout-branch").flex_1().min_w(0).gap(5).items_center().cursor_pointer().rounded(3).hover(s=>s.bg(t.hover))
          .tooltip("Checkout branch…").on_click(()=>this.chooseBranch())
          .child(icon("branch",14).text_color(t.accent))
          .child(div().flex_1().min_w(0).truncate().child(b?.name??"Select repository"))
          .child(icon("chevron-down",12).text_color(t.dim)))
        .when(Boolean(this.root&&this.originBase),el=>el.child(toolButton("compare-default-branch","columns",this.originBase.name,t,cx=>this.compareOrigin(cx))
          .tooltip(`Review changes against ${this.originBase.name}`)))
        .when(Boolean(b?.upstream),el=>el.child(div().flex_none().text_size(11).text_color(t.muted).child(`↓${b.behind} ↑${b.ahead}`)));
  }

  remoteActions(t) {
    const b=this.branch,enabled=Boolean(b&&!b.detached&&this.hasHead&&!this.busy&&!this.loading);
    return h_flex().flex_none().px(10).py(6).gap(4).items_center().border_t(1).border_color(t.border)
        .child(iconButton("fetch","cloud",t,cx=>this.fetch(cx),{title:"Fetch origin"}))
        .child(iconButton("pull","arrow-down",t,cx=>{if(enabled&&b.upstream)this.pull(cx);},{color:enabled&&b?.upstream?t.muted:t.dim,title:b?.upstream?`Pull from ${b.upstream} (fast-forward only)`:"Pull requires an upstream branch"}))
        .child(h_flex().id("push-branch").h(24).px(6).gap(5).flex_1().min_w(0).items_center().rounded(3)
          .bg(t.raised).text_color(enabled?t.accent:t.dim).when(enabled,e=>e.cursor_pointer()).hover(s=>s.bg(t.hover))
          .tooltip(b?.upstream?`Push ${b.name} to ${b.upstream}`:`Publish ${b?.name??"branch"} to origin`)
          .on_click((_e,cx)=>{if(enabled)this.push(cx);})
          .child(icon(b?.upstream?"arrow-up":"cloud-upload",13))
          .child(div().flex_1().min_w(0).truncate().text_size(11).child(this.busy?`${this.busy}…`:b?.upstream?"Push":"Publish branch")));
  }

  commitBox(t) {
    const count = this.staged.length;
    const enabled = Boolean(this.message.trim() && count > 0 && this.root && !this.busy && !this.loading);
    const label = this.busy === "Commit" ? "Committing…" : count ? `Commit ${count} staged` : "Commit";
    return v_flex().flex_none().p(10).gap(8).border_b(1).border_color(t.border)
      .child(div().id("commit-message").w_full().px(10).py(6).rounded(8).border_1().border_color(this.typing ? t.accent : t.border).cursor_text()
        .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
        .child(Textarea.new(this.input).w_full().text_size(12).text_color(t.foreground)))
      .child(div().id("commit").w_full().h(30).flex().items_center().justify_center().rounded(8)
        .bg(enabled ? t.solid : t.raised).text_color(enabled ? t.solid_foreground : t.dim).text_size(12).font_semibold()
        .when(enabled, (e) => e.cursor_pointer()).on_click((_e, cx) => this.commit(cx)).child(icon("check",13)).child(div().ml(5).child(label)))
      .when(Boolean(this.message.trim()) && !count && Boolean(this.root) && !this.loading, (e) => e.child(div().text_size(11).text_color(t.dim).child("Stage changes with + to commit them")));
  }

  commentsBar(t, space) {
    const count = commentsFor(this.source()).length;
    return div().flex_none().px(8).py(6).border_t(1).border_color(t.border)
      .child(h_flex().id("open-review-comments").w_full().h(30).px(8).gap(7).items_center().rounded(5)
        .cursor_pointer().bg(t.raised).hover(style => style.bg(t.hover))
        .on_click(() => openOverlay({
          mod: "tabbed-changes", kind: "dialog", width: 580, height: 450,
          props: { role: "comments", source: this.source(), space },
        }))
        .child(icon("comment", 14).text_color(count ? t.accent : t.muted))
        .child(div().flex_1().font_semibold().text_size(12).child("Comments"))
        .child(div().min_w(19).px(5).rounded(8).bg(count ? t.selected : t.background)
          .text_center().text_size(11).text_color(count ? t.accent : t.muted).child(String(count))));
  }

  render(cx) {
    const event=shared(REPOSITORY_EVENT)??shared(BRANCH_EVENT);
    if(event && event.root===this.root && (event.on??null)===(this.on??null) && (event.version??event.at)!==this.lastBranchEvent){this.lastBranchEvent=event.version??event.at;invalidateReads();this.refresh(cx);}
    if (this.key() !== this.context) this.refresh(cx);
    const t = theme();
    const space = spaces().find((s) => s.active), entry = space && shared(VIEW_KEY)?.[space.id];
    const shown = entry?.view?.source?.root === this.root ? { ...entry.view.file, mode: entry.view.mode } : null;
    const visible = G.SECTIONS.map((s) => ({ ...s, files: this[s.id] })).filter((s) => s.files.length > 0);
    const list = v_flex().id("scm-list").flex_1().min_h(0).p(6).gap(2).overflow_y_scrollbar()
      .children(visible.flatMap((s) => [this.sectionHeader(s, s.files, t), ...(this.collapsed[s.id] ? [] : s.files.map((f) => this.fileRow(f, t, shown)))]))
      .when(!visible.length, (e) => e.child(div().p(8).text_color(t.dim).child(this.error || (this.loading ? "Loading changes…" : this.root ? "No uncommitted changes" : "No folder"))))
      .when(this.limited, (e) => e.child(div().px(8).py(4).text_size(11).text_color(t.dim).child(`Showing the first ${G.LIMIT.toLocaleString()} changed files`)));

    return v_flex().id("scm-panel").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13).track_focus(this.handle)
      .on_key_down((e, cx) => {
        if (e.key === "escape") {
          if (this.confirm) { this.confirm = null; cx.stop_propagation(); cx.notify(); }
          else if (this.typing) { this.typing = false; this.handle.focus(); cx.stop_propagation(); cx.notify(); }
        } else if (e.key === "enter" && (e.modifiers.platform || e.modifiers.control) && this.typing) {
          cx.stop_propagation(); this.commit(cx);
        }
      })
      .child(this.headerBar(t))
      .when(Boolean(this.root), e => e.child(this.branchBar(t)).child(this.commitBox(t)))
      .child(list)
      .when(Boolean(this.root), e => e.child(this.commentsBar(t, space?.id)).child(this.remoteActions(t)))
      .when(Boolean(this.note), (e) => e.child(div().px(10).py(6).border_t(1).border_color(t.border).text_size(11).text_color(t.ansi1).child(this.note)));
  }
}
