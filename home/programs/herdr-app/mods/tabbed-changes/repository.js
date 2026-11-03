import {exec,shared,setShared} from 'herdr';
import {READ} from './git.js';
import {ReadCache} from './read-cache.js';
export const REPOSITORY_EVENT='tabbed-changes.repository-changed';
const reads=new ReadCache();
export const invalidateReads=()=>reads.invalidate();
export function invalidateRepository(source) {
  invalidateReads();setShared(REPOSITORY_EVENT,{root:source.root,on:source.on??null,version:`${Date.now()}-${Math.random()}`});
}
export function readGit(source,args) {
  const event=shared(REPOSITORY_EVENT);
  const version=event?.root===source.root && (event.on??null)===(source.on??null)?event.version:null;
  const key=JSON.stringify([source.root,source.on??null,version,args]);
  return reads.read(key,()=>exec('git',[...READ,...args],{cwd:source.root,on:source.on??null}));
}
