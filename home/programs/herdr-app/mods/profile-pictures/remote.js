// The picture lookup, apart from main.js so node can test it:
// node mods/profile-pictures/remote.test.mjs

// git@github.com:owner/repo.git, https://gitlab.com/group/sub/repo, ssh://git@host:22/a/b.git -> { host, path }
// The host goes to ssh and gh as an argument, so it can't start with "-".
export function parseRemote(url) {
  const m = /^(?:[a-z+]+:\/\/)?(?:[^@/]+@)?(\w[\w.-]*)(?::\d+)?[:/](.+?)(?:\.git)?\/?$/i.exec(url.trim());
  return m ? { host: m[1].toLowerCase(), path: m[2].replace(/^\/+/, "") } : null;
}

// SSH over port 443 has a host of its own; the pictures are on the main one.
const SSH_HOSTS = { "ssh.github.com": "github.com", "altssh.gitlab.com": "gitlab.com" };

// An ssh remote's real host, from `ssh -G <host>` (a Host alias in ~/.ssh/config names another).
export function realHost(host, sshConfig) {
  const h = /^hostname\s+(\S+)/m.exec(sshConfig ?? "")?.[1].toLowerCase() ?? host;
  return SSH_HOSTS[h] ?? h;
}

// A GitHub host's REST API: github.com, Enterprise Cloud with data residency (*.ghe.com), else Enterprise Server.
export function apiBase(host) {
  if (host === "github.com") return "https://api.github.com/";
  return host.endsWith(".ghe.com") ? `https://api.${host}/` : `https://${host}/api/v3/`;
}

// A repo's picture: { id, sources }, or null. `id` names the cached file. `sources`, tried in
// order: { url } anyone may download, { url, gh: true } fetched through gh, which adds the
// person's login for the URL's host. GitHub first (any host whose name doesn't say gitlab), then GitLab.
// `upstream`: a fork shows the owner of the repo it was forked from. `exec` runs programs here.
export async function pictureFor({ host, path }, upstream, exec) {
  if (!host.includes("gitlab")) {
    const repo = await githubRepo(host, path, exec);
    if (repo?.owner?.login) {
      const owner = (upstream && repo.parent?.owner) || repo.owner;
      const url = `${owner.avatar_url}${owner.avatar_url.includes("?") ? "&" : "?"}s=64`;
      if (host === "github.com") return { id: `${host}_${owner.login}`, sources: [{ url }] };
      // Enterprise avatar URLs sit behind private mode: Server's avatars API (3.0+) takes the
      // login; a ghe.com avatar gets it from gh, which sends it only to that tenant.
      const gh = host.endsWith(".ghe.com") ? url : `${apiBase(host)}enterprise/avatars/u/${owner.id}?s=64`;
      return { id: `${host}_${owner.login}`, sources: [{ url: gh, gh: true }, { url }] };
    }
    // No API answer (rate limit, a private repo without gh): github.com serves any owner's picture.
    const owner = path.split("/")[0];
    if (host === "github.com") return { id: `${host}_${owner}`, sources: [{ url: `https://github.com/${owner}.png?size=64` }] };
  }
  const project = await json(exec, `https://${host}/api/v4/projects/${encodeURIComponent(path)}`);
  const from = (upstream && project?.forked_from_project) || project;
  const url = from?.avatar_url || from?.namespace?.avatar_url;
  // A group's avatar can come as a path on the host.
  return url ? { id: `${host}_${from.path_with_namespace}`, sources: [{ url: url.startsWith("/") ? `https://${host}${url}` : url }] } : null;
}

// gh first: the person's login reaches private repos and private-mode servers.
async function githubRepo(host, path, exec) {
  const r = await exec("gh", ["api", "--hostname", host, `repos/${path}`]).catch(() => null);
  if (r?.code === 0) {
    try {
      return JSON.parse(r.stdout);
    } catch {}
  }
  return json(exec, `${apiBase(host)}repos/${path}`);
}

async function json(exec, url) {
  const r = await exec("curl", ["-fsSL", "--max-time", "15", url]);
  try {
    return r.code === 0 ? JSON.parse(r.stdout) : null;
  } catch {
    return null;
  }
}
