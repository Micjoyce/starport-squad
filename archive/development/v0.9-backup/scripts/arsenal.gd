extends RefCounted
const F = preload("res://scripts/factory.gd")
const Gear = preload("res://scripts/gear.gd")
const CALIBERS = [3,10,20,100,1000]
const MAX_RPS = 1200.0
var game: Node3D
var trace_budget := 4
var section := 0
var status := ""

func interval(model: int, tier: int) -> float:
 return maxf(1.0/MAX_RPS,Gear.interval(model,tier)*.25/pow(20.0,game.career.rate_level))

func caliber_power() -> float:
 return [.7,1.0,1.3,1.6,2.0][game.career.caliber]

func apply_mods() -> void:
 if not is_instance_valid(game.player): return
 for i in range(2):
  game.player.capacity[i] = Gear.CAPACITY[game.player.weapon_models[i]]*(game.career.mag_level+1)
  game.player.ammo[i] = mini(game.player.ammo[i],game.player.capacity[i])
  var guns = [game.player.weapons[i],game.player.body_model.get_meta("guns")[i]]
  for gun in guns:
   if not gun.has_meta("silencer"):
    var attachment = F.cylinder(gun,Vector3(0,0,-.80),.05,.34,F.mat(Color("223442")),10)
    attachment.rotation.x = PI/2
    gun.set_meta("silencer",attachment)
   gun.get_meta("silencer").visible = game.career.silencer

func shot_trace(from: Vector3, to: Vector3, laser: bool) -> void:
 if trace_budget<=0: return
 trace_budget -= 1
 if laser:
  trace_budget = 0
  var colors = ["ff4848","ffac45","ffed4d","4eff9a","4dabff","b876ff"]
  for i in range(6):
   game.tracer(from+Vector3.UP*(i-2.5)*.018,to+Vector3.UP*(i-2.5)*.018,Color(colors[i]),.07)
 else:
  game.tracer(from,to,Color("ffdc9b"),.045)

func shatter(pos: Vector3, tier: int) -> void:
 while game.effects.size()>200:
  var old = game.effects.pop_front()
  if is_instance_valid(old.node): old.node.queue_free()
 var surface = F.mat(Gear.COLORS[tier],.6)
 for i in range(mini(28,maxi(0,240-game.effects.size()))):
  var shard = F.box(game,pos+Vector3(game.rng.randf_range(-.35,.35),game.rng.randf_range(-.4,.5),game.rng.randf_range(-.3,.3)),Vector3(.09,.045,.13),surface)
  shard.rotation = Vector3(game.rng.randf(),game.rng.randf(),game.rng.randf())*TAU
  game.effects.append({"node":shard,"life":.8,"velocity":Vector3(game.rng.randf_range(-5,5),game.rng.randf_range(1,5),game.rng.randf_range(-5,5))})
 game.sound("break",.55)

func rocket(origin: Vector3, target: Vector3, friendly: bool) -> void:
 if game.grenades.size()>=64: return
 game.throw_grenade(origin,target,friendly)
 var shot = game.grenades.back()
 shot.rocket = true
 shot.velocity = (target-origin).normalized()*25
 shot.fuse = 3.0
 shot.damage = 180.0
 var tube = F.cylinder(shot.node,Vector3.ZERO,.12,.7,F.mat(Color("a9bcc5")),8)
 tube.rotation.x = PI/2
 shot.node.look_at(target,Vector3.UP)
 F.sphere(shot.node,Vector3(0,0,.38),.17,F.mat(Color("ffac45"),2))

func build_city() -> void:
 var metal = F.mat(Color("314454"))
 var glow = F.mat(Color("ff745b"),.8)
 for side in [-1,1]:
  for z in [-18,-28]:
   var x = side*10
   var h = 6.0 if z==-18 else 9.0
   game.solid(Vector3(x,h/2,z),Vector3(3.5,h,3.5),metal)
   for floor_index in range(2,int(h),2):
    F.box(game.world,Vector3(x,floor_index,z+1.77),Vector3(2.8,.45,.04),glow)
 F.text3d(game.world,"ENEMY / NEON DISTRICT",Vector3(0,9.3,-31),70,Color("ffad83"))

func toggle_page() -> void:
 if game.hud.page=="workshop":
  game.close_backpack()
  return
 if game.mode=="transit": return
 if game.hud.page not in ["inventory","chest","command"]:
  game.inventory_origin = game.mode
 game.active = false
 if game.mode=="playing": game.mode = "paused"
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 game.hud.show_page("workshop")

func act(action: String) -> void:
 status = "已保存" if game.career.workshop(action) else "金币、芯片不足，或已达到最高级"
 apply_mods()
 game.companions.sync_pet()
 game.hud.show_page("workshop")

func build_page(hud: Control) -> void:
 hud.button("返回 / M",Rect2(1050,102,220,44),func(): game.close_backpack(),true)
 hud.button("军械改装",Rect2(170,180,250,48),func(): section=0; hud.show_page("workshop"),section==0)
 hud.button("宠物与补给蛋",Rect2(435,180,250,48),func(): section=1; hud.show_page("workshop"),section==1)
 if section==0:
  var labels = ["购买消音器 · 500","购买射速芯片 · 300","安装 / 融合射速芯片","升级弹夹 · 400","切换科幻弹药规格"]
  var actions = ["silencer","chip","fuse","magazine","caliber"]
  for i in range(5):
   var action: String = actions[i]
   hud.button(labels[i],Rect2(170,275+i*90,450,60),func(): act(action))
 else:
  var labels = ["切换：狗 / 马 / 收回","领养破甲战马 · 1000","喂养训练 · 50","打开全部宠物补给蛋"]
  var actions = ["pet","horse","feed","eggs"]
  for i in range(4):
   var action: String = actions[i]
   hud.button(labels[i],Rect2(170,290+i*100,450,62),func(): act(action))

func draw_page(hud: Control) -> void:
 hud.draw_rect(Rect2(0,0,1440,900),Color(.015,.035,.065,.94))
 hud.panel(Rect2(110,65,1220,760),.96)
 hud.txt("星港补给站",Vector2(170,140),38,hud.CYAN)
 hud.txt("金币 "+str(game.career.credits),Vector2(780,140),26,hud.ORANGE)
 if section==0:
  hud.txt("消音器："+("已安装" if game.career.silencer else "未安装"),Vector2(690,312),23)
  hud.txt("备用芯片："+str(game.career.chips),Vector2(690,380),23)
  hud.txt("射速等级 %d · 理论倍率 ×%d" % [game.career.rate_level,int(pow(20,game.career.rate_level))],Vector2(690,430),23,hud.ORANGE)
  hud.txt("当前最高 %.0f 发 / 秒" % (1.0/interval(game.player.weapon_models[game.player.weapon],game.player.weapon_tiers[game.player.weapon])),Vector2(690,480),23,hud.CYAN)
  hud.txt("弹夹容量 ×"+str(game.career.mag_level+1),Vector2(690,550),23)
  hud.txt("科幻弹药：%d mm" % CALIBERS[game.career.caliber],Vector2(690,625),25)
  hud.txt("一级消耗 1 芯片；后续融合消耗 2 芯片。",Vector2(690,690),18,hud.MUTED)
  hud.txt("每级 ×20；模拟射速上限 1200 发 / 秒。",Vector2(690,724),18,hud.MUTED)
 else:
  hud.txt("伙伴："+["宠物狗","破甲战马","已收回"][game.career.pet_kind if game.career.pet_kind>=0 else 2],Vector2(690,310),28,hud.CYAN)
  hud.txt("训练等级 "+str(1+game.career.pet_xp/20),Vector2(690,365),25)
  hud.txt("狗会咬敌人；战马能直接击碎盔甲。",Vector2(690,420),21)
  hud.txt("击败敌人的箱内可获得宠物补给蛋：",Vector2(690,485),19,hud.MUTED)
  for i in range(6):
   hud.txt(game.companions.EGG_NAMES[i]+"  ×"+str(game.career.eggs[i]),Vector2(700+(i%2)*220,535+int(i/2)*50),23,Gear.COLORS[maxi(0,i-1)])
  hud.txt("补给蛋各自独立掉落，红蛋保证掉落。",Vector2(690,720),18,hud.MUTED)
 hud.txt(status,Vector2(170,790),20,hud.CYAN)
