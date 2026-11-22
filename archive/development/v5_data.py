from pathlib import Path
p=Path('outputs/StarportSquad/scripts/gear.gd');s=p.read_text().replace('375.0,325.0','375.0,1119.0').replace('0.35,0.30','0.35,0.40').replace('[1.0,1.2,1.5,1.85,2.4]','[1.0,1.2,1.5,1.85,2.4,3.2]').replace('[1.0,0.95,0.90,0.85,0.78]','[1.0,0.95,0.90,0.85,0.78,0.70]')
s=s.replace('["简单","困难","噩梦"]','["简单","困难","噩梦","超级噩梦"]').replace('"10 个机器人 · 全员红色满级枪 · 手榴弹 ×10"]','"10 个机器人 · 全员红枪 · 手榴弹 ×10","20 名红甲士兵 + 全套彩虹首领"]')
s=s.replace('[6,8,10]','[6,8,10,20]').replace('[3,3,4,4,4,4,3,4,4,4]]','[5,3,4,4,4,4,5,4,4,4],[4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4]]').replace('[4,4,4,4,4,4,4,4,4,4]]','[4,4,4,4,4,4,4,4,4,4],[4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4]]',1) if False else s
# Explicit mode distributions to avoid touching unrelated arrays.
a=s.index('const BOT_ARMOR');b=s.index('const GRENADE_BASE_DAMAGE',a)
s=s[:a]+'''const BOT_ARMOR = [[0,0,1,1,2,2],[1,2,2,3,5,4,2,3],[5,3,4,4,4,4,5,4,4,4],[4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4]]
const BOT_GUNS = [[0,0,0,1,1,1],[1,2,2,3,3,3,2,3],[4,4,4,4,4,4,4,4,4,4],[4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4]]
const MODEL_NAMES = ["AK47","霰弹枪","M4A1","AWM","MP5","M249","彩虹枪","AK47M1LW"]
const MODEL_COSTS = [0,0,600,1000,500,900,5000,8000]
const CAPACITY = [30,8,30,5,40,75,24,40]
const BASE_DAMAGE = [26.0,20.0,30.0,105.0,20.0,32.0,180.0,260.0]
const BASE_INTERVAL = [.12,.68,.10,1.0,.075,.085,.16,.11]
'''+s[b:]
a=s.index(' var base =',s.index('static func damage'));b=s.index('\n# Both player',a)
s=s[:a]+''' var level = clampi(tier,0,5)
 if weapon==7:
  return 1200.0+120.0*level
 if weapon==6:
  return 500.0+100.0*level
 var base = BASE_DAMAGE[clampi(weapon,0,7)]
 if weapon==1:
  base = maxf(5,base-distance*.55)
 return base*POWER[level]

static func interval(weapon: int, tier: int) -> float:
 return BASE_INTERVAL[clampi(weapon,0,7)]*RATE[clampi(tier,0,5)]
'''+s[b:]
s=s.replace(' if kind == 0:',' if kind != 1:').replace(' return 4 if tier==5 else (5 if tier==4 else tier)',' return tier')
s=s.replace(' F.batch_meshes(w)\n return w',''' if kind==3:
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
 F.batch_meshes(w)
 paint_weapon(w,tier)
 return w''')
s=s.replace(' color_material(w.get_meta("glow"),tier)',''' color_material(w.get_meta("glow"),tier)
 var special = tier==5 or int(w.get_meta("kind"))==6
 var material: Material = armor_surface(5) if special else w.get_meta("paint")
 if int(w.get_meta("kind"))==7:
  color_material(w.get_meta("paint"),4)
  material = w.get_meta("paint")
 for mesh in w.get_children():
  if mesh is MeshInstance3D and (mesh.material_override==w.get_meta("paint") or mesh.has_meta("rainbow_paint")):
   mesh.set_meta("rainbow_paint",true)
   mesh.material_override = material''')
s+='''
static func loot_name(kind: String, tier: int, big: bool) -> String:
 var colors = ["白","蓝","紫","金","红","彩虹"]
 return ("大" if big else "小")+colors[tier]+("甲" if kind=="armor" else ("裤" if kind=="pants" else "枪"))
'''
p.write_text(s)
