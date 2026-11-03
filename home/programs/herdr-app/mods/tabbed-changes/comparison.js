import {diffFlags} from "./review-model.js";
// Remote comparison helpers use explicit remote-tracking refs and immutable commit IDs.
export async function resolveOrigin(git, requested='origin') {
  if(!['origin','origin/main','origin/master'].includes(requested))throw new Error('Unsupported comparison target.');
  let names=requested==='origin'?['origin/main','origin/master']:[requested];
  if(requested==='origin') {
    try {
      const preferred=(await git(['symbolic-ref','--quiet','refs/remotes/origin/HEAD'])).trim().replace(/^refs\/remotes\//,'');
      if(names.includes(preferred))names=[preferred,...names.filter(n=>n!==preferred)];
    } catch { /* No advertised default: prefer main, then master. */ }
  }
  for(const name of names) {
    try {
      const sha=(await git(['rev-parse','--verify',`refs/remotes/${name}^{commit}`])).trim();
      if(/^[0-9a-f]{40,64}$/.test(sha))return {name,sha};
    } catch { /* Try the other conventional default branch. */ }
  }
  throw new Error(requested==='origin'?'No origin/main or origin/master reference. Use Fetch origin, or configure the origin remote.':`${requested} is unavailable. Use Fetch origin or choose the other branch.`);
}

export async function resolveReviewBase(git, requested) {
  const remote = await resolveOrigin(git, requested);
  try {
    const sha = (await git(['merge-base', 'HEAD', remote.sha])).trim();
    return { name: remote.name, sha };
  } catch (error) {
    throw new Error(`Could not find a shared commit with ${remote.name}: ${error.message}`);
  }
}

export function comparisonArgs(sha,path,options={}) {
  if(!/^[0-9a-f]{40,64}$/.test(sha))throw new Error('Invalid comparison commit.');
  return ['diff','--no-ext-diff','--no-textconv','--no-color','--no-renames',...diffFlags(options),sha,'--',...(path?[path]:[])];
}
