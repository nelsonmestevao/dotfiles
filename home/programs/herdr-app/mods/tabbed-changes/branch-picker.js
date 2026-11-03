import { div } from 'gpui-kit';
import { v_flex,h_flex,InputState,Input,v_virtual_list,Scrollbar } from 'gpui-base';
import { props,exec,theme,closeOverlay,setShared } from 'herdr';
import { invalidateRepository } from "./repository.js";
import { READ,tidy } from './git.js';
import { currentBranch,listBranches,switchBranch,BRANCH_EVENT } from './branches.js';
import { icon,iconButton } from './ui.js';
const ROW=34;
export class BranchPicker {
  init(cx) {
    const p=props()??{};this.source=p.source;this.overlay=p.overlay;this.branches=[];this.search='';this.loading=false;this.busy=false;
    this.input=InputState.new({placeholder:'Search local and remote branches…'});
    this.input.on('change',(_e,cx)=>{this.search=this.input.value();cx.notify();});
    this.input.focus();this.refresh(cx);
  }
  async git(args,read=false) {
    if(!this.source?.root)throw new Error('No repository selected.');
    const r=await exec('env',['GIT_TERMINAL_PROMPT=0','git',...(read?READ:[]),...args],{cwd:this.source.root,on:this.source.on??null});
    if(r.code!==0)throw new Error(tidy(r.stderr||r.stdout)||'Git command failed.');
    return r.stdout;
  }
  refresh(cx) {
    if(this.loading||this.busy)return;this.loading=true;this.error=null;cx.notify();
    cx.spawn(async cx=>{
      try {
        this.expected=await currentBranch(args=>this.git(args,true));
        this.branches=(await listBranches(args=>this.git(args,true))).sort((a,b)=>Number(b.current)-Number(a.current)||(a.kind===b.kind?0:a.kind==='local'?-1:1));
      }catch(e){this.error=String(e.message??e);}
      finally{this.loading=false;cx.notify();}
    });
  }
  choose(ref,cx) {
    if(this.loading||this.busy)return;
    const branch=this.branches.find(b=>b.ref===ref);if(!branch)return;
    if(branch.current){closeOverlay(this.overlay);return;}
    this.busy=true;this.error=null;cx.notify();
    cx.spawn(async cx=>{
      try {await switchBranch(args=>this.git(args),branch,this.expected);invalidateRepository(this.source);setShared(BRANCH_EVENT,{...this.source,at:Date.now()});closeOverlay(this.overlay);}
      catch(e){this.error=String(e.message??e);}
      finally{this.busy=false;cx.notify();}
    });
  }
  close(){this.input.release();}
  render(cx) {
    const t=theme(),query=this.search.toLowerCase();
    const shown=this.branches.filter(b=>b.name.toLowerCase().includes(query));
    const list=v_virtual_list('branch-picker-list',shown.length,ROW,i=>shown[i].ref,range=>shown.slice(range.start,range.end).map(b=>
      h_flex().h(ROW).w_full().px(10).gap(8).items_center().bg(b.current?t.selected:t.surface)
        .child(icon(b.kind==='remote'?'cloud':'branch',14).text_color(t.muted))
        .child(div().flex_1().min_w(0).truncate().child(b.name))
        .child(div().flex_none().text_size(11).text_color(t.dim).child(b.current?'✓ current':b.worktree?'in worktree':b.kind==='remote'?'remote':'local'))))
      .on_item_click((key,cx)=>this.choose(key,cx)).size_full();
    return v_flex().size_full().min_h(0).p(12).gap(8).bg(t.surface).text_color(t.foreground).text_size(13)
      .child(h_flex().items_center().gap(6)
        .child(div().flex_1().font_semibold().child(this.busy?'Switching branch…':'Checkout branch'))
        .child(iconButton('branches-refresh','refresh',t,cx=>this.refresh(cx),{title:'Refresh branches'}))
        .child(iconButton('branches-close','minus',t,()=>{if(!this.busy)closeOverlay(this.overlay);},{title:'Close'})))
      .child(div().text_size(11).text_color(t.dim).truncate().child(this.source?.root??''))
      .child(Input.new(this.input).h(30).px(8).border(1).border_color(t.input).rounded(4).bg(t.background))
      .when(Boolean(this.error),el=>el.child(div().text_size(12).text_color(t.ansi1).child(this.error)))
      .child(div().flex_1().min_h(0).relative().child(list).child(Scrollbar.vertical('branch-picker-list').viewport_from_layout().absolute().inset_0()))
      .when(!shown.length,el=>el.child(div().text_color(t.dim).child(this.loading?'Loading branches…':'No matching branches')))
      .child(div().text_size(11).text_color(t.dim).child('Local: switch branch · Remote: create a local tracking branch'));
  }
}
