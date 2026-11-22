from pathlib import Path
p=Path('outputs/StarportSquad/scripts/player.gd');s=p.read_text().replace('var third_person := false','var overcharged := false\nvar armor_big := false\nvar weapon_models := [0,1]\nvar weapon_big := [false,false]\nvar third_person := false')
s=s.replace('  var w = Gear.make_weapon(gun,i,weapon_tiers[i])','  var w = Gear.make_weapon(gun,weapon_models[i],weapon_tiers[i])')
s=s.replace(' if event.is_action_pressed("view_toggle"):', ' if event.is_action_pressed("overcharge"):\n  activate_overcharge()\n if event.is_action_pressed("player_grenade"):\n  throw_player_grenade()\n if event.is_action_pressed("view_toggle"):')
s=s.replace('cooldown = Gear.interval(weapon,weapon_tiers[weapon])','cooldown = Gear.interval(weapon_models[weapon],weapon_tiers[weapon])').replace('flash.visible = cooldown > Gear.interval(weapon,weapon_tiers[weapon])','flash.visible = cooldown > Gear.interval(weapon_models[weapon],weapon_tiers[weapon])')
s=s.replace('game.sound("ak" if weapon == 0 else "shotgun")','game.sound("shotgun" if weapon_models[weapon]==1 else "ak")')
s=s.replace('range(1 if weapon == 0 else 9)','range(9 if weapon_models[weapon]==1 else 1)').replace('if weapon == 0 else (.045','if weapon_models[weapon] != 1 else (.045')
s=s.replace('Gear.damage(weapon,weapon_tiers[weapon],distance)','Gear.damage(weapon_models[weapon],weapon_tiers[weapon],distance)*(1.25 if weapon_big[weapon] else 1.0)')
s=s.replace('shield -= amount*(1.0-Gear.REDUCTION[armor_tier])','shield -= amount*(1.0-total_reduction())')
s=s.replace('position = Vector3(0,.2,23)','position = game.extraction_position+Vector3.UP*.2')
s=s.replace(' return Gear.SHIELD[armor_tier]',' if armor_tier==5 and overcharged:\n  return 9999.0\n return Gear.SHIELD[armor_tier]*(1.2 if armor_big and armor_tier!=5 else 1.0)')
s=s.replace(' armor_tier = clampi(tier,0,5)\n shield',' armor_tier = clampi(tier,0,5)\n overcharged = false\n shield')
s=s.replace('clampi(tier,0,4)','clampi(tier,0,5)')
s=s.replace('   part.material_override = pants_green if green else pants_plain','   part.material_override = pants_green if green else pants_plain\n update_pants_equipment()')
s+='''
func total_reduction() -> float:
 var pants_bonus = 0.0
 if game.career.pants_style>0:
  pants_bonus = game.career.equipped.pants*.02
 return minf(.65,Gear.REDUCTION[armor_tier]+pants_bonus+(.03 if armor_big else 0.0))

func activate_overcharge() -> bool:
 if not game.active or armor_tier!=5:
  if game.active:
   game.message("需要先穿上彩虹甲，才能开启 Q · 9999 护盾",3)
  return false
 overcharged = true
 shield = 9999.0
 game.message("彩虹超载开启 · 护盾上限 9999",3)
 return true

func throw_player_grenade() -> bool:
 if not game.active or game.career.grenades<=0:
  return false
 var before = game.career.snapshot()
 game.career.grenades -= 1
 if not game.career.commit(before):
  return false
 var origin = global_position+Vector3.UP*1.4-global_basis.z*.5
 var target = global_position-global_basis.z*12
 var q = PhysicsRayQueryParameters3D.create(camera.global_position,camera.global_position-camera.global_basis.z*18,1)
 var hit = get_world_3d().direct_space_state.intersect_ray(q)
 if not hit.is_empty():
  target = hit.position
 game.throw_grenade(origin,target,true)
 return true

func update_pants_equipment() -> void:
 if not is_instance_valid(pants):
  return
 var material: Material = pants_green if game.career.green_pants else pants_plain
 if game.career.pants_style>0:
  material = Gear.armor_surface(game.career.equipped.pants)
 for part in pants.get_children():
  if part.has_meta("trousers"):
   part.material_override = material
   part.visible = not (game.career.pants_style==2 and part.position.y<.4)

func set_weapon_models(values: Array) -> void:
 if weapon_models==values:
  return
 weapon_models = values.duplicate()
 for i in range(2):
  var old = weapons[i]
  gun.remove_child(old)
  old.queue_free()
  var w = Gear.make_weapon(gun,weapon_models[i],weapon_tiers[i])
  weapons[i] = w
  var glove = F.mat(Color("111c29"))
  F.box(w,Vector3(.04,-.17,.18),Vector3(.13,.15,.17),glove)
  F.box(w,Vector3(.09,-.24,.32),Vector3(.17,.15,.32),armor_material).set_meta("armor",true)
  F.box(w,Vector3(-.05,-.10,-.20),Vector3(.14,.12,.16),glove)
  F.box(w,Vector3(-.10,-.20,-.03),Vector3(.16,.16,.30),armor_material).set_meta("armor",true)
  w.visible = i==weapon
  capacity[i] = Gear.CAPACITY[weapon_models[i]]
  ammo[i] = capacity[i]
 var old_body = body_model
 remove_child(old_body)
 old_body.queue_free()
 body_model = Operative.make_body(self,armor_material,pants_green,weapon,weapon_tiers,game.career.operator_coat,false,weapon_models)
 refresh_body()
 update_view()
'''
p.write_text(s)
p=Path('outputs/StarportSquad/scripts/operative.gd');s=p.read_text().replace('legs: bool = true)','legs: bool = true, models: Array = [0,1])').replace('Gear.make_weapon(root,i,tiers[i])','Gear.make_weapon(root,models[i],tiers[i])');p.write_text(s)
