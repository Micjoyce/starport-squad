extends RefCounted
const F = preload("res://scripts/factory.gd")
const COLORS = [Color("e9f1f5"),Color("4ca9ff"),Color("be7bff"),Color("ffd45c"),Color("ff4545"),Color("73eadc")]
const NAMES = ["白色 · 基础","蓝色 · 中级","紫色 · 进阶","黄色 · 终极","红色 · 至尊","彩虹 · 幻彩"]
const SHORT = ["白甲 I","蓝甲 II","紫甲 III","黄甲 IV","红甲 V","彩虹甲"]
const SHIELD = [100.0,150.0,200.0,275.0,375.0,1119.0]
const REDUCTION = [0.0,0.08,0.16,0.25,0.35,0.40]
const POWER = [1.0,1.2,1.5,1.85,2.4,3.2]
const RATE = [1.0,0.95,0.90,0.85,0.78,0.70]
const MODES = ["简单","困难","噩梦","超级噩梦","超级困难"]
const DESCRIPTIONS = ["6 个机器人 · 宽容伤害 · 无手榴弹","8 个持枪机器人 · 手榴弹伤害 ×10","10 个机器人 · 全员红枪 · 手榴弹 ×10","20 名同装士兵 + 全套彩虹首领","全员大型彩虹甲 · 精英指挥官无限重生"]
const BOT_COUNTS = [6,8,10,20,20]
const BOT_ARMOR = [[0,0,1,1,2,2],[1,2,2,3,5,4,2,3],[5,3,4,4,4,4,5,4,4,4],[4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4],[5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5]]
const BOT_GUNS = [[0,0,0,1,1,1],[1,2,2,3,3,3,2,3],[4,4,4,4,4,4,4,4,4,4],[4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4],[4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4]]
const MODEL_NAMES = ["AK47","霰弹枪","M4A1","AWM","MP5","M249","彩虹激光枪","AK47M1LW"]
const MODEL_COSTS = [0,0,600,1000,500,900,5000,8000]
const CAPACITY = [30,8,30,5,40,75,24,40]
const BASE_DAMAGE = [26.0,20.0,30.0,105.0,20.0,32.0,180.0,260.0]
const BASE_INTERVAL = [.12,.68,.10,1.0,.075,.085,.16,.11]
const GRENADE_BASE_DAMAGE = 20.0
const GRENADE_MULTIPLIER = 10.0
const GRENADE_RADIUS = 6.5
const GRENADE_FUSE = 2.2

static func color_material(m: StandardMaterial3D, tier: int) -> void:
 var c: Color = COLORS[clampi(tier,0,5)]
 m.albedo_color = c.srgb_to_linear().lerp(c,.3)
 if m.emission_enabled:
  m.emission = c

static func damage(weapon: int, tier: int, distance: float) -> float:
 var level = clampi(tier,0,5)
 if weapon==7:
  return 1200.0+120.0*level
 if weapon==6:
  return 45.0+8.0*level
 var base = BASE_DAMAGE[clampi(weapon,0,7)]
 if weapon==1:
  base = maxf(5,base-distance*.55)
 return base*POWER[level]

static func interval(weapon: int, tier: int) -> float:
 return BASE_INTERVAL[clampi(weapon,0,7)]*RATE[clampi(tier,0,5)]*.70

# Both player and robot weapons use this single model and these same stats.
static func make_weapon(parent: Node3D, kind: int, tier: int) -> Node3D:
 var w = Node3D.new()
 parent.add_child(w)
 var paint = F.mat(COLORS[tier])
 var black = F.mat(Color("111c29"))
 var silver = F.mat(Color("819baa"))
 var wood = F.mat(Color("a86135"))
 var glow = F.mat(COLORS[tier],1.3)
 w.set_meta("paint",paint)
 w.set_meta("glow",glow)
 w.set_meta("kind",kind)
 F.box(w,Vector3(0,0,.03),Vector3(.13,.14,.42),paint)
 F.box(w,Vector3(0,-.13,.14),Vector3(.075,.23,.10),black).rotation.x = -.25
 F.box(w,Vector3(0,-.01,.37),Vector3(.13,.16,.24),wood if kind==0 else paint)
 F.box(w,Vector3(0,-.05,.47),Vector3(.15,.22,.04),black)
 F.box(w,Vector3(0,.09,-.04),Vector3(.06,.035,.20),silver)
 for z in [-.08,-.14,-.20]:
  F.box(w,Vector3(0,.10,z),Vector3(.065,.025,.025),black)
 F.box(w,Vector3(.068,.015,.04),Vector3(.008,.035,.11),glow)
 if kind != 1:
  F.box(w,Vector3(0,-.015,-.27),Vector3(.115,.10,.24),paint)
  var barrel = F.cylinder(w,Vector3(0,0,-.49),.025,.28,black)
  barrel.rotation.x = PI/2
  F.box(w,Vector3(0,.06,-.48),Vector3(.025,.10,.035),silver)
  for j in range(4 if kind in [0,7] else 0):
   var mag = F.box(w,Vector3(0,-.12-j*.055,-.04+j*.017),Vector3(.08,.065,.14),black)
   mag.rotation.x = -j*.1
  F.box(w,Vector3(0,.035,-.64),Vector3(.065,.07,.035),black)
 else:
  var barrel = F.cylinder(w,Vector3(0,.01,-.40),.045,.53,black)
  barrel.rotation.x = PI/2
  var tube = F.cylinder(w,Vector3(0,-.07,-.35),.032,.40,silver)
  tube.rotation.x = PI/2
  F.box(w,Vector3(0,-.055,-.23),Vector3(.14,.13,.21),paint)
  for z in [-.29,-.25,-.21,-.17]:
   F.box(w,Vector3(0,-.06,z),Vector3(.15,.12,.012),black)
  F.box(w,Vector3(0,.095,-.11),Vector3(.09,.08,.11),black)
  F.box(w,Vector3(0,.10,-.17),Vector3(.055,.035,.01),glow)
 if kind in [2,3,4,6]:
  F.box(w,Vector3(0,-.18,.01),Vector3(.085,.24,.15),black)
 if kind==6:
  F.sphere(w,Vector3(0,0,-.25),.11,armor_surface(5))
 if kind==3:
  F.box(w,Vector3(0,.16,-.04),Vector3(.09,.09,.31),black)
  F.box(w,Vector3(0,0,-.75),Vector3(.045,.045,.25),black)
 elif kind==4:
  w.scale = Vector3(.9,.9,.8)
 elif kind==5:
  F.box(w,Vector3(0,-.15,-.05),Vector3(.24,.28,.22),paint)
 elif kind==7:
  F.box(w,Vector3(0,.14,-.06),Vector3(.10,.07,.24),glow)
  for side in [-1,1]:
   F.box(w,Vector3(side*.095,0,-.27),Vector3(.04,.12,.25),F.mat(Color("ffd25e"),.6))
 w.set_meta("base_scale",w.scale)
 F.batch_meshes(w)
 paint_weapon(w,tier)
 return w

static func paint_weapon(w: Node3D, tier: int) -> void:
 color_material(w.get_meta("paint"),tier)
 color_material(w.get_meta("glow"),tier)
 var special = tier==5 or int(w.get_meta("kind"))==6
 var material: Material = armor_surface(5) if special else w.get_meta("paint")
 if int(w.get_meta("kind"))==7:
  color_material(w.get_meta("paint"),4)
  material = w.get_meta("paint")
 for mesh in w.get_children():
  if mesh is MeshInstance3D and (mesh.material_override==w.get_meta("paint") or mesh.has_meta("rainbow_paint")):
   mesh.set_meta("rainbow_paint",true)
   mesh.material_override = material

static func armor_rank(tier: int) -> int:
 return tier

static func armor_surface(tier: int) -> Material:
 if tier==5:
  var material = ShaderMaterial.new()
  material.shader = load("res://scripts/rainbow.gdshader")
  return material
 return F.mat(COLORS[tier])

static func loot_name(kind: String, tier: int, big: bool) -> String:
 var colors = ["白","蓝","紫","金","红","彩虹"]
 return ("大" if big else "小")+colors[tier]+("甲" if kind=="armor" else ("裤" if kind=="pants" else "枪"))

static func make_knife(parent: Node3D) -> Node3D:
 var root = Node3D.new()
 parent.add_child(root)
 F.box(root,Vector3(0,0,0),Vector3(.065,.08,.20),F.mat(Color("162a34")))
 F.box(root,Vector3(0,0,-.12),Vector3(.18,.04,.04),F.mat(Color("4de2ce"),.5))
 F.box(root,Vector3(0,0,-.31),Vector3(.065,.025,.34),F.mat(Color("b7d5e3")))
 return root
