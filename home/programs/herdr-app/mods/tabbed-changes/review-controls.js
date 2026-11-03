// Controls are built during render; virtual rows only describe data and visuals.
import {div} from 'gpui-kit';
import {h_flex,v_flex,Input,v_virtual_list,Scrollbar} from 'gpui-base';
import {iconButton,toolButton,icon,fileIcon} from './ui.js';
export function reviewToolbar(view,t) {
  const moreContext = view.contextLines > 3;
  return h_flex().h(30).flex_none().px(8).gap(4).items_center().border_b(1).border_color(t.border)
    .when(view.mode==='all',el=>el.child(iconButton('toggle-files','file-tree',t,cx=>{view.showFiles=!view.showFiles;cx.notify();},{active:view.showFiles,title:'Changed file navigator'})))
    .child(iconButton('previous-change','arrow-up',t,cx=>view.moveChange(-1,cx),{title:'Previous change (Alt+Up)'}))
    .child(iconButton('next-change','arrow-down',t,cx=>view.moveChange(1,cx),{title:'Next change (Alt+Down)'}))
    .child(div().text_size(11).text_color(t.dim).child(`${view.changeIndices.length} changes`))
    .child(div().flex_1())
    .child(toolButton('word-highlights','columns','Words',t,cx=>{view.wordHighlight=!view.wordHighlight;cx.notify();},{active:view.wordHighlight}))
    .child(toolButton('ignore-whitespace','rows','Ignore spaces',t,cx=>view.setDiffOption('ignoreWhitespace',!view.ignoreWhitespace,cx),{active:view.ignoreWhitespace}))
    .child(toolButton('wrap-lines', 'rows', 'Wrap lines', t, cx => {
      view.wrapLines = !view.wrapLines;
      view.horizontalVersion++;
      view.commentPosition.inset = 0;
      cx.notify();
    }, { active: view.wrapLines }))
    .child(toolButton('context-lines', moreContext ? 'arrow-up' : 'arrow-down',
      moreContext ? 'Show fewer lines' : 'Show more lines', t,
      cx => view.setDiffOption('contextLines', moreContext ? 3 : 10, cx)))
    .child(toolButton('diff-search','search','Find',t,cx=>view.openSearch(cx),{active:view.searchOpen}));
}
export function searchBar(view,t) {
  return h_flex().h(34).flex_none().px(8).gap(5).items_center().border_b(1).border_color(t.border)
    .child(Input.new(view.searchInput).flex_1().min_w(0).h(26).px(6).bg(t.surface).border(1).border_color(t.input).rounded(3).text_size(12))
    .child(div().text_size(11).text_color(t.dim).child(view.searchQuery?`${view.matches.length} matches`:''))
    .child(iconButton('find-previous','arrow-up',t,cx=>view.moveMatch(-1,cx),{title:'Previous match (Shift+Enter)'}))
    .child(iconButton('find-next','arrow-down',t,cx=>view.moveMatch(1,cx),{title:'Next match (Enter)'}))
    .child(iconButton('find-close','minus',t,cx=>{view.searchOpen=false;view.searchInput.set_value('');view.handle.focus();cx.notify();},{title:'Close search'}));
}
export function fileNavigator(view,t) {
  const nodes=view.treeNodes;
  const list=v_virtual_list('review-file-tree',nodes.length,26,i=>`${nodes[i].kind}:${nodes[i].path}`,range=>nodes.slice(range.start,range.end).map(n=>
    h_flex().h(26).w_full().pl(6+n.depth*12).pr(5).gap(5).items_center().bg(n.path===view.navFile?t.selected:t.surface)
      .child(n.kind==='folder'?icon(n.closed?'chevron-right':'chevron-down',12).text_color(t.dim):fileIcon(n.path,13))
      .child(div().flex_1().min_w(0).truncate().text_size(11).text_color(n.kind==='folder'?t.muted:t.foreground).child(n.name))))
    .on_item_click((key,cx)=>view.navigateFile(key,cx)).size_full();
  return v_flex().w(180).h_full().flex_none().min_h(0).bg(t.surface).border_r(1).border_color(t.border)
    .child(div().px(8).py(6).text_size(10).font_semibold().text_color(t.muted).child(`CHANGED FILES · ${view.files.length}`))
    .child(div().px(6).pb(5).child(Input.new(view.fileInput).h(26).w_full().px(5).bg(t.background).border(1).border_color(t.input).rounded(3).text_size(11)))
    .child(div().flex_1().min_h(0).relative().child(list).child(Scrollbar.vertical('review-file-tree').viewport_from_layout().absolute().inset_0()))
    .when(!nodes.length,el=>el.child(div().p(8).text_size(11).text_color(t.dim).child('No matching files')));
}
