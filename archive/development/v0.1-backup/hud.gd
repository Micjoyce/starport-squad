extends Control
var game: Node3D
var font: Font
var bold: Font
var content: Control
var page := "menu"
var buttons: Array[Control] = []
var s := 1.0
var offset := Vector2.ZERO
const INK = Color("0b1929")
const WHITE = Color("edf5f6")
const MUTED = Color("a6bdcc")
const CYAN = Color("64ece0")
const ORANGE = Color("ffb266")

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 var system = SystemFont.new()
 system.font_names = PackedStringArray(["PingFang SC","Noto Sans CJK SC","Microsoft YaHei","Arial"])
 font = system
 if ResourceLoader.exists("res://assets/NotoSansSC.ttf"):
  var variation = FontVariation.new()
  variation.base_font = load("res://assets/NotoSansSC.ttf")
  variation.variation_opentype = {2003265652: 550.0}
  font = variation
 var heading = SystemFont.new()
 heading.font_names = PackedStringArray(["DIN Alternate","Avenir Next","Arial"])
 heading.font_weight = 700
 bold = heading
 content = Control.new()
 content.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(content)
 show_page("menu")
 resized.connect(update_layout)
 update_layout()

func update_layout() -> void:
 s = minf(size.x/1440,size.y/900)
 offset = (size-Vector2(1440,900)*s)/2
 if content:
  content.scale = Vector2.ONE*s
  content.position = offset
 queue_redraw()

func style(bg: Color, border: Color) -> StyleBoxFlat:
 var st = StyleBoxFlat.new()
 st.bg_color = bg
 st.border_color = border
 st.set_border_width_all(1)
 st.set_corner_radius_all(3)
 st.content_margin_left = 20
 st.content_margin_right = 20
 return st

func button(value: String, rect: Rect2, action: Callable, primary: bool = false) -> Button:
 var b = Button.new()
 b.text = value
 b.position = rect.position
 b.size = rect.size
 b.add_theme_font_override("font",font)
 b.add_theme_font_size_override("font_size",21)
 var bg = ORANGE if primary else Color("182c40")
 b.add_theme_color_override("font_color",INK if primary else WHITE)
 b.add_theme_color_override("font_hover_color",INK if primary else CYAN)
 b.add_theme_color_override("font_focus_color",INK if primary else CYAN)
 b.add_theme_color_override("font_pressed_color",INK)
 b.add_theme_stylebox_override("normal",style(bg,ORANGE if primary else Color("415b6d")))
 b.add_theme_stylebox_override("hover",style(bg.lightened(.12),CYAN))
 b.add_theme_stylebox_override("pressed",style(CYAN,CYAN))
 b.add_theme_stylebox_override("focus",style(Color(0,0,0,0),CYAN))
 b.pressed.connect(action)
 content.add_child(b)
 buttons.append(b)
 return b

func toggle(value: String, pos: Vector2, state: bool, action: Callable) -> CheckButton:
 var b = CheckButton.new()
 b.text = value
 b.position = pos
 b.size = Vector2(430,48)
 b.button_pressed = state
 b.add_theme_font_override("font",font)
 b.add_theme_font_size_override("font_size",20)
 b.add_theme_color_override("font_color",WHITE)
 b.toggled.connect(action)
 content.add_child(b)
 buttons.append(b)
 return b

func show_page(value: String) -> void:
 page = value
 if not content:
  return
 for b in buttons:
  b.queue_free()
 buttons.clear()
 if page == "menu":
  button("部署出发    /    PLAY",Rect2(68,557,460,64),func(): game.start_game(),true)
  button("AK47 · 轨道改装型",Rect2(68,457,225,56),func(): game.player.switch_weapon(0); queue_redraw())
  button("霰弹枪 · 彗星",Rect2(303,457,225,56),func(): game.player.switch_weapon(1); queue_redraw())
  button("设置与操作",Rect2(68,637,222,52),func(): show_page("settings"))
  button("退出游戏",Rect2(306,637,222,52),func(): game.get_tree().quit())
 elif page == "paused":
  button("继续任务",Rect2(490,363,460,62),func(): game.pause_game(),true)
  button("设置与操作",Rect2(490,443,460,56),func(): show_page("settings"))
  button("重新开始",Rect2(490,517,460,56),func(): game.restart())
  button("退出游戏",Rect2(490,591,460,56),func(): game.get_tree().quit())
 elif page == "settings":
  toggle("背景配乐",Vector2(490,245),game.music_on,func(v): game.music_on=v; game.apply_audio(); game.save_settings())
  toggle("射击与环境音效",Vector2(490,298),game.sfx_on,func(v): game.sfx_on=v; game.apply_audio(); game.save_settings())
  toggle("辅助瞄准 · 推荐开启",Vector2(490,351),game.assist,func(v): game.assist=v; game.save_settings())
  toggle("减少镜头晃动",Vector2(490,404),game.low_motion,func(v): game.low_motion=v; game.save_settings())
  var slider = HSlider.new()
  slider.position = Vector2(690,475)
  slider.size = Vector2(240,32)
  slider.min_value = .0008
  slider.max_value = .004
  slider.step = .0001
  slider.value = game.sensitivity
  slider.value_changed.connect(func(v): game.sensitivity=v; game.player.sensitivity=v; game.save_settings())
  content.add_child(slider)
  buttons.append(slider)
  button("返回",Rect2(490,727,460,56),func(): show_page("menu" if game.mode=="menu" else "paused"),true)
 elif page == "win":
  button("再来一局",Rect2(490,622,460,62),func(): game.restart(),true)
  button("退出游戏",Rect2(490,703,460,52),func(): game.get_tree().quit())
 if not buttons.is_empty():
  buttons[0].grab_focus()
 queue_redraw()

func txt(value: String, pos: Vector2, px: int = 20, color: Color = WHITE, display: bool = false) -> void:
 draw_string(bold if display else font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)

func center(value: String, y: float, px: int = 20, color: Color = WHITE) -> void:
 var width = font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
 txt(value,Vector2(720-width/2,y),px,color)

func panel(rect: Rect2, alpha: float = .9) -> void:
 draw_style_box(style(Color(INK,alpha),Color("355062")),rect)

func _draw() -> void:
 if not font or not is_instance_valid(game.player):
  return
 draw_set_transform(offset,0,Vector2.ONE*s)
 if page == "playing":
  draw_game()
 elif page == "menu":
  draw_menu()
 else:
  draw_rect(Rect2(0,0,1440,900),Color(.015,.035,.065,.76))
  panel(Rect2(450,135,540,690),.96)
  draw_rect(Rect2(450,135,540,3),CYAN)
  if page == "paused":
   txt("MISSION PAUSED",Vector2(490,201),17,CYAN,true)
   txt("休息一下",Vector2(490,280),48)
   txt("任务已暂停，准备好就继续。",Vector2(490,323),19,MUTED)
  elif page == "settings":
   txt("FLIGHT CONFIGURATION",Vector2(490,187),17,CYAN,true)
   txt("设置与操作",Vector2(490,226),29)
   txt("鼠标灵敏度",Vector2(490,498),20,MUTED)
   draw_line(Vector2(490,532),Vector2(950,532),Color("355062"))
   txt("W A S D  移动     鼠标  转向",Vector2(490,572),19)
   txt("左键  射击         右键  瞄准",Vector2(490,607),19)
   txt("1 / 2  切枪         R  换弹",Vector2(490,642),19)
   txt("E  交互   Shift  奔跑   空格  跳跃",Vector2(490,677),19)
   txt("Esc  暂停          F11  全屏",Vector2(490,708),17,MUTED)
  elif page == "win":
   txt("MISSION COMPLETE",Vector2(490,206),19,CYAN,true)
   txt("星港，重新亮起。",Vector2(490,286),39)
   txt("能源已送达。小小守卫，任务完成！",Vector2(490,335),21,MUTED)
   draw_line(Vector2(490,371),Vector2(950,371),Color("355062"))
   txt("任务用时",Vector2(490,417),20,MUTED)
   txt(time_string(game.elapsed),Vector2(811,421),30,CYAN,true)
   txt("停机机器人",Vector2(490,474),20,MUTED)
   txt(str(game.kills),Vector2(866,477),30,WHITE,true)
   txt("能源回收",Vector2(490,531),20,MUTED)
   txt("3 / 3",Vector2(839,534),30,WHITE,true)
   txt("护盾修复次数  "+str(game.rescues),Vector2(490,580),18,MUTED)
 # thin framing lines stay quiet at the edge of the view.
 for x in [24,1416]:
  draw_line(Vector2(x,24),Vector2(x,54),CYAN,2)
 draw_line(Vector2(24,24),Vector2(54,24),CYAN,2)
 draw_line(Vector2(1386,24),Vector2(1416,24),CYAN,2)

func draw_menu() -> void:
 draw_rect(Rect2(0,0,595,900),Color(.025,.06,.10,.96))
 draw_rect(Rect2(595,0,2,900),Color(.35,.65,.72,.35))
 txt("O R B I T A L   /   0 7",Vector2(68,91),21,CYAN,true)
 txt("星港小队",Vector2(63,238),79)
 txt("STARPORT",Vector2(68,313),72,WHITE,true)
 txt("S Q U A D",Vector2(71,356),30,ORANGE,true)
 txt("一座失联的星港。一场勇敢的太空冒险。",Vector2(68,402),20,MUTED)
 txt("选择你的出发装备",Vector2(68,441),17,CYAN)
 var chosen = Rect2(68 if game.player.weapon==0 else 303,521,225,3)
 draw_rect(chosen,ORANGE)
 txt("单人任务  /  机器人对战  /  友好难度",Vector2(68,734),18,MUTED)
 txt("收集 3 块能源，带着希望返回飞船。",Vector2(68,769),20,WHITE)
 txt("GODOT 4  /  PLAYABLE PROTOTYPE  /  01",Vector2(68,852),13,MUTED,true)
 panel(Rect2(1108,54,264,66),.8)
 draw_circle(Vector2(1132,87),4,CYAN)
 txt("KEPLER · 星环轨道",Vector2(1147,94),17,WHITE)
 panel(Rect2(1010,713,362,132),.85)
 txt("SECTOR 07",Vector2(1034,750),18,ORANGE,true)
 txt("能源中枢 / 轨道星港",Vector2(1034,787),25)
 txt("三处能源站 · 一条回家的路",Vector2(1034,820),17,MUTED)

func draw_game() -> void:
 var p = game.player
 # Mission card.
 panel(Rect2(40,45,320,128),.84)
 draw_rect(Rect2(40,45,3,128),CYAN)
 txt("OPERATION / 星港重启",Vector2(61,77),17,CYAN)
 txt("收集能源" if game.cells<3 else "返回撤离平台",Vector2(61,114),26)
 for i in range(3):
  var x = 63+i*29
  draw_rect(Rect2(x,135,18,13),CYAN if game.pickups[i].taken else Color("355366"))
 txt(str(game.cells)+" / 3",Vector2(166,148),18,MUTED,true)
 txt(time_string(game.elapsed),Vector2(276,148),17,WHITE,true)
 # Compass.
 draw_line(Vector2(540,63),Vector2(900,63),Color(1,1,1,.25))
 var heading = fposmod(rad_to_deg(-p.rotation.y),360)
 for i in range(-3,4):
  var x = 720+i*48
  draw_line(Vector2(x,57),Vector2(x,65),MUTED)
 txt("%03d°" % int(heading),Vector2(698,45),18,CYAN,true)
 draw_colored_polygon(PackedVector2Array([Vector2(715,72),Vector2(725,72),Vector2(720,79)]),ORANGE)
 # Objective world markers.
 for item in game.pickups:
  if not item.taken:
   marker(item.pos+Vector3.UP*2.7,item.letter,CYAN)
 if game.cells==3:
  marker(game.extraction_position+Vector3.UP*2.5,"撤离",ORANGE)
 # Radar.
 panel(Rect2(1200,45,200,221),.82)
 txt("星港雷达   N ↑",Vector2(1217,72),15,MUTED)
 var radar_origin = Vector2(1300,167)
 draw_circle(radar_origin,77,Color("142d3c"))
 draw_arc(radar_origin,77,0,TAU,64,Color("476777"),1)
 draw_arc(radar_origin,38,0,TAU,48,Color("2c4a5b"),1)
 draw_line(radar_origin-Vector2(77,0),radar_origin+Vector2(77,0),Color("2c4a5b"))
 draw_line(radar_origin-Vector2(0,77),radar_origin+Vector2(0,77),Color("2c4a5b"))
 var rscale = 2.25
 for item in game.pickups:
  if not item.taken:
   var v = Vector2(item.pos.x,item.pos.z)*rscale
   draw_rect(Rect2(radar_origin+v-Vector2(3,3),Vector2(6,6)),CYAN)
 for enemy in game.enemies:
  if is_instance_valid(enemy) and enemy.hp>0:
   draw_circle(radar_origin+Vector2(enemy.position.x,enemy.position.z)*rscale,2.5,ORANGE)
 var pp = radar_origin+Vector2(p.position.x,p.position.z)*rscale
 var dir = Vector2(sin(-p.rotation.y),-cos(p.rotation.y))
 draw_circle(pp,4,WHITE)
 draw_line(pp,pp+dir*12,WHITE,2)
 txt("%.0f FPS" % Engine.get_frames_per_second(),Vector2(1327,289),14,MUTED,true)
 # Crosshair.
 var c = Vector2(720,450)
 var gap = 6 if p.ads else (10 if p.weapon==0 else 20)
 var reticle = CYAN if game.hit_marker>0 else WHITE
 draw_circle(c,1.7,reticle)
 for axis in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
  draw_line(c+axis*gap,c+axis*(gap+7),reticle,1.5)
 if game.hit_marker>0:
  for d in [Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]:
   draw_line(c+d*11,c+d*17,ORANGE,2)
 # Shield and weapon status.
 panel(Rect2(40,761,312,96),.86)
 txt("护盾 / SHIELD",Vector2(60,791),16,CYAN)
 txt("%03d" % int(p.shield),Vector2(257,794),25,WHITE,true)
 draw_rect(Rect2(60,813,272,12),Color("2b4255"))
 draw_rect(Rect2(60,813,272*maxf(0,p.shield)/100,12),CYAN if p.shield>30 else ORANGE)
 txt("脱离攻击后自动恢复",Vector2(60,845),13,MUTED)
 panel(Rect2(1100,761,300,96),.88)
 txt("AK47 / 轨道改装型" if p.weapon==0 else "霰弹枪 / 彗星",Vector2(1120,791),18,ORANGE)
 txt("%02d" % p.ammo[p.weapon],Vector2(1117,841),44,WHITE,true)
 txt("/ %02d" % p.capacity[p.weapon],Vector2(1192,837),22,MUTED,true)
 txt("R 换弹",Vector2(1305,836),17,CYAN)
 center("WASD 移动    Shift 奔跑    空格 跳跃    1 / 2 切枪    右键 瞄准    Esc 暂停",883,15,MUTED)
 if p.reload_left>0:
  center("换弹中…",553,20,ORANGE)
  draw_rect(Rect2(650,568,140,4),Color("2b4255"))
  draw_rect(Rect2(650,568,140*(1-p.reload_left/(1.55 if p.weapon==0 else 1.9)),4),ORANGE)
 # Interaction prompts.
 var nearby = game.nearby_cell()
 if nearby>=0:
  prompt("E   收集能源 "+game.pickups[nearby].letter)
 elif game.cells==3 and p.position.distance_to(game.extraction_position)<4.3 and not game.extracting:
  prompt("E   启动飞船撤离")
 if game.extracting:
  panel(Rect2(510,683,420,66),.9)
  var inside = p.position.distance_to(game.extraction_position)<4.3
  center("飞船充能 · %.0f%%" % (game.extraction/12*100) if inside else "返回平台继续充能",711,20,CYAN if inside else ORANGE)
  draw_rect(Rect2(530,728,380,5),Color("2b4255"))
  draw_rect(Rect2(530,728,380*game.extraction/12,5),CYAN)
 if game.toast_time>0:
  var width = font.get_string_size(game.toast,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x+48
  panel(Rect2(720-width/2,124,width,48),.9)
  center(game.toast,155,20,WHITE)
 if game.elapsed>130 and game.elapsed<150:
  center("外沿设备即将过热 · 请靠近星港中央",216,20,ORANGE)
 elif game.elapsed>=150 and (absf(p.position.x)>23 or p.position.z < -28):
  center("外沿过热！请返回中央通道",216,23,ORANGE)
 if game.hurt_flash>0:
  draw_rect(Rect2(0,0,1440,900),Color(1,.35,.15,game.hurt_flash*.20),false,12)

func prompt(value: String) -> void:
 panel(Rect2(560,610,320,56),.93)
 center(value,647,21,CYAN)

func marker(world_pos: Vector3, label: String, color: Color) -> void:
 var cam = game.player.camera
 var point = cam.unproject_position(world_pos)
 # Convert viewport coordinates back into our reference layout.
 point = (point-offset)/s
 var behind = cam.is_position_behind(world_pos)
 if behind:
  point = Vector2(1440-point.x,900-point.y)
 point.x = clampf(point.x,390,1150)
 point.y = clampf(point.y,210,650)
 var distance = game.player.position.distance_to(world_pos)
 draw_circle(point,17,Color(INK,.9))
 draw_arc(point,18,0,TAU,24,color,1.5)
 var width = font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x
 txt(label,point+Vector2(-width/2,6),17,color)
 var meters = "%dm" % int(distance)
 txt(meters,point+Vector2(-13,40),15,WHITE,true)
 if behind:
  txt("↓",point+Vector2(-7,61),17,color)

func time_string(seconds: float) -> String:
 return "%02d:%02d" % [int(seconds)/60,int(seconds)%60]
