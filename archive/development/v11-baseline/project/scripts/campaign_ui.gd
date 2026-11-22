extends RefCounted

const ART = preload("res://assets/campaign_keyart.png")
const AMBER = Color("ffc48e")
const PAPER = Color("f4f2e9")
const SILVER = Color("c0cbd3")
const NIGHT = Color("101a24")
const ICE = Color("9ce3e0")

static func main_menu(h: Control) -> void:
 var mission = h.game.campaign
 menu_button(h,"继续战役" if mission.checkpoint>0 and not mission.completed else "开始战役",391,mission.begin,true)
 menu_button(h,"整备",470,h.game.open_backpack)
 menu_button(h,"自由实验场",535,h.game.open_lab)
 menu_button(h,"设置",600,func(): h.show_page("settings"))
 h.button("退出游戏",Rect2(92,805,143,40),func(): h.game.get_tree().quit()).add_theme_font_size_override("font_size",16)

static func menu_button(h: Control, value: String, y: int, action: Callable, primary: bool = false) -> void:
 var b: Button = h.button(value,Rect2(92,y,367,57),action,primary)
 b.alignment = HORIZONTAL_ALIGNMENT_LEFT
 b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 var background = Color("ffc48e") if primary else Color(.054,.094,.13,.78)
 var border = AMBER if primary else Color("465863")
 b.add_theme_stylebox_override("normal",h.style(background,border))
 b.add_theme_stylebox_override("hover",h.style(background.lightened(.11),AMBER))
 b.add_theme_stylebox_override("focus",h.style(Color(0,0,0,0),PAPER))
 b.add_theme_color_override("font_focus_color",NIGHT if primary else PAPER)

static func draw_menu(h: Control) -> void:
 # Fill the reference canvas while keeping the squad on the right at 16:10.
 h.draw_texture_rect_region(ART,Rect2(0,0,1440,900),Rect2(0,0,1506,941))
 h.draw_rect(Rect2(0,0,1440,900),Color(0.02,.038,.055,.12))
 h.draw_rect(Rect2(92,114,40,3),AMBER)
 h.txt("STARPORT SQUAD",Vector2(92,154),22,AMBER,true)
 h.txt("星港小队",Vector2(83,255),83,PAPER)
 h.txt("夺回星港",Vector2(92,315),31,PAPER)
 var m = h.game.campaign
 var summary = "战役已完成 · 可重新部署" if m.completed else "检查点  /  "+m.TITLES[m.checkpoint]
 h.txt(summary,Vector2(93,351),18,SILVER)

static func draw_hud(h: Control) -> void:
 var g = h.game
 var m = g.campaign
 var p = g.player
 h.panel(Rect2(44,43,405,104),.88)
 h.draw_rect(Rect2(44,43,3,104),AMBER)
 h.txt(m.TITLES[m.phase],Vector2(66,83),26,PAPER)
 h.txt(m.objective(),Vector2(66,121),19,AMBER)
 for i in range(4):
  h.draw_rect(Rect2(66+i*24,156,18,3),AMBER if i<=m.phase else Color("455561"))
 var status = "%d / %d 队友" % [g.command.alive_count(),g.allies.size()]
 h.txt(status+"   ·   "+("驻守" if g.command.order=="defend" else "跟随"),Vector2(1130,83),20,ICE)
 if g.vehicles.current!=null:
  g.fieldkit.draw_vehicle(h)
 else:
  var target = g.vehicles.nearby()
  if target!=null:
   h.prompt("E  登上装甲车")
  elif p.position.distance_to(g.forts.base())<1.8 or p.position.distance_to(g.forts.top())<2:
   h.prompt("E  使用梯子")
  var aim_center = Vector2(720,450)
  if p.ads and p.weapon_models[p.weapon]==8:
   h.draw_arc(aim_center,255,0,TAU,96,Color(ICE,.62),2,true)
   h.draw_line(Vector2(465,450),Vector2(975,450),Color(ICE,.65))
   h.draw_line(Vector2(720,195),Vector2(720,705),Color(ICE,.65))
  else:
   for axis in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
    h.draw_line(aim_center+axis*5,aim_center+axis*12,PAPER,2,true)
  if g.hit_marker>0:
   for axis in [Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]:
    h.draw_line(aim_center+axis*11,aim_center+axis*17,AMBER,2,true)
 var location = m.RALLY+Vector3.UP*.45
 if m.phase==2: location = Vector3(10,1,-13.3)
 if m.phase==3: location = g.command.enemy_core.global_position+Vector3.UP*1.4
 if m.phase!=1 and not p.ads:
  h.marker(location,["集合","","外环","核心"][m.phase],AMBER)
 if m.radio_time>0:
  h.panel(Rect2(330,716,780,55),.91)
  h.center("小队频道   "+m.radio,751,19,PAPER)
 if g.toast_time>0 and m.radio_time<=0:
  h.center(g.toast,751,19,PAPER)
 h.txt("护盾",Vector2(50,813),16,ICE)
 h.draw_rect(Rect2(112,800,168,9),Color("2e4353"))
 h.draw_rect(Rect2(112,800,168*clampf(p.shield/p.max_shield(),0,1),9),ICE)
 h.txt("生命",Vector2(50,843),16,PAPER)
 h.draw_rect(Rect2(112,830,168,9),Color("2e4353"))
 h.draw_rect(Rect2(112,830,168*clampf(p.hp/p.max_hp,0,1),9),PAPER)
 h.txt("手雷 %d" % m.grenades,Vector2(1050,837),17,SILVER)
 h.txt("重型大狙" if p.weapon==1 else "制式步枪",Vector2(1190,793),18,SILVER)
 h.txt("%02d  /  %02d" % [p.ammo[p.weapon],p.capacity[p.weapon]],Vector2(1188,840),36,PAPER,true)
 if p.reload_left>0: h.center("换弹中",540,18,AMBER)
 if g.hurt_flash>0: h.draw_rect(Rect2(0,0,1440,900),Color(1,.43,.22,g.hurt_flash*.31),false,10)

static func result_buttons(h: Control) -> void:
 var m = h.game.campaign
 if h.page=="campaign_failed":
  h.button("从检查点重试",Rect2(496,516,448,56),h.game.retry_campaign,true)
 elif m.completed and m.reward=="":
  h.button("增强护盾   +40",Rect2(496,511,215,58),func(): m.choose_reward("armor"),true)
  h.button("增加一名队友",Rect2(729,511,215,58),func(): m.choose_reward("squad"))
 elif not m.completed:
  h.button("从检查点重试",Rect2(496,516,448,56),h.game.retry_campaign,true)
 h.button("返回主菜单",Rect2(496,600,448,53),h.game.restart)

static func draw_result(h: Control) -> void:
 var m = h.game.campaign
 h.draw_rect(Rect2(0,0,1440,900),Color(.025,.045,.065,.83))
 h.panel(Rect2(454,210,532,493),.97)
 h.draw_rect(Rect2(454,210,532,3),AMBER)
 var won = h.page=="campaign_result"
 h.center("中继核心已夺回" if won else "小队撤离",331,39,PAPER)
 if won:
  h.center("用时 "+h.time_string(h.game.elapsed)+"   ·   停机机器人 %d" % h.game.kills,389,21,SILVER)
  h.center("选择一项战役升级" if m.reward=="" else ("已装备强化护盾" if m.reward=="armor" else "额外队友已加入"),465,20,AMBER)
 else:
  h.center("护盾和生命已耗尽，从最近的检查点重整小队。",423,18,SILVER)
 if m.notice!="": h.center(m.notice,680,17,AMBER)
