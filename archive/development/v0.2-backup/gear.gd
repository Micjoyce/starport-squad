extends RefCounted
const F = preload("res://scripts/factory.gd")
const COLORS = [Color("e9f1f5"),Color("4ca9ff"),Color("be7bff"),Color("ffd45c"),Color("ff4545")]
const NAMES = ["白色 · 基础","蓝色 · 中级","紫色 · 进阶","黄色 · 终极","红色 · 至尊"]
const SHORT = ["白甲 I","蓝甲 II","紫甲 III","黄甲 IV","红甲 V"]
const SHIELD = [100.0,150.0,200.0,275.0,375.0]
const REDUCTION = [0.0,0.08,0.16,0.25,0.35]
const POWER = [1.0,1.2,1.5,1.85,2.4]
const RATE = [1.0,0.95,0.90,0.85,0.78]
const MODES = ["简单","困难","噩梦"]
const DESCRIPTIONS = ["6 个机器人 · 宽容伤害 · 无手榴弹","8 个持枪机器人 · 手榴弹伤害 ×10","10 个机器人 · 全员红色满级枪 · 手榴弹 ×10"]
const BOT_COUNTS = [6,8,10]
const BOT_ARMOR = [[0,0,1,1,2,2],[1,2,2,3,3,4,2,3],[3,3,4,4,4,4,3,4,4,4]]
const BOT_GUNS = [[0,0,0,1,1,1],[1,2,2,3,3,3,2,3],[4,4,4,4,4,4,4,4,4,4]]
const GRENADE_BASE_DAMAGE = 20.0
const GRENADE_MULTIPLIER = 10.0
const GRENADE_RADIUS = 6.5
const GRENADE_FUSE = 2.2

static func color_material(m: StandardMaterial3D, tier: int) -> void:
 var c: Color = COLORS[clampi(tier,0,4)]
 m.albedo_color = c.srgb_to_linear().lerp(c,.3)
 if m.emission_enabled:
  m.emission = c

static func damage(weapon: int, tier: int, distance: float) -> float:
 var base = 26.0 if weapon == 0 else maxf(5,20-distance*.55)
 return base*POWER[clampi(tier,0,4)]

static func interval(weapon: int, tier: int) -> float:
 return (.12 if weapon==0 else .68)*RATE[clampi(tier,0,4)]

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
 if kind == 0:
  F.box(w,Vector3(0,-.015,-.27),Vector3(.115,.10,.24),paint)
  var barrel = F.cylinder(w,Vector3(0,0,-.49),.025,.28,black)
  barrel.rotation.x = PI/2
  F.box(w,Vector3(0,.06,-.48),Vector3(.025,.10,.035),silver)
  for j in range(4):
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
 F.batch_meshes(w)
 return w

static func paint_weapon(w: Node3D, tier: int) -> void:
 color_material(w.get_meta("paint"),tier)
 color_material(w.get_meta("glow"),tier)
