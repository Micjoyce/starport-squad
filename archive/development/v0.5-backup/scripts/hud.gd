extends Control
const Gear = preload("res://scripts/gear.gd")
var game: Node3D
var font: Font
var bold: Font
var content: Control
var page := "menu"
var inventory_big := false
var inventory_tab := 0
var inventory_status := ""
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
  button("部署出发    /    PLAY",Rect2(68,602,460,64),func(): game.start_game(),true)
  button(Gear.MODEL_NAMES[game.career.models.ak]+" / 主武器",Rect2(68,509,225,56),func(): game.player.switch_weapon(0); queue_redraw()).add_theme_font_size_override("font_size",17)
  button(Gear.MODEL_NAMES[game.career.models.sg]+" / 副武器",Rect2(303,509,225,56),func(): game.player.switch_weapon(1); queue_redraw()).add_theme_font_size_override("font_size",17)
  button("设置与操作",Rect2(68,680,222,52),func(): show_page("settings"))
  button("退出游戏",Rect2(306,680,222,52),func(): game.get_tree().quit())
  for i in range(4):
   var index = i
   var choice = button(Gear.MODES[i],Rect2(68+i*117,405,109,44),func(): game.select_difficulty(index))
   choice.add_theme_font_size_override("font_size",17)
  button("背包 / 商店 / 技能  B",Rect2(68,744,460,48),func(): game.open_backpack())
 elif page == "chest":
  build_chest()
 elif page == "inventory":
  build_inventory()
 elif page == "paused":
  button("继续任务",Rect2(490,363,460,62),func(): game.pause_game(),true)
  button("设置与操作",Rect2(490,443,460,56),func(): show_page("settings"))
  button("重新开始",Rect2(490,517,460,56),func(): game.restart())
  button("退出游戏",Rect2(490,591,460,56),func(): game.get_tree().quit())
  button("背包 / 商店 / 技能  B",Rect2(490,665,460,48),func(): game.open_backpack())
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
  button("返回战场开箱 / 卖出战利品",Rect2(490,622,460,56),func(): game.resume_looting(),true)
  button("再来一局",Rect2(490,692,460,52),func(): game.restart(),true)
  button("退出游戏",Rect2(490,758,460,48),func(): game.get_tree().quit())
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
 if game.mode=="transit":
  draw_rect(Rect2(0,0,1440,900),INK)
  center("NEXUS / 科技传送中",440,35,CYAN)
 elif page == "chest":
  draw_chest()
 elif page == "inventory":
  draw_inventory()
 elif page == "playing":
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
   txt("H 风衣治疗    V 切换人称    F11 全屏",Vector2(490,708),17,MUTED)
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
   txt("资源币 "+str(game.career.credits)+" · 战利品已存档，按 B 管理",Vector2(490,580),17,CYAN)
 # thin framing lines stay quiet at the edge of the view.
 for x in [24,1416]:
  draw_line(Vector2(x,24),Vector2(x,54),CYAN,2)
 draw_line(Vector2(24,24),Vector2(54,24),CYAN,2)
 draw_line(Vector2(1386,24),Vector2(1416,24),CYAN,2)

func draw_menu() -> void:
 draw_rect(Rect2(0,0,595,900),Color(.025,.06,.10,.96))
 draw_rect(Rect2(595,0,2,900),Color(.35,.65,.72,.35))
 txt("O R B I T A L   /   0 7",Vector2(68,91),21,CYAN,true)
 txt("星港小队",Vector2(63,216),75)
 txt("STARPORT",Vector2(68,287),66,WHITE,true)
 txt("S Q U A D",Vector2(71,327),28,ORANGE,true)
 txt("一座失联的星港。一场勇敢的太空冒险。",Vector2(68,366),18,MUTED)
 txt("选择难度",Vector2(68,393),16,CYAN)
 draw_rect(Rect2(68+game.difficulty*117,453,109,3),Gear.COLORS[4] if game.difficulty==2 else ORANGE)
 txt(Gear.DESCRIPTIONS[game.difficulty],Vector2(68,481),15,MUTED)
 txt("选择出发武器 · 保留仓库等级",Vector2(68,500),16,CYAN)
 var chosen = Rect2(68 if game.player.weapon==0 else 303,573,225,3)
 draw_rect(chosen,ORANGE)
 txt("资源币 "+str(game.career.credits)+" · 装备与技能永久保存",Vector2(68,815),17,MUTED)
 
 txt("GODOT 4  /  NEXUS EXPEDITION  /  05",Vector2(68,852),13,MUTED,true)
 panel(Rect2(1108,54,264,66),.8)
 draw_circle(Vector2(1132,87),4,CYAN)
 txt("KEPLER · 星环轨道",Vector2(1147,94),17,WHITE)
 panel(Rect2(1010,713,362,132),.85)
 txt("SECTOR 07",Vector2(1034,750),18,ORANGE,true)
 txt("能源中枢 / 轨道星港",Vector2(1034,787),25)
 txt("白 → 蓝 → 紫 → 金 → 红 → 彩虹",Vector2(1034,820),17,MUTED)
 for i in range(6):
  draw_rect(Rect2(1034+i*49,692,38,5),Gear.COLORS[[0,1,2,3,4,5][i]])

func draw_game() -> void:
 var p = game.player
 # Mission card.
 panel(Rect2(40,45,320,128),.84)
 draw_rect(Rect2(40,45,3,128),CYAN)
 txt(("星港 / " if game.expedition.sector==1 else "科技区 / ")+Gear.MODES[game.difficulty],Vector2(61,77),17,Gear.COLORS[4] if game.difficulty==2 else CYAN)
 txt("收集能源" if game.cells<3 else "返回撤离平台",Vector2(61,114),26)
 for i in range(3):
  var x = 63+i*29
  draw_rect(Rect2(x,135,18,13),CYAN if i<game.pickups.size() and game.pickups[i].taken else Color("355366"))
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
 var rscale = 2.25/game.expedition.scale_factor
 for item in game.pickups:
  if not item.taken:
   var v = Vector2(item.pos.x,item.pos.z)*rscale
   draw_rect(Rect2(radar_origin+v-Vector2(3,3),Vector2(6,6)),CYAN)
 for enemy in game.enemies:
  if is_instance_valid(enemy) and enemy.hp>0:
   draw_circle(radar_origin+Vector2(enemy.position.x,enemy.position.z)*rscale,2.5,Gear.COLORS[enemy.armor_tier])
 for loot in game.equipment:
  if not loot.taken:
   var dot = radar_origin+Vector2(loot.pos.x,loot.pos.z)*rscale
   draw_rect(Rect2(dot-Vector2(1.5,1.5),Vector2(3,3)),Gear.COLORS[loot.tier])
 var pp = radar_origin+Vector2(p.position.x,p.position.z)*rscale
 var dir = Vector2(sin(-p.rotation.y),-cos(p.rotation.y))
 draw_circle(pp,4,WHITE)
 draw_line(pp,pp+dir*12,WHITE,2)
 txt("%.0f FPS" % Engine.get_frames_per_second(),Vector2(1327,289),14,MUTED,true)
 for boss in game.enemies:
  if is_instance_valid(boss) and boss.is_boss and boss.hp>0:
   center("彩虹首领 · 生命 %d / 999 · 甲 %d / 1119" % [int(boss.hp),int(boss.armor)],248,18,ORANGE)
   draw_rect(Rect2(470,260,500,7),Color("2b4255"))
   draw_rect(Rect2(470,260,500*maxf(0,boss.hp)/999,7),ORANGE)
   break
 marker(game.expedition.portal_position+Vector3.UP*4,"传送02" if game.expedition.sector==1 else "终点",Color("b49aff"))
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
 txt(Gear.SHORT[p.armor_tier]+" / 盔甲",Vector2(60,791),16,Gear.COLORS[p.armor_tier])
 txt("%d / %d" % [int(p.shield),int(p.max_shield())],Vector2(218,791),17,WHITE,true)
 draw_rect(Rect2(60,813,272,12),Color("2b4255"))
 draw_rect(Rect2(60,813,272*maxf(0,p.shield)/p.max_shield(),12),Gear.COLORS[p.armor_tier])
 txt("减伤 %d%% · 脱战自动恢复" % int(p.total_reduction()*100),Vector2(60,845),13,MUTED)
 panel(Rect2(1100,761,300,96),.88)
 txt(Gear.MODEL_NAMES[p.weapon_models[p.weapon]]+" / "+Gear.NAMES[p.weapon_tiers[p.weapon]],Vector2(1120,791),17,Gear.COLORS[p.weapon_tiers[p.weapon]])
 txt("%02d" % p.ammo[p.weapon],Vector2(1117,841),44,WHITE,true)
 txt("/ %02d" % p.capacity[p.weapon],Vector2(1192,837),22,MUTED,true)
 txt("R 换弹",Vector2(1305,836),17,CYAN)
 center("WASD 移动  ·  V 切换人称  ·  H 风衣治疗  ·  Q 9999 · C/F/G 技能 · T 手雷  ·  B 背包  ·  Esc 暂停",883,15,MUTED)
 center("资源币 "+str(game.career.credits)+"  |  手榴弹 "+str(game.career.grenades)+"  |  区域 "+str(game.expedition.sector)+" / 2",850,14,CYAN)
 if p.reload_left>0:
  center("换弹中…",553,20,ORANGE)
  draw_rect(Rect2(650,568,140,4),Color("2b4255"))
  draw_rect(Rect2(650,568,140*(1-p.reload_left/(1.55 if p.weapon==0 else 1.9)),4),ORANGE)
 # Interaction prompts.
 var nearby = game.nearby_cell()
 if nearby>=0:
  prompt("E   收集能源 "+game.pickups[nearby].letter)
 elif game.expedition.nearby_chest()>=0:
  prompt("E   打开士兵战利品箱")
 elif game.expedition.near_portal():
  prompt("E   科技区传送门" if game.cells>=3 else "收齐 3 块能源开启传送门")
 elif game.nearby_resource()>=0:
  prompt("E   拾取资源 +"+str(game.resources[game.nearby_resource()].amount))
 elif game.nearby_equipment()>=0:
  var loot = game.equipment[game.nearby_equipment()]
  var noun = "盔甲" if loot.kind=="armor" else "枪械"
  var current_tier: int = p.armor_tier if loot.kind in ["armor","pants"] else p.weapon_tiers[p.weapon]
  prompt("E   存入背包"+noun if loot.tier<current_tier else "E   拾取"+Gear.NAMES[loot.tier].split(" · ")[0]+noun)
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
 elif game.elapsed>=150 and (absf(p.position.x)>23*game.expedition.scale_factor or p.position.z < -28*game.expedition.scale_factor):
  center("外沿过热！请返回中央通道",216,23,ORANGE)
 if not game.grenades.is_empty():
  var closest = null
  var closest_distance := 999.0
  for g in game.grenades:
   var distance = p.position.distance_to(g.node.position)
   if distance<closest_distance:
    closest = g
    closest_distance = distance
  if closest_distance<15:
   center("手榴弹！%.1f 秒 · 立即离开橙色圈或躲到掩体后" % closest.fuse,596,20,ORANGE)
   marker(closest.node.position+Vector3.UP*.6,"!",ORANGE)
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

func refresh_inventory() -> void:
 show_page("inventory")

func transact(action: String, kind: String, tier: int) -> void:
 var ok = game.career.buy(kind,tier) if action=="buy" else game.career.sell(kind,tier)
 inventory_status = ("买入成功 · 已永久保存" if action=="buy" else "出售成功 · 资源币已保存") if ok else "交易未完成 · 请检查余额、库存与价格"
 refresh_inventory()


func build_character_preview() -> void:
 var container = SubViewportContainer.new()
 container.position = Vector2(1020,268)
 container.size = Vector2(290,390)
 container.mouse_filter = Control.MOUSE_FILTER_IGNORE
 content.add_child(container)
 buttons.append(container)
 var viewport = SubViewport.new()
 viewport.size = Vector2i(290,390)
 viewport.own_world_3d = true
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 container.add_child(viewport)
 var root = Node3D.new()
 viewport.add_child(root)
 var env = WorldEnvironment.new()
 env.environment = Environment.new()
 env.environment.background_mode = Environment.BG_COLOR
 env.environment.background_color = INK
 env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color = Color.WHITE
 env.environment.ambient_light_energy = .7
 root.add_child(env)
 var light = DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-35,-45,0)
 light.light_energy = 1.1
 root.add_child(light)
 var camera = Camera3D.new()
 root.add_child(camera)
 camera.position = Vector3(2.2,1.65,-3.7)
 camera.look_at(Vector3(0,.95,0))
 camera.fov = 38
 var F = preload("res://scripts/factory.gd")
 var armor = Gear.armor_surface(game.career.equipped.armor)
 var trousers: Material = F.mat(Color("485567"))
 if game.career.pants_style>0:
  trousers = Gear.armor_surface(game.career.equipped.pants)
 elif game.career.green_pants:
  trousers = ShaderMaterial.new()
  trousers.shader = load("res://scripts/pants.gdshader")
 var Operative = preload("res://scripts/operative.gd")
 Operative.make_body(root,armor,trousers,game.player.weapon,[game.career.equipped.ak,game.career.equipped.sg],game.career.operator_coat,true,[game.career.models.ak,game.career.models.sg],game.career.pants_style==2)

func inventory_kind() -> String:
 return ["armor","ak","sg","pants"][inventory_tab]+("+" if inventory_big else "")

func build_inventory() -> void:
 button("返回 / B",Rect2(1190,88,150,45),func(): game.close_backpack())
 var titles = ["盔甲","主武器","副武器","裤装","技能","外观"]
 for i in range(6):
  var tab = i
  button(titles[i],Rect2(90+i*150,173,138,45),func(): inventory_tab=tab; refresh_inventory())
 if inventory_tab<4:
  button("当前：大型" if inventory_big else "当前：小型",Rect2(665,94,210,42),func(): inventory_big=not inventory_big; refresh_inventory())
  var kind = inventory_kind()
  var base = kind.trim_suffix("+")
  for tier in range(6):
   var t = tier
   var y = 275+t*69
   var owned: int = game.career.items[kind][t]
   var worn: bool = game.career.equipped[base]==t and game.career.sizes[base]==int(inventory_big)
   var equip_button = button("已装备" if worn else "装备",Rect2(605,y,104,43),func(): game.equip_owned(kind,t); refresh_inventory())
   equip_button.disabled = owned<=0 or worn
   var price: int = game.career.price(kind,t)
   var buy_button = button("买入",Rect2(723,y,104,43),func(): transact("buy",kind,t))
   buy_button.disabled = game.career.credits<price
   var sell_button = button("出售",Rect2(841,y,104,43),func(): transact("sell",kind,t))
   sell_button.disabled = not game.career.can_sell(kind,t)
  var cup = button("售世界杯 · 5000",Rect2(690,759,270,40),func():
   game.career.sell_trophy()
   refresh_inventory())
  cup.disabled = game.career.trophies<=0 or game.career.wins<=0
 elif inventory_tab==4:
  for index in range(3):
   var i = index
   var unlocked: bool = game.career.skills[i]
   var b = button("已解锁 · 无限使用" if unlocked else "解锁 · "+str(game.career.SKILL_COSTS[i]),Rect2(705,274+i*133,239,48),func():
    inventory_status = "技能已永久解锁" if game.career.unlock(i) else "资源不足"
    refresh_inventory())
   b.disabled = unlocked or game.career.credits<game.career.SKILL_COSTS[i]
 else:
  button("裤装："+["绿色炫彩","彩色防护长裤","战术防护泳裤"][game.career.pants_style],Rect2(150,412,465,56),func():
   game.career.set_pants_style((game.career.pants_style+1)%3)
   game.player.update_pants_equipment()
   refresh_inventory(),true)
  button("脱下干员风衣" if game.career.operator_coat else "穿上干员风衣",Rect2(150,482,465,56),func():
   game.career.set_coat(not game.career.operator_coat)
   game.player.refresh_body()
   refresh_inventory())
  button("切换为第一人称" if game.player.third_person else "切换为第三人称",Rect2(150,552,465,56),func():
   game.player.set_view(not game.player.third_person)
   refresh_inventory())
 build_character_preview()
 if inventory_tab in [1,2]:
  var slot: String = "ak" if inventory_tab==1 else "sg"
  var selector = OptionButton.new()
  selector.position = Vector2(1020,735)
  selector.size = Vector2(290,35)
  selector.add_theme_font_override("font",font)
  selector.add_theme_font_size_override("font_size",17)
  for model in range(8):
   selector.add_item(Gear.MODEL_NAMES[model]+(" · 已有" if model in game.career.owned_models else " · "+str(Gear.MODEL_COSTS[model])))
  selector.selected = game.career.models[slot]
  selector.item_selected.connect(func(model):
   if game.career.select_model(slot,model):
    game.apply_career()
    inventory_status = "型号已装备并保存"
   else:
    inventory_status = "资源不足，未解锁型号"
   refresh_inventory())
  content.add_child(selector)
  buttons.append(selector)

func draw_inventory() -> void:
 draw_rect(Rect2(0,0,1440,900),Color(.015,.035,.065,.95))
 panel(Rect2(60,63,1320,775),.96)
 txt("永久背包",Vector2(90,135),39)
 txt("资源币  "+str(game.career.credits),Vector2(910,126),27,CYAN)
 draw_rect(Rect2(90+inventory_tab*150,226,138,3),CYAN)
 if inventory_tab<4:
  var kind = inventory_kind()
  var base = kind.trim_suffix("+")
  txt("品质与等级",Vector2(116,257),16,MUTED)
  txt("库存",Vector2(378,257),16,MUTED)
  txt("买入 / 售出",Vector2(472,257),16,MUTED)
  for tier in range(6):
   var y = 275+tier*69
   panel(Rect2(90,y-8,880,67),.80)
   draw_rect(Rect2(90,y-8,5,67),Gear.COLORS[tier])
   txt(Gear.loot_name(base,tier,inventory_big),Vector2(114,y+29),23,Gear.COLORS[tier])
   txt("×"+str(game.career.items[kind][tier]),Vector2(378,y+29),23,WHITE,true)
   var value = str(game.career.price(kind,tier))
   if base=="armor" and tier==5:
    value += "/"+str(game.career.resale(kind,tier))
   txt(value,Vector2(472,y+29),15,MUTED)
  txt("装备的最后一件不可直接卖出，先换穿其他装备即可。",Vector2(93,714),16,MUTED)
  txt("小彩虹甲买10555 / 卖10554；大型为基础价格的两倍。",Vector2(93,745),16,MUTED)
  txt("大红珍宝 · 世界奖杯 ×"+str(game.career.trophies),Vector2(93,786),21,Gear.COLORS[4])
 elif inventory_tab==4:
  var descriptions = ["C · 向前跃迁 7 米，遇到掩体会停下","F · 立刻恢复当前盔甲的全部护盾","G · 对 8 米内可见机器人释放引力震波"]
  for i in range(3):
   panel(Rect2(90,260+i*133,880,111),.85)
   txt(game.career.SKILLS[i],Vector2(117,300+i*133),27,CYAN)
   txt(descriptions[i],Vector2(117,339+i*133),18,MUTED)
  txt("彩虹甲额外技能：Q 开启 9999 护盾，无需解锁费用。",Vector2(93,714),19,CYAN)
 else:
  txt("干员装扮",Vector2(145,322),37,Color("72f09b"))
  txt("彩虹裤、六色防护裤、战术泳裤与治疗风衣",Vector2(145,373),20,MUTED)
  txt("H 无限治疗 · V 切换人称 · 裤装页穿戴颜色",Vector2(145,650),18,MUTED)
 txt("装备展示",Vector2(1086,252),22,CYAN)
 txt("干员治疗风衣" if game.career.operator_coat else "战斗装扮",Vector2(1078,702),20,WHITE)
 if not inventory_tab in [1,2]:
  txt("装备、资源、技能均自动保存在本机",Vector2(1020,741),14,MUTED)
 if inventory_status!="":
  txt(inventory_status,Vector2(93,815),17,CYAN)

func build_chest() -> void:
 button("全部领取并存档 / E",Rect2(490,669,460,60),func(): game.expedition.claim_chest(),true)
 button("暂不领取 / Esc",Rect2(490,746,460,48),func(): game.close_backpack())

func draw_chest() -> void:
 draw_rect(Rect2(0,0,1440,900),Color(.015,.035,.065,.87))
 panel(Rect2(410,110,620,715),.97)
 var chest = game.expedition.chests[game.expedition.current_chest]
 txt(chest.name,Vector2(455,170),35,ORANGE)
 txt("打开箱子后领取，战利品会永久保存",Vector2(455,213),19,MUTED)
 var row = 0
 for item in chest.payload:
  var kind = item.kind.trim_suffix("+")
  var name = Gear.loot_name(kind,item.tier,item.kind.ends_with("+"))
  if int(item.get("model",-1))>=0:
   name += " / "+Gear.MODEL_NAMES[item.model]
  txt(name,Vector2(455,272+row*52),23,Gear.COLORS[item.tier])
  row += 1
 txt("资源币 +"+str(chest.money)+"   手榴弹 +"+str(chest.grenades),Vector2(455,535),23,CYAN)
 if chest.cups>0:
  txt("大红珍宝：世界奖杯 ×"+str(chest.cups),Vector2(455,587),24,Gear.COLORS[4])
