extends RefCounted
const Gear = preload("res://scripts/gear.gd")
var game: Node3D
var tutorial_step := 0
var tutorial_origin := "menu"
var deploy_after := false
var grid_page := 0
var selected := -1
const LESSONS = [
 ["欢迎，星港小队的新头领！","先看操作，再安全出发。","W A S D  移动     鼠标  转动视角","Shift  快速跑     空格  跳跃","Ctrl  滑铲：最远 10 米，碰到墙会停下"],
 ["准备好你的大狙","无限子弹 · 零后座力","左键  射击     右键  瞄准     1 / 2  切枪","V  切换人称     Z  趴下     T  无限手雷","到我方城堡梯子下按 E，上平台后趴下打大狙"],
 ["两人配合，驾驶重装载具","灰白旧漆 → 蓝色 → 深绿黑纹","我方城堡两侧是车库，走近坦克或装甲车按 E","WASD 驾驶，AI 炮手协助；X 切换炮手，左键开火","E 下车 · 两名基础乘员 · 总共最多 8 人"],
 ["收拾背包，带领小队出发","装备与金币会自动保存","B  打开格子背包：白 16 → 蓝 32 → 红 48 → 绿 64 格","M  改装武器     K  招兵     J  守城     L  进攻","攻下敌方城堡获得百万金币 · Esc 随时暂停"]]

func open_tutorial(deploy: bool = false) -> void:
 tutorial_origin = game.mode
 deploy_after = deploy
 tutorial_step = 0
 game.active = false
 game.mode = "tutorial"
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 game.hud.show_page("tutorial")

func finish_tutorial() -> void:
 if not game.career.complete_tutorial():
  game.message("教程进度保存失败，请检查存档目录")
  return
 game.mode = tutorial_origin
 if deploy_after or tutorial_origin=="playing":
  game.start_game()
 else:
  game.hud.show_page(tutorial_origin)

func build_tutorial(h: Control) -> void:
 h.button("上一步",Rect2(250,698,180,54),func(): tutorial_step=maxi(0,tutorial_step-1); h.show_page("tutorial")).disabled = tutorial_step==0
 h.button("下一步" if tutorial_step<3 else "看完了，出发！",Rect2(900,698,290,54),func():
  if tutorial_step<3:
   tutorial_step += 1
   h.show_page("tutorial")
  else: finish_tutorial(),true)
 h.button("跳过教程",Rect2(625,698,190,54),func(): finish_tutorial())

func draw_tutorial(h: Control) -> void:
 h.draw_rect(Rect2(0,0,1440,900),Color("0b1929"))
 h.panel(Rect2(210,130,1020,650),.98)
 h.txt("FIELD MANUAL / 新手操作手册",Vector2(250,193),20,h.CYAN)
 h.txt("%02d / 04" % (tutorial_step+1),Vector2(1050,193),23,h.CYAN)
 var lesson = LESSONS[tutorial_step]
 h.txt(lesson[0],Vector2(250,280),36,h.WHITE)
 h.txt(lesson[1],Vector2(250,335),23,h.ORANGE)
 for i in range(3):
  h.panel(Rect2(250,380+i*86,940,68))
  h.txt(lesson[i+2],Vector2(275,423+i*86),22,h.WHITE)
 for i in range(4):
  h.draw_rect(Rect2(250+i*238,654,218,4),h.CYAN if i<=tutorial_step else Color("304655"))

func build_grid(h: Control) -> void:
 var c = game.career
 var entries: Array = c.pack_entries()
 var count: int = maxi(c.pack_capacity(),entries.size())
 grid_page = clampi(grid_page,0,maxi(0,ceili(count/32.0)-1))
 for i in range(32):
  var index: int = grid_page*32+i
  var label = "空格" if index<c.pack_capacity() else "未扩容"
  if index<entries.size():
   var item = entries[index]
   label = Gear.loot_name(item.kind.trim_suffix("+"),item.tier,item.kind.ends_with("+"))+"\n×"+str(item.count)
  var b = h.button(label,Rect2(95+(i%8)*112,278+(i/8)*92,104,82),func(): selected=index; h.refresh_inventory(),selected==index)
  b.add_theme_font_size_override("font_size",14)
  b.disabled = index>=entries.size()
 h.button("上一页",Rect2(95,676,130,44),func(): grid_page-=1; h.refresh_inventory()).disabled = grid_page==0
 h.button("下一页",Rect2(235,676,130,44),func(): grid_page+=1; h.refresh_inventory()).disabled = (grid_page+1)*32>=count
 h.button("背包已满级" if c.backpack_level==3 else "扩容 · %d 金币" % c.PACK_COSTS[c.backpack_level+1],Rect2(1030,310,285,50),func():
  h.inventory_status="背包已扩容并保存" if c.upgrade_pack() else "金币不足或保存失败"
  h.refresh_inventory(),true).disabled = c.backpack_level==3
 h.button("护甲路线已满级" if c.armor_route_level==9 else "升级新护甲 · %d" % ((c.armor_route_level+2)*200),Rect2(1030,470,285,50),func():
  var ok: bool = c.upgrade_armor_route()
  if ok:
   game.player.shield = game.player.max_shield()
   game.player.refresh_body()
  h.inventory_status="新护甲升级并穿戴成功" if ok else "金币不足或保存失败"
  h.refresh_inventory()).disabled = c.armor_route_level==9
 if c.armor_route_level>=0:
  h.button("穿戴新护甲" if not c.armor_route_equipped else "换回原有护甲",Rect2(1030,532,285,46),func():
   var before: Dictionary = c.snapshot()
   c.armor_route_equipped = not c.armor_route_equipped
   if c.commit(before):
    game.player.shield=game.player.max_shield()
    game.apply_career()
   h.refresh_inventory())
 if selected>=0 and selected<entries.size():
  var item = entries[selected]
  h.button("穿戴选中装备",Rect2(400,676,235,44),func(): game.equip_owned(item.kind,item.tier); h.refresh_inventory())
  h.button("出售一件",Rect2(650,676,235,44),func():
   h.inventory_status="出售成功" if c.sell(item.kind,item.tier) else "已装备的最后一件不能卖出"
   h.refresh_inventory()).disabled = not c.can_sell(item.kind,item.tier)

func draw_grid(h: Control) -> void:
 var c = game.career
 h.txt(c.PACK_NAMES[c.backpack_level]+" / %d 格已用，共 %d 格" % [c.pack_used(),c.pack_capacity()],Vector2(95,260),22,c.PACK_COLORS[c.backpack_level])
 h.txt("每格叠放同规格、同品质装备；B 或 Esc 返回",Vector2(95,753),18,h.MUTED)
 h.txt("第 %d 页" % (grid_page+1),Vector2(95,790),18,h.CYAN)
 h.txt("背包扩容",Vector2(1030,275),25,h.WHITE)
 h.txt("白16 → 蓝32 → 红48 → 绿64",Vector2(1030,397),16,h.MUTED)
 h.txt("新护甲："+(c.ARMOR_ROUTE[c.armor_route_level] if c.armor_route_level>=0 else "未购买"),Vector2(1030,447),24,h.CYAN)
 h.txt("白 / 蓝 / 红 / 紫 / 金 / 赤红",Vector2(1030,623),16,h.MUTED)
 h.txt("深红 / 绿 / 浅绿 / 淡黄绿",Vector2(1030,655),16,h.MUTED)
 h.txt("现有彩虹装备继续保留",Vector2(1030,701),17,h.CYAN)
 if c.armor_route_level>=0:
  h.txt("护甲值 %d" % c.ARMOR_ROUTE_HP[c.armor_route_level],Vector2(1030,741),19,h.CYAN)

func draw_vehicle(h: Control) -> void:
 var v = game.vehicles.current
 if v==null: return
 h.panel(Rect2(420,585,600,122),.95)
 h.txt(v.title()+" · "+("驾驶位" if game.vehicles.role==0 else "炮手位"),Vector2(445,619),25,h.CYAN)
 h.txt("耐久 %d%% · 乘员 %d / 8 · AI 驾驶员 / 炮手就位" % [ceili(v.durability*100),v.seats_used()],Vector2(445,654),20,h.WHITE)
 h.txt("WASD 驾驶 · X 换座 · 左键开火 · E 下车",Vector2(445,688),20,h.ORANGE)
