from pathlib import Path
s=Path('outputs/StarportSquad/scripts')
p=s/'career.gd';t=p.read_text().replace('var path :=','var silencer := false\nvar chips := 0\nvar rate_level := 0\nvar mag_level := 0\nvar caliber := 1\nvar pet_kind := 0\nvar horse_owned := false\nvar pet_xp := 0\nvar eggs := [0,0,0,0,0,0]\nvar path :=',1).replace('"version":4,','"version":5,"silencer":silencer,"chips":chips,"rate_level":rate_level,"mag_level":mag_level,"caliber":caliber,"pet_kind":pet_kind,"horse_owned":horse_owned,"pet_xp":pet_xp,"eggs":eggs.duplicate(),');t=t.replace(' castle_level = clampi', ''' silencer = bool(data.get("silencer",false))
 chips = clampi(int(data.get("chips",0)),0,99999)
 rate_level = clampi(int(data.get("rate_level",0)),0,3)
 mag_level = clampi(int(data.get("mag_level",0)),0,2)
 caliber = clampi(int(data.get("caliber",1)),0,4)
 horse_owned = bool(data.get("horse_owned",false))
 pet_kind = clampi(int(data.get("pet_kind",0)),-1,1)
 if pet_kind==1 and not horse_owned:
  pet_kind = 0
 pet_xp = clampi(int(data.get("pet_xp",0)),0,1000000)
 eggs = [0,0,0,0,0,0]
 var egg_data = data.get("eggs",[])
 if egg_data is Array:
  for i in range(mini(6,egg_data.size())):
   eggs[i] = clampi(int(egg_data[i]),0,99999)
 castle_level = clampi''',1).replace('grenades_found: int = 0) -> bool:', 'grenades_found: int = 0, pet_eggs: Array = []) -> bool:').replace(' credits += maxi(0,money)',' for i in range(mini(6,pet_eggs.size())):\n  eggs[i] = mini(99999,eggs[i]+maxi(0,int(pet_eggs[i])))\n credits += maxi(0,money)');t+='''
func workshop(action: String) -> bool:
 var before = snapshot()
 var cost := 0
 match action:
  "silencer":
   if silencer: return false
   cost = 500
   silencer = true
  "chip":
   cost = 300
   chips += 1
  "fuse":
   var needed = 1 if rate_level==0 else 2
   if rate_level>=3 or chips<needed: return false
   chips -= needed
   rate_level += 1
  "magazine":
   if mag_level>=2: return false
   cost = 400
   mag_level += 1
  "caliber": caliber = (caliber+1)%5
  "horse":
   if horse_owned: return false
   cost = 1000
   horse_owned = true
  "feed":
   cost = 50
   pet_xp += 5
  "pet":
   pet_kind = (pet_kind+2)%3-1 if horse_owned else (-1 if pet_kind==0 else 0)
  "eggs":
   var total := 0
   for i in range(6):
    total += eggs[i]*(i+1)
    eggs[i] = 0
   if total==0: return false
   pet_xp += total
  _: return false
 if credits<cost:
  restore(before)
  return false
 credits -= cost
 return commit(before)
''';p.write_text(t)
p=s/'game.gd';t=p.read_text().replace('var wardrobe: RefCounted','const Arsenal = preload("res://scripts/arsenal.gd")\nconst Companions = preload("res://scripts/companions.gd")\nconst UpgradeChecks = preload("res://scripts/upgrade_checks.gd")\nvar arsenal: RefCounted\nvar companions: RefCounted\nvar wardrobe: RefCounted').replace(' setup_inputs()',' arsenal = Arsenal.new()\n arsenal.game = self\n companions = Companions.new()\n companions.game = self\n setup_inputs()',1).replace('"guard":KEY_J,','"workshop":KEY_M,"guard":KEY_J,').replace(' if active and event.is_action_pressed("guard"):', ' if event.is_action_pressed("workshop"):\n  arsenal.toggle_page()\n  return\n if active and event.is_action_pressed("guard"):').replace('["inventory","chest","command"]','["inventory","chest","command","workshop"]').replace('func run_tests() -> void:\n','func run_tests() -> void:\n companions.enabled = false\n').replace(' await RivalChecks.run(self,failures)',' await RivalChecks.run(self,failures)\n await UpgradeChecks.run(self,failures)').replace(' step_grenades(dt)',' arsenal.trace_budget = 4\n companions.tick(dt)\n step_grenades(dt)',1).replace('  g.velocity.y -= 14*dt','  if not g.get("rocket",false):\n   g.velocity.y -= 14*dt').replace('  var q = PhysicsRayQueryParameters3D.create(old,next,1)','  var q = PhysicsRayQueryParameters3D.create(old,next,5 if g.get("friendly",false) and g.get("rocket",false) else (11 if g.get("rocket",false) else 1))').replace(' var g = Node3D.new()\n add_child(g)',' if grenades.size()>=64:\n  return\n var g = Node3D.new()\n add_child(g)',1).replace(' wardrobe.sync()\n\nfunc equip_owned',' wardrobe.sync()\n arsenal.apply_mods()\n\nfunc equip_owned').replace(' command.build_castle()\n build_navigation()',' command.build_castle()\n arsenal.build_city()\n build_navigation()');p.write_text(t)
p=s/'gear.gd';t=p.read_text().replace('"彩虹枪",','"彩虹激光枪",').replace('  return 500.0+100.0*level','  return 45.0+8.0*level');p.write_text(t)
p=s/'player.gd';t=p.read_text().replace('var overcharged := false','var hp := 100.0\nvar max_hp := 100.0\nvar grenade_cooldown := 0.0\nvar overcharged := false').replace(' cooldown = maxf(0, cooldown-dt)',' cooldown -= dt\n grenade_cooldown = maxf(0,grenade_cooldown-dt)').replace(' if Input.is_action_pressed("fire"):\n  shoot()',' if Input.is_action_pressed("fire"):\n  for shot_index in range(32):\n   if cooldown>0: break\n   var before_shots: int = game.shots\n   shoot()\n   if game.shots==before_shots: break\n else:\n  cooldown = maxf(0,cooldown)').replace('cooldown = Gear.interval(weapon_models[weapon],weapon_tiers[weapon])','cooldown += game.arsenal.interval(weapon_models[weapon],weapon_tiers[weapon])').replace(' game.sound("shotgun" if weapon_models[weapon]==1 else "ak")',' if game.arsenal.trace_budget>0:\n  game.sound("shotgun" if weapon_models[weapon]==1 else "ak",.18 if game.career.silencer else .7)').replace('Gear.damage(weapon_models[weapon],weapon_tiers[weapon],distance)*(1.25 if weapon_big[weapon] else 1.0)','Gear.damage(weapon_models[weapon],weapon_tiers[weapon],distance)*(1.25 if weapon_big[weapon] else 1.0)*game.arsenal.caliber_power()').replace('game.tracer(muzzle_position(),end,Color("ffdc9b"),.045)','game.arsenal.shot_trace(muzzle_position(),end,weapon_models[weapon]==6)').replace(' shield -= amount*(1.0-total_reduction())',' if shield>0:\n  var previous = shield\n  shield = maxf(0,shield-amount*(1.0-total_reduction()))\n  if previous>0 and shield==0:\n   game.arsenal.shatter(global_position+Vector3.UP,armor_tier)\n else:\n  hp = maxf(0,hp-amount)').replace(' if shield <= 0:\n  rescue()',' if hp<=0:\n  rescue()').replace('func rescue() -> void:\n shield','func rescue() -> void:\n hp = max_hp\n shield').replace('func coat_heal() -> bool:\n','func coat_heal() -> bool:\n').replace(' shield = max_shield()\n shield_delay = 0\n game.spark',' hp = max_hp\n shield = max_shield()\n shield_delay = 0\n game.spark');start=t.index('func activate_overcharge()');end=t.index('\nfunc throw_player_grenade',start);t=t[:start]+'''func activate_overcharge() -> bool:
 if not game.active:
  return false
 max_hp = 999
 hp = 999
 if armor_tier==5:
  overcharged = true
  shield = 9999.0
 game.message("队长 Q 强化 · 生命 999"+(" / 彩虹护盾 9999" if armor_tier==5 else ""),3)
 return true
'''+t[end:];start=t.index(' if not game.active or game.career.grenades<=0:',t.index('func throw_player_grenade'));end=t.index(' var origin =',start);t=t[:start]+''' if not game.active or grenade_cooldown>0 or game.grenades.size()>=64:
  return false
 grenade_cooldown = .25
'''+t[end:];p.write_text(t)
