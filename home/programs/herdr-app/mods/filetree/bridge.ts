#!/usr/bin/env bun
// Claude Code hook -> herdr filetree mod. Appends one JSON line per file activity to
// ~/.local/state/herdr-filetree/activity.jsonl; the mod watches that folder.
// Command parsing is a trimmed port of claude-code-filetree's hooks/git.ts (MIT, Kurt Buhler).
import { appendFileSync, mkdirSync, readFileSync, statSync, writeFileSync } from "fs";
import { spawnSync } from "child_process";

const HOME = process.env.HOME ?? "";
const DIR = `${HOME}/.local/state/herdr-filetree`;
const FILE = `${DIR}/activity.jsonl`;
const KEEP = 400;

type Action = { verb: string; running: string; done: string; tone: string };

const GIT: Record<string, Omit<Action, "verb">> = {
  commit: { running: "committing", done: "committed", tone: "green" },
  push: { running: "pushing", done: "pushed", tone: "teal" },
  pull: { running: "pulling", done: "pulled", tone: "blue" },
  fetch: { running: "fetching", done: "fetched", tone: "blue" },
  checkout: { running: "checking out", done: "checked out", tone: "blue" },
  switch: { running: "switching", done: "switched", tone: "blue" },
  branch: { running: "branching", done: "branched", tone: "blue" },
  merge: { running: "merging", done: "merged", tone: "purple" },
  rebase: { running: "rebasing", done: "rebased", tone: "purple" },
  "cherry-pick": { running: "cherry-picking", done: "cherry-picked", tone: "purple" },
  stash: { running: "stashing", done: "stashed", tone: "orange" },
  reset: { running: "resetting", done: "reset", tone: "red" },
  restore: { running: "restoring", done: "restored", tone: "red" },
  revert: { running: "reverting", done: "reverted", tone: "red" },
  add: { running: "staging", done: "staged", tone: "green" },
  rm: { running: "removing", done: "removed", tone: "red" },
  mv: { running: "moving", done: "moved", tone: "orange" },
  tag: { running: "tagging", done: "tagged", tone: "purple" },
  init: { running: "initialising", done: "initialised", tone: "green" },
  clone: { running: "cloning", done: "cloned", tone: "blue" },
};
const GH: Record<string, Omit<Action, "verb">> = {
  "pr create": { running: "opening PR", done: "opened PR", tone: "purple" },
  "pr merge": { running: "merging PR", done: "merged PR", tone: "purple" },
  "pr checkout": { running: "checking out PR", done: "checked out PR", tone: "blue" },
  "pr comment": { running: "commenting on PR", done: "commented on PR", tone: "purple" },
  "pr review": { running: "reviewing PR", done: "reviewed PR", tone: "purple" },
  "repo clone": { running: "cloning", done: "cloned", tone: "blue" },
  "release create": { running: "releasing", done: "released", tone: "purple" },
  "issue create": { running: "opening issue", done: "opened issue", tone: "purple" },
};
const READ_ONLY_GIT = new Set(["status", "log", "diff", "show", "blame", "rev-parse", "ls-files", "grep", "describe", "config", "remote", "reflog", "shortlog", "help", "version", "check-ignore"]);
const READERS = new Set(["rg", "grep", "egrep", "fgrep", "find", "fd", "fdfind", "cat", "head", "tail", "bat", "less", "more", "ls", "eza", "tree", "wc", "sed", "awk", "jq"]);
const PATTERN_FIRST = new Set(["rg", "grep", "egrep", "fgrep", "sed", "awk", "jq"]);
const OUTPUT_PATHS = new Set(["rg", "grep", "egrep", "fgrep", "find", "fd", "fdfind"]);
const WRITE_FLAGS = /^-(delete|exec|execdir|ok|okdir|fprint\w*|fls|x|X|-exec|-exec-batch)$/;

function segments(command: string): string[][] {
  const out: string[][] = [];
  let cur: string[] = [], tok = "", quote = "", has = false;
  const endTok = () => { if (has) cur.push(tok); tok = ""; has = false; };
  const endSeg = () => { endTok(); if (cur.length) out.push(cur); cur = []; };
  for (let i = 0; i < command.length; i++) {
    const ch = command[i];
    if (quote) {
      if (ch === quote) quote = "";
      else if (ch === "\\" && quote === '"' && i + 1 < command.length) tok += command[++i];
      else tok += ch;
    } else if (ch === '"' || ch === "'") { quote = ch; has = true; }
    else if (ch === "\\" && i + 1 < command.length) { tok += command[++i]; has = true; }
    else if (ch === "#" && !has) { while (i + 1 < command.length && command[i + 1] !== "\n") i++; }
    else if (ch === " " || ch === "\t") endTok();
    else if (ch === "\n" || ch === ";") endSeg();
    else if (ch === "&" && (command[i - 1] === ">" || command[i + 1] === ">")) { tok += ch; has = true; }
    else if (ch === "&" || ch === "|") { if (command[i + 1] === ch) i++; endSeg(); }
    else { tok += ch; has = true; }
  }
  endSeg();
  if (!quote) return out;
  return command.split(/&&|\|\||;|\||\n/).map(s => s.trim().split(/\s+/).filter(Boolean)).filter(s => s.length > 0);
}

function stripGlobals(tokens: string[]): string[] {
  const out = [...tokens];
  if (out[0] === "env") out.shift();
  while (out.length && /^[A-Z_][A-Z0-9_]*=/.test(out[0])) out.shift();
  return out;
}

function gitVerb(tokens: string[]): number {
  let i = 1;
  while (i < tokens.length && tokens[i].startsWith("-")) { if (tokens[i] === "-C" || tokens[i] === "-c") i++; i++; }
  return i;
}

function gitReadOnly(verb: string, rest: string[]): boolean {
  if (!verb || READ_ONLY_GIT.has(verb)) return true;
  if (verb === "stash") return ["list", "show"].includes(rest[0] ?? "");
  if (verb === "branch") return rest.every(t => t.startsWith("-"));
  if (verb === "tag") return rest.length === 0 || rest.some(t => /^(-l|--list|-n\d*|--contains|--points-at|--merged|--no-merged|-v|--verify)$/.test(t));
  return false;
}

function gitActions(command: string): Action[] {
  const out: Action[] = [];
  for (const raw of segments(command)) {
    const tokens = stripGlobals(raw), head = tokens[0]?.split("/").pop();
    if (head === "git") {
      const i = gitVerb(tokens), verb = tokens[i] ?? "", rest = tokens.slice(i + 1);
      if (gitReadOnly(verb, rest)) continue;
      const spec = verb === "checkout" && rest.includes("--") ? GIT.restore : GIT[verb];
      if (spec) out.push({ verb: `git ${verb}`, ...spec });
    } else if (head === "gh") {
      const pair = `${tokens[1] ?? ""} ${tokens[2] ?? ""}`;
      if (GH[pair]) out.push({ verb: `gh ${pair}`, ...GH[pair] });
    }
  }
  return out;
}

function resolve(cwd: string, p: string): string {
  let path = p;
  if (path === "~" || path.startsWith("~/")) path = HOME + path.slice(1);
  const parts = path.startsWith("/") ? [""] : cwd.replace(/\/+$/, "").split("/");
  for (const seg of path.split("/")) {
    if (!seg || seg === ".") continue;
    if (seg === "..") { if (parts.length > 1) parts.pop(); } else parts.push(seg);
  }
  return parts.join("/") || "/";
}

function readOnly(command: string): boolean {
  const bare = ` ${command}`.replace(/\d*>&\d/g, " ").replace(/(\d*|&)>>?\s*\/dev\/null/g, " ");
  if (/[^>]>[^>&]|>>/.test(bare)) return false;
  return segments(command).every(raw => {
    const tokens = stripGlobals(raw), head = tokens[0]?.split("/").pop() ?? "";
    if (["cd", "echo", "printf", "true", "pwd"].includes(head)) return true;
    if (head === "git") { const i = gitVerb(tokens); return gitReadOnly(tokens[i] ?? "", tokens.slice(i + 1)); }
    if (head === "sed") return !tokens.some(t => /^-i/.test(t));
    if (head === "find" || head === "fd" || head === "fdfind") return !tokens.some(t => WRITE_FLAGS.test(t));
    return READERS.has(head);
  });
}

function readTargets(command: string, start: string, stdout: string): string[] {
  let cwd = start, listsPaths = false;
  const out = new Set<string>();
  for (const raw of segments(command)) {
    const tokens = stripGlobals(raw).map(t => t.replace(/^["']|["']$/g, ""));
    const head = tokens[0]?.split("/").pop() ?? "";
    if (head === "cd" && tokens[1]) { cwd = resolve(cwd, tokens[1]); continue; }
    if (!READERS.has(head) || (head === "sed" && tokens.some(t => /^-i/.test(t)))) continue;
    if (OUTPUT_PATHS.has(head)) listsPaths = true;
    const args = tokens.slice(1);
    let skipPattern = PATTERN_FIRST.has(head) && !args.some(t => t === "-e" || t === "-f" || t === "--files");
    for (let i = 0; i < args.length; i++) {
      const a = args[i];
      if (a.startsWith("-")) { if (/^-(e|f|g|t|T|m|A|B|C|-glob|-type|-max-count|name|iname|maxdepth|mindepth)$/.test(a)) i++; continue; }
      if (skipPattern) { skipPattern = false; continue; }
      if (/[*?<>|]/.test(a)) continue;
      out.add(resolve(cwd, a));
    }
  }
  if (listsPaths) for (const line of stdout.split("\n").slice(0, 400)) {
    const path = line.match(/^([^:\0]+?)(?::\d+[:-]|$|:)/)?.[1]?.trim();
    if (path && !path.includes(" ")) out.add(resolve(cwd, path));
  }
  return [...out].slice(0, 60);
}

function git(cwd: string, args: string[]): string {
  const r = spawnSync("git", ["--no-optional-locks", ...args], { cwd, encoding: "utf8", timeout: 3000 });
  return r.status === 0 ? r.stdout.trim() : "";
}

function emit(events: Record<string, unknown>[]) {
  if (!events.length) return;
  mkdirSync(DIR, { recursive: true });
  appendFileSync(FILE, events.map(e => JSON.stringify(e)).join("\n") + "\n");
  try {
    if (statSync(FILE).size > 256 * 1024) writeFileSync(FILE, readFileSync(FILE, "utf8").trimEnd().split("\n").slice(-KEEP).join("\n") + "\n");
  } catch {}
}

try {
  const input = JSON.parse(await Bun.stdin.text());
  const hook: string = input.hook_event_name ?? "";
  const tool: string = input.tool_name ?? "";
  const ti = input.tool_input ?? {};
  const tr = input.tool_response ?? {};
  const cwd: string = input.cwd ?? process.cwd();
  const base = { at: Date.now(), cwd, session: input.session_id ?? "", id: input.tool_use_id ?? "" };
  const events: Record<string, unknown>[] = [];
  const abs = (p: unknown) => (typeof p === "string" && p ? resolve(cwd, p) : null);
  const list = (v: unknown) => (Array.isArray(v) ? v.map(abs).filter(Boolean).slice(0, 60) : []);

  if (hook === "UserPromptSubmit") {
    const paths = [...String(input.prompt ?? "").matchAll(/(?:^|\s)@([^\s@]+)/g)].map(m => abs(m[1].replace(/^["'`]|["'`),.;:?!]+$/g, ""))).filter(Boolean);
    if (paths.length) events.push({ ...base, kind: "mention", paths: paths.slice(0, 20) });
  } else if (hook === "PreToolUse" && tool === "Bash") {
    const command = String(ti.command ?? ""), actions = gitActions(command);
    if (!readOnly(command)) events.push({ ...base, kind: "bash-start" });
    if (actions.length) events.push({ ...base, kind: "git", state: "running", actions: actions.map(a => ({ verb: a.verb, label: a.running, tone: a.tone })) });
  } else if (hook === "PostToolUse" || hook === "PostToolUseFailure") {
    const ok = hook === "PostToolUse" && !tr.interrupted;
    if (tool === "Read") events.push({ ...base, kind: "read", paths: [abs(ti.file_path)].filter(Boolean) });
    else if (tool === "Grep" || tool === "Glob") {
      const hits = list(tr.filenames);
      events.push({ ...base, kind: "read", paths: hits.length ? hits : [abs(ti.path) ?? cwd] });
    } else if (["Write", "Edit", "MultiEdit", "NotebookEdit"].includes(tool)) {
      if (ok) events.push({ ...base, kind: "write", paths: [abs(ti.file_path ?? ti.notebook_path)].filter(Boolean) });
    } else if (tool === "Bash") {
      const command = String(ti.command ?? ""), actions = gitActions(command);
      const reads = readTargets(command, cwd, typeof tr.stdout === "string" ? tr.stdout : "");
      if (reads.length) events.push({ ...base, kind: "read", paths: reads });
      if (!readOnly(command)) events.push({ ...base, kind: "bash-end" });
      if (actions.length) {
        const commit = ok && actions.some(a => a.verb === "git commit");
        const detail = commit ? git(cwd, ["log", "-1", "--format=%h %s"]) : "";
        const top = commit ? git(cwd, ["rev-parse", "--show-toplevel"]) : "";
        const paths = commit && top ? git(cwd, ["show", "--name-only", "--format=", "HEAD"]).split("\n").filter(Boolean).slice(0, 60).map(p => `${top}/${p}`) : [];
        events.push({ ...base, kind: "git", state: ok ? "done" : "failed", detail, paths, actions: actions.map(a => ({ verb: a.verb, label: ok ? a.done : `${a.verb.replace(/^(git|gh) /, "")} failed`, tone: ok ? a.tone : "red" })) });
      }
    }
  }
  emit(events.filter(e => !Array.isArray(e.paths) || (e.paths as unknown[]).length || e.kind !== "read"));
} catch {}
process.exit(0);
