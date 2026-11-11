import { View, div, svg, image } from 'gpui-kit';
import { h_flex, v_flex } from 'gpui-base';
import { agents, spaces, panes, props, focused, run, setAgentOrder } from 'herdr';

const C = { bg:'#191b1f', tile:'#292c32', dim:'#a9adb6', text:'#f4f5f7', green:'#49d392' };
const icon = (name, size=22) => svg(`mods/call/${name}.svg`).size(size);
const status = a => ({ working:'Speaking · working', blocked:'Needs you', done:'Finished', idle:'Camera off' })[a.status];
const pill = (text, color=C.dim) => div().px(9).py(4).rounded(6).bg('#191b1fcc').text_size(11).text_color(color).child(text);

export default class Call extends View {
  init(p, cx) {
    this.role = (props() ?? p ?? {}).role ?? 'toolbar';
    this.started = Date.now();
    if (this.role === 'top') cx.timer.every(1000, cx => cx.notify());
  }
  render() {
    if (this.role === 'top') return this.top();
    if (this.role === 'gallery') return this.gallery();
    if (this.role === 'pane') return this.pane();
    return this.toolbar();
  }
  top() {
    const elapsed = Math.floor((Date.now()-this.started)/1000);
    const s = spaces().find(s => s.active);
    return h_flex().size_full().px(24).items_center().justify_between().bg(C.bg).text_color(C.text)
      .child(h_flex().gap(12).items_center().child(div().size(32).rounded(10).bg('#263b32').text_color(C.green).flex().items_center().justify_center().child(icon('shield',19)))
        .child(v_flex().gap(3).child(div().text_size(18).font_semibold().child(`${s?.name ?? 'website'} standup`)).child(div().text_size(11).text_color(C.dim).child(s?.tabs.find(t=>t.active)?.name ?? 'Team meeting'))))
      .child(h_flex().gap(18).items_center().text_size(12).child(h_flex().gap(7).items_center().text_color(C.dim).child(icon('clock',15)).child(div().child(`${String(Math.floor(elapsed/60)).padStart(2,'0')}:${String(elapsed%60).padStart(2,'0')}`)))
        .child(div().px(12).py(7).rounded(6).bg('#303339').child('Gallery view')).child(icon('expand',17)));
  }
  gallery() {
    const all=agents();
    setAgentOrder(all.map(a=>a.address));
    const list=all.filter(a=>a.tab !== focused()?.tab);
    return h_flex().size_full().gap(10).text_color(C.text).children(list.map((a,i)=> {
      const active=a.status==='working', needs=a.status==='blocked';
      const colors=['#514b72','#43596f','#6c5141','#375e57','#5e4662','#535b3e','#4b536d'];
      const glyph=a.program.icon ? (a.program.tint ? svg(a.program.icon).text_color(a.program.color ?? '#ffffff') : image(a.program.icon)).size(43) : icon('people',40);
      return v_flex().id(`person-${a.address}`).flex_1().min_w(0).h_full().relative().rounded(10).bg(C.tile).border(2).border_color(active?C.green:'#363940').overflow_hidden()
        .on_click(()=>run('agent.focus',{terminal:a.address}))
        .child(h_flex().w_full().h(32).flex_none().px(9).pt(5).justify_between().items_center()
          .child(needs ? h_flex().gap(4).items_center().text_color('#ffd68b').child(icon('hand',19)).child(div().text_size(10).child('Needs you')) : div())
          .child(icon('mic-off',16).text_color(C.dim)))
        .child(v_flex().flex_1().items_center().justify_center().gap(10)
          .child(div().size(72).rounded(36).bg(colors[i%colors.length]).flex().items_center().justify_center().child(glyph))
          .child(div().text_size(11).text_color(active?C.green:C.dim).child(status(a))))
        .child(v_flex().p(10).gap(3).child(div().text_size(12).font_semibold().truncate().child(a.program.name)).child(div().text_size(10).text_color(C.dim).truncate().child(`${a.space_name} / ${a.tab_name}`)));
    }));
  }
  pane() {
    const p=panes().find(p=>p.pane===props().pane);
    const working=p?.status==='working';
    return h_flex().size_full().px(12).items_center().justify_between().bg('#25282e').border_t(working?3:1).border_color(working?C.green:'#35383f').text_color(C.text)
      .child(h_flex().gap(8).items_center().child(icon('mic-off',15).text_color(C.dim)).child(div().text_size(13).font_semibold().child(p?.program.name ?? 'Participant')))
      .child(pill(working?'Speaking · working': p?.status==='blocked'?'Needs you':'Screen shared',working?C.green:C.dim));
  }
  toolbar() {
    const button=(name,label,green=false)=>v_flex().w(90).gap(7).items_center().text_color(green?C.green:C.text).child(icon(name,24)).child(div().text_size(11).child(label));
    return h_flex().size_full().px(26).bg('#222429').items_center().text_color(C.text)
      .child(h_flex().gap(2).items_center().child(button('mic-off','Unmute')).child(button('video-off','Start video')))
      .child(div().flex_1())
      .child(h_flex().gap(6).items_center().child(button('people',`Participants (${agents().length})`)).child(button('chat','Chat')).child(button('share','Share screen',true)).child(button('record','Record')).child(button('smile','Reactions')))
      .child(div().flex_1())
      .child(div().px(25).py(12).rounded(8).bg('#d9454d').text_size(13).font_semibold().child('Leave'));
  }
}
