// Bounded pure helpers: presentation never changes the underlying review snapshot.
export function diffFlags(options={}) {
  return [`--unified=${[3,10,30].includes(options.context)?options.context:3}`,...(options.ignoreWhitespace?['--ignore-all-space']:[])];
}
const segments=text=>[...text.matchAll(/\s+|[A-Za-z0-9_$]+|[^A-Za-z0-9_$\s]/gu)].map(m=>({text:m[0],start:m.index,end:m.index+m[0].length}));
const mergeSpans=items=>{
  const out=[];for(const item of items){const last=out[out.length-1];if(last?.end===item.start)last.end=item.end;else out.push({start:item.start,end:item.end});}return out;
};
export function wordChanges(oldText,newText) {
  if(oldText===newText)return {old:[],next:[]};
  const whole=()=>({old:oldText?[{start:0,end:oldText.length}]:[],next:newText?[{start:0,end:newText.length}]:[]});
  if(oldText.length>8000||newText.length>8000)return whole();
  const a=segments(oldText),b=segments(newText),n=a.length,m=b.length;
  if(n>160||m>160||n*m>16000)return whole();
  const table=Array.from({length:n+1},()=>new Uint16Array(m+1));
  for(let i=n-1;i>=0;i--)for(let j=m-1;j>=0;j--)table[i][j]=a[i].text===b[j].text?table[i+1][j+1]+1:Math.max(table[i+1][j],table[i][j+1]);
  const removed=[],added=[];let i=0,j=0;
  while(i<n||j<m){
    if(i<n&&j<m&&a[i].text===b[j].text){i++;j++;}
    else if(i<n&&(j===m||table[i+1][j]>=table[i][j+1]))removed.push(a[i++]);
    else added.push(b[j++]);
  }
  return {old:mergeSpans(removed),next:mergeSpans(added)};
}
export function splitTokens(tokens,spans=[]) {
  if(!spans.length)return tokens;
  const out=[];let at=0;
  for(const token of tokens){
    const end=at+token.text.length,edges=[at,end];
    for(const span of spans)if(span.end>at&&span.start<end){edges.push(Math.max(at,span.start),Math.min(end,span.end));}
    const sorted=[...new Set(edges)].sort((a,b)=>a-b);
    for(let i=0;i<sorted.length-1;i++)out.push({...token,text:token.text.slice(sorted[i]-at,sorted[i+1]-at),changed:spans.some(s=>s.start<sorted[i+1]&&s.end>sorted[i])});
    at=end;
  }
  return out;
}
export const changedTargets=rows=>rows.flatMap((row,i)=>row.kind==='@'?[i]:[]);
export function searchRows(rows,query) {
  const text=query.trim().toLowerCase();if(!text)return [];
  return rows.flatMap((r,i)=>`${r.path??''}\n${r.text??''}\n${r.l?.text??''}\n${r.r?.text??''}`.toLowerCase().includes(text)?[i]:[]);
}
export function stepTarget(indices,current,direction) {
  if(!indices.length)return null;
  return direction>0?(indices.find(i=>i>current)??indices[0]):(indices.slice().reverse().find(i=>i<current)??indices[indices.length-1]);
}
export function fileTree(files,query='',collapsed=new Set()) {
  const root=new Map(),filter=query.toLowerCase();
  for(const file of files){
    if(filter&&!file.path.toLowerCase().includes(filter))continue;
    const parts=file.path.split('/');let children=root,path='';
    for(let i=0;i<parts.length;i++){
      path=path?`${path}/${parts[i]}`:parts[i];const kind=i===parts.length-1?'file':'folder',key=`${kind}:${path}`;
      if(!children.has(key))children.set(key,{kind,path,name:parts[i],children:new Map(),file});
      children=children.get(key).children;
    }
  }
  const out=[];function flatten(children,depth){
    for(const node of [...children.values()].sort((a,b)=>a.kind===b.kind?a.name.localeCompare(b.name):a.kind==='folder'?-1:1)){
      out.push({kind:node.kind,path:node.path,name:node.name,depth,file:node.file,closed:!filter&&collapsed.has(node.path)});
      if(node.kind==='folder'&&(filter||!collapsed.has(node.path)))flatten(node.children,depth+1);
    }
  }flatten(root,0);return out;
}
// Keep a comment opened after horizontal panning inside the visible content viewport.
export function commentPlacement(contentLeft,viewportLeft,contentWidth,viewportWidth) {
  const inset=Math.min(Math.max(0,viewportLeft-contentLeft),Math.max(0,contentWidth-viewportWidth));
  return {inset,width:Math.max(40,Math.min(600,viewportWidth,contentWidth-inset))};
}

// Leave room for the scrollbar, match marker and variation in monospace fonts.
export function wrapColumns(width, gutter, fontSize) {
  return Math.max(4, Math.floor((width - gutter - 14) / (fontSize * 0.70)));
}

// Break at whitespace when possible, and within long words when necessary.
// Offsets refer to the original text so token colors and comment snapshots survive.
export function wrapBreaks(text, columns) {
  if (!text || !columns) return null;
  let start = 0, offset = 0, used = 0, space = 0;
  const breaks = [];
  while (offset < text.length) {
    const point = text.codePointAt(offset);
    const size = point === 9 ? 4 : point >= 0x2e80 ? 2 : 1;
    if (used + size > columns && offset > start) {
      offset = start = space > start ? space : offset;
      breaks.push(start);
      used = 0;
      continue;
    }
    offset += point > 0xffff ? 2 : 1;
    used += size;
    if (point === 32 || point === 9) space = offset;
  }
  return breaks.length ? breaks : null;
}

export function wrapTokens(tokens, breaks) {
  if (!breaks) return [tokens];
  const rows = [[]];
  let offset = 0, index = 0;
  for (const token of tokens) {
    const end = offset + token.text.length;
    let start = 0;
    while (breaks[index] <= end) {
      const cut = breaks[index++] - offset;
      if (cut > start) rows.at(-1).push({ ...token, text: token.text.slice(start, cut) });
      rows.push([]);
      start = cut;
    }
    if (start < token.text.length) rows.at(-1).push({ ...token, text: token.text.slice(start) });
    offset = end;
  }
  return rows;
}
