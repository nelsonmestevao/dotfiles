import { View, div, svg, image } from 'gpui-kit';
import { h_flex, v_flex } from 'gpui-base';
import { spaces, agents, panes, props, run, setAgentOrder } from 'herdr';

const C = { purple:'#311b3b', deep:'#22112b', soft:'#b9a6c4', text:'#27232b', muted:'#817888', line:'#e8e3ea', mint:'#3cbd9b', yellow:'#e6b755' };
const active = () => spaces().find(s => s.active);
const dot = (status) => div().size(8).rounded(4).flex_shrink(0).bg(status === 'working' ? C.mint : status === 'blocked' ? C.yellow : '#998ba1');
const icon = (p, size=30) => div().size(size).flex_shrink(0).rounded(7).bg(p?.tile || '#eee9f0').flex().items_center().justify_center().when(Boolean(p?.icon), e => e.child(p.tint ? svg(p.icon).size(size-12).text_color(p.color || '#ffffff') : image(p.icon).size(size-12)));
const label = (text) => div().px(20).mt(23).mb(8).text_size(11).font_semibold().text_color(C.soft).child(text);
const statusText = a => a.status === 'blocked' ? `Needs you in ${a.tab_name}` : a.status === 'working' ? `Working on ${a.tab_name}` : a.status === 'done' ? `Finished ${a.tab_name}` : `Standing by in ${a.tab_name}`;

export default class Chat extends View {
  init() { this.events = new Map(); }
  render() {
    const role = props()?.role;
    const all = agents();
    if (role === 'top') return h_flex().size_full().items_center().bg(C.deep).text_color('#ded2e6').px(18).gap(18)
      .child(div().text_size(15).font_semibold().child('herdr / team chat'))
      .child(div().flex_1())
      .child(h_flex().w(540).h(27).px(12).items_center().rounded(5).bg('#ffffff15').text_size(12).child('Search your workspace'))
      .child(div().flex_1()).child(div().size(25).rounded(6).bg('#b69ac3').text_color(C.deep).flex().items_center().justify_center().text_size(11).font_semibold().child('CC'));
    if (role === 'sidebar') {
      setAgentOrder(all.map(a => a.address));
      return v_flex().size_full().bg(C.purple).text_color('#f5eff8').text_size(13).overflow_hidden()
        .child(h_flex().h(64).flex_shrink(0).px(20).items_center().justify_between().border_b(1).border_color('#ffffff15').child(div().text_size(19).font_semibold().child('Launch team')).child(div().child('+')))
        .child(h_flex().px(20).mt(18).gap(10).items_center().text_color(C.soft).child(div().child('All activity')).child(div().flex_1()).child(div().child(String(all.filter(a=>a.status==='blocked').length))))
        .child(label('CHANNELS'))
        .children(spaces().map(s => h_flex().id('space-'+s.id).h(33).mx(10).px(10).gap(9).items_center().rounded(5).bg(s.active ? '#715180' : '#00000000').on_click(()=>run('space.select',{id:s.id}))
          .child(div().text_color(C.soft).text_size(18).child('#')).child(div().flex_1().truncate().font_semibold().child(s.name)).when(s.status==='blocked', e=>e.child(dot('blocked')))))
        .child(label('DIRECT MESSAGES'))
        .children(all.map(a=>h_flex().id('dm-'+a.address).h(39).mx(10).px(10).gap(9).items_center().on_click(()=>run('agent.focus',{terminal:a.address}))
          .child(dot(a.status)).child(v_flex().flex_1().min_w(0).child(div().truncate().child(a.program.name)).child(div().text_size(10).text_color(C.soft).truncate().child(a.tab_name)))))
        .child(div().flex_1())
        .child(h_flex().h(48).px(20).gap(8).items_center().border_t(1).border_color('#ffffff15').child(dot('working')).child(div().text_size(11).text_color(C.soft).child(`${all.length} agents connected`)));
    }
    if (role === 'thread') return h_flex().size_full().bg('#faf8fb').px(18).items_center().gap(10).border_b(1).border_color(C.line).text_color(C.text)
      .child(div().text_size(17).font_semibold().child('Thread')).child(div().text_size(12).text_color(C.muted).child(active()?.tabs.find(t=>t.active)?.name || ''))
      .child(div().flex_1()).child(dot('working')).child(div().text_size(11).text_color(C.muted).child('Live terminals'));
    if (role === 'pane') {
      const p = panes().find(p=>p.pane===props().pane);
      return h_flex().size_full().px(10).gap(8).items_center().bg('#eee8f1').text_color(C.text).text_size(11).child(icon(p?.program,22)).child(div().font_semibold().child(p?.program.name || 'Terminal')).child(div().flex_1()).child(dot(p?.status));
    }
    const channel = active();
    const list = all.filter(a=>a.space===channel?.id);
    for (const a of list) {
      const old = this.events.get(a.address);
      if (!old || old.seq !== a.seq) this.events.set(a.address, { seq:a.seq, time:`${String(new Date().getHours()).padStart(2,'0')}:${String(new Date().getMinutes()).padStart(2,'0')}` });
    }
    return v_flex().size_full().bg('#ffffff').text_color(C.text).overflow_hidden()
      .child(v_flex().h(65).flex_shrink(0).px(22).justify_center().gap(3).border_b(1).border_color(C.line)
        .child(h_flex().gap(12).items_center().child(div().text_size(21).font_semibold().child('# '+(channel?.name || ''))).child(div().flex_1()).child(div().text_size(11).text_color(C.muted).child(`${list.length} members`)))
        .child(div().text_size(11).text_color(C.muted).child('A place for work to come together')))
      .child(v_flex().flex_1().min_h(0).overflow_y_scrollbar().px(22).pt(18)
        .child(div().size(40).rounded(10).bg('#eee6f2').flex().items_center().justify_center().text_size(33).text_color('#785086').child('#'))
        .child(div().mt(13).text_size(27).font_semibold().child(channel?.name || ''))
        .child(div().mt(5).text_size(12).text_color(C.muted).child('Your agents, together in one place.'))
        .child(h_flex().mt(16).mb(16).gap(10).items_center().child(div().h(1).flex_1().bg(C.line)).child(div().text_size(10).text_color(C.muted).child('LIVE ACTIVITY')).child(div().h(1).flex_1().bg(C.line)))
        .children(list.map(a=>h_flex().mb(12).gap(11).items_start()
          .child(icon(a.program,34))
          .child(v_flex().flex_1().min_w(0).gap(3)
            .child(h_flex().gap(7).items_center().child(div().text_size(13).font_semibold().child(a.program.name)).child(div().px(4).py(1).rounded(3).bg('#f1edf4').text_size(8).text_color(C.muted).child('APP')).child(div().text_size(9).text_color(C.muted).child(this.events.get(a.address)?.time || '')))
            .child(div().text_size(13).child(statusText(a)))
            .child(h_flex().id('message-'+a.address).on_click(()=>run('agent.focus',{terminal:a.address})).gap(7).px(10).py(5).rounded(5).bg(a.status==='blocked'?'#fff5df':'#f6f3f7').border_l(3).border_color(a.status==='blocked'?C.yellow:'#bba3c7').items_center().child(dot(a.status)).child(div().text_size(11).text_color('#75617f').child(a.status==='blocked'?'Open conversation':'View live thread')).child(div().flex_1()).child(div().text_size(12).text_color('#9983a4').child('>')))))))
      .child(v_flex().mx(20).mb(20).p(12).gap(16).rounded(8).border(1).border_color('#cfc4d5').bg('#ffffff')
        .child(div().text_size(12).text_color('#a098a6').child(`Message #${channel?.name || ''}`))
        .child(h_flex().text_size(14).text_color(C.muted).gap(16).child(div().font_semibold().child('+')).child(div().font_semibold().child('B')).child(div().child('/')).child(div().flex_1()).child(div().px(9).py(2).rounded(4).bg('#eae4ef').text_color('#755482').child('Send'))));
  }
}
