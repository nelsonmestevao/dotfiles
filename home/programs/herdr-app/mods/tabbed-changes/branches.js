// Git branch operations shared by the picker and Source Control actions.
export async function currentBranch(git) {
  let ref=null,sha=null;
  try{ref=(await git(['symbolic-ref','--quiet','HEAD'])).trim();}catch{}
  try{sha=(await git(['rev-parse','--verify','HEAD'])).trim();}catch{}
  return {ref,name:ref?.startsWith('refs/heads/')?ref.slice(11):null,sha};
}
export async function listBranches(git) {
  const remotes=(await git(['remote'])).trim().split('\n').filter(Boolean).sort((a,b)=>b.length-a.length);
  const text=await git(['for-each-ref','--sort=-committerdate','--format=%(refname)%09%(HEAD)%09%(upstream)%09%(worktreepath)%09%(symref)','refs/heads/','refs/remotes/']);
  return text.trimEnd().split('\n').filter(Boolean).flatMap(line=>{
    const [ref,head,upstream,worktree,symref]=line.split('\t');if(symref)return [];
    const kind=ref.startsWith('refs/heads/')?'local':'remote';
    const name=ref.slice(kind==='local'?11:13);
    const remote=kind==='remote'?remotes.find(r=>name.startsWith(`${r}/`)):null;
    if(kind==='remote'&&!remote)return [];
    return [{ref,name,kind,current:head==='*',upstream:upstream||null,worktree:worktree||null,remote:remote??null,localName:kind==='remote'?name.slice(remote.length+1):name}];
  });
}
export async function switchBranch(git,selected,expected) {
  const current=await currentBranch(git);
  if(current.ref!==expected.ref || current.sha!==expected.sha)throw new Error('The current branch changed. Refresh the branch picker and try again.');
  const branches=await listBranches(git),branch=branches.find(b=>b.ref===selected.ref);
  if(!branch)throw new Error('That branch no longer exists. Refresh the picker.');
  if(branch.current)return;
  if(branch.kind==='local') {
    if(branch.worktree)throw new Error('This branch is checked out in another worktree.');
    await git(['switch','--no-guess','--',branch.name]);
  } else {
    const local=branches.find(b=>b.kind==='local'&&b.name===branch.localName);
    if(local) {
      if(local.upstream!==branch.ref)throw new Error(`Local branch ${branch.localName} already exists with a different upstream. Choose the local branch explicitly.`);
      if(local.worktree&&!local.current)throw new Error('This branch is checked out in another worktree.');
      await git(['switch','--no-guess','--',local.name]);
    } else {
      await git(['check-ref-format','--branch',branch.localName]);
      await git(['switch','--track','--create',branch.localName,'--',branch.ref]);
    }
  }
}
export const BRANCH_EVENT='tabbed-changes.branch-changed';
export async function branchTarget(git,name) {
  const config=async key=>{try{return (await git(['config','--get',key])).trim();}catch{return null;}};
  const remote=await config(`branch.${name}.remote`),merge=await config(`branch.${name}.merge`);
  if(Boolean(remote)!==Boolean(merge))throw new Error('The branch upstream is incomplete. Configure it before continuing.');
  if(merge&&!merge.startsWith('refs/heads/'))throw new Error('The upstream must be a branch.');
  return remote?{remote,ref:merge,label:remote==='.'?merge.slice(11):`${remote}/${merge.slice(11)}`} : null;
}
async function checkedTarget(git,expected,action) {
  const current=await currentBranch(git),name=typeof expected==='string'?expected:expected?.name;
  if(!current.name)throw new Error(`Check out a branch before ${action}.`);
  if(current.name!==name)throw new Error('The current branch changed. Refresh Source Control before continuing.');
  const target=await branchTarget(git,current.name);
  if(typeof expected==='object' && (target?.label??null)!==(expected?.upstream??null))throw new Error('The upstream changed. Refresh Source Control before continuing.');
  return {current,target};
}
export async function pushCurrent(git,expected) {
  const {current,target}=await checkedTarget(git,expected,'pushing');
  if(!current.sha)throw new Error('Create a commit before publishing this branch.');
  await git(['push','--no-follow-tags','--recurse-submodules=no',...(!target?['--set-upstream']:[]),'--',target?.remote??'origin',`${current.ref}:${target?.ref??current.ref}`]);
}
export async function pullCurrent(git,expected) {
  const {target}=await checkedTarget(git,expected,'pulling');
  if(!target)throw new Error('Set an upstream branch before pulling.');
  await git(['pull','--ff-only','--no-rebase','--no-autostash','--',target.remote,target.ref]);
}
