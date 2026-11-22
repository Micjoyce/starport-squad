from pathlib import Path
p=Path('outputs/StarportSquad/scripts/player.gd');s=p.read_text()
s=s.replace('const F = preload("res://scripts/factory.gd")','const F = preload("res://scripts/factory.gd")\nconst Gear = preload("res://scripts/gear.gd")')
s=s.replace('var weapon := 0','var armor_tier := 0\nvar weapon_tiers := [0,0]\nvar armor_material: StandardMaterial3D\nvar weapon := 0')
a=s.index(' var steel = F.mat',s.index('func build_weapons'));b=s.index(' flash = Node3D.new()',a)
s=s[:a]+''' armor_material = F.mat(Gear.COLORS[armor_tier])
 var glove = F.mat(Color("111c29"))
 for i in range(2):
  var w = Gear.make_weapon(gun,i,weapon_tiers[i])
  weapons.append(w)
  F.box(w,Vector3(.04,-.17,.18),Vector3(.13,.15,.17),glove).rotation.x = -.3
  F.box(w,Vector3(.09,-.24,.32),Vector3(.17,.15,.32),armor_material).rotation.x = -.35
  F.box(w,Vector3(-.05,-.10,-.20),Vector3(.14,.12,.16),glove)
  F.box(w,Vector3(-.10,-.20,-.03),Vector3(.16,.16,.30),armor_material).rotation.x = .6
  w.visible = i == weapon
'''+s[b:]
s=s.replace('shield = minf(100,shield+dt*10)','shield = minf(max_shield(),shield+dt*10)')
s=s.replace('cooldown = .12 if weapon == 0 else .68','cooldown = Gear.interval(weapon,weapon_tiers[weapon])')
s=s.replace('flash.visible = cooldown > (.085 if weapon == 0 else .59)','flash.visible = cooldown > Gear.interval(weapon,weapon_tiers[weapon])-.035')
s=s.replace('hit.collider.take_hit(26.0 if weapon == 0 else maxf(5,20-distance*.55))','hit.collider.take_hit(Gear.damage(weapon,weapon_tiers[weapon],distance))')
s=s.replace('shield -= amount','shield -= amount*(1.0-Gear.REDUCTION[armor_tier])')
s=s.replace('func rescue() -> void:\n shield = 100','func rescue() -> void:\n shield = max_shield()')
s+='''
func max_shield() -> float:
 return Gear.SHIELD[armor_tier]

func equip_armor(tier: int) -> void:
 armor_tier = clampi(tier,0,4)
 shield = max_shield()
 Gear.color_material(armor_material,armor_tier)

func upgrade_weapon(tier: int) -> void:
 weapon_tiers[weapon] = maxi(weapon_tiers[weapon],clampi(tier,0,4))
 Gear.paint_weapon(weapons[weapon],weapon_tiers[weapon])
 ammo[weapon] = capacity[weapon]
'''
p.write_text(s)
