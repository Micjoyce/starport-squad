from pathlib import Path
p=Path('outputs/StarportSquad/scripts/game.gd');s=p.read_text().replace('var career: RefCounted','const Expedition = preload("res://scripts/expedition.gd")\nvar expedition: RefCounted\nvar career: RefCounted')
s=s.replace(' setup_inputs()\n load_settings()',' if not test_mode and not smoke_mode:\n  rng.randomize()\n expedition = Expedition.new()\n expedition.game = self\n setup_inputs()\n load_settings()')
s=s.replace(' if test_mode:\n  difficulty = 0\n elif "--nightmare"',' difficulty = 0\n if "--super-nightmare" in OS.get_cmdline_user_args():\n  difficulty = 3\n elif "--nightmare"')
s=s.replace(' career.load_profile()',' career.load_profile()\n career.grenades = maxi(3,career.grenades)',1)
s=s.replace('"skill_dash":KEY_Q','"skill_dash":KEY_C').replace('"coat_heal":KEY_H}','"coat_heal":KEY_H,"overcharge":KEY_Q,"player_grenade":KEY_T}')
s=s.replace('get("game","difficulty",0)),0,2)','get("game","difficulty",0)),0,3)').replace('difficulty = clampi(value,0,2)','difficulty = clampi(value,0,3)')
s=s.replace(' build_equipment()\n\nfunc batch_static_geometry',' build_equipment()\n expedition.build_portal()\n world.scale = Vector3(expedition.scale_factor,1,expedition.scale_factor)\n\nfunc batch_static_geometry')
s=s.replace('pickups.append({"node":root,"item":item,"pos":pos,','pickups.append({"node":root,"item":item,"pos":pos*expedition.scale_factor,')
s=s.replace('roundi(from.x),roundi(from.z)','roundi(from.x/expedition.scale_factor),roundi(from.z/expedition.scale_factor)').replace('roundi(to.x),-26,26','roundi(to.x/expedition.scale_factor),-26,26').replace('roundi(to.z),-30,30','roundi(to.z/expedition.scale_factor),-30,30')
s=s.replace(' return navigation.get_point_path(a,b)',' var points = navigation.get_point_path(a,b)\n for i in range(points.size()):\n  points[i] *= expedition.scale_factor\n return points')
a=s.index('func spawn_enemies()');b=s.index('\nfunc start_game()',a)
s=s[:a]+'''func spawn_enemies() -> void:
 for i in range(Gear.BOT_COUNTS[difficulty]):
  var pos = expedition.random_point(1)
  for attempt in range(100):
   var valid = true
   for enemy in enemies:
    if is_instance_valid(enemy) and enemy.position.distance_to(pos)<2:
     valid = false
   if valid:
    break
   pos = expedition.random_point(1)
  spawn_enemy(pos+Vector3.UP*.1)
 if difficulty==3:
  spawn_enemy(Vector3(0,.1,-24)*expedition.scale_factor,true)

func spawn_enemy(pos: Vector3, boss: bool = false) -> Node3D:
 var bot = CharacterBody3D.new()
 bot.set_script(DroneScript)
 bot.game = self
 var index = enemies.size()%Gear.BOT_COUNTS[difficulty]
 bot.armor_tier = 5 if boss else Gear.BOT_ARMOR[difficulty][index]
 bot.weapon_tier = 5 if boss else Gear.BOT_GUNS[difficulty][index]
 bot.weapon_kind = 7 if boss else index%2
 bot.is_boss = boss
 bot.hp = 999.0 if boss else 100.0
 bot.big = difficulty==3 or rng.randf()>.65
 add_child(bot)
 bot.position = pos
 bot.home = pos
 enemies.append(bot)
 return bot
'''+s[b:]
s=s.replace('  elapsed += dt','  expedition.tick(dt)\n  elapsed += dt',1)
s=s.replace('absf(player.position.x)>23 or player.position.z < -28','absf(player.position.x)>23*expedition.scale_factor or player.position.z < -28*expedition.scale_factor')
s=s.replace('func interact() -> void:\n var i','func interact() -> void:\n if expedition.near_portal():\n  if cells>=3:\n   expedition.travel()\n  else:\n   message("收齐 3 块能源后即可使用科技传送门",3)\n  return\n if expedition.nearby_chest()>=0:\n  expedition.open_chest(expedition.nearby_chest())\n  return\n var i')
# Energy C is close to the gate: keep collection ahead of gate proximity until all cells collected.
s=s.replace('if expedition.near_portal():\n  if cells>=3:','if expedition.near_portal() and nearby_cell()<0:\n  if cells>=3:')
s=s.replace('if event.is_action_pressed("pause") and hud.page=="inventory":','if event.is_action_pressed("pause") and hud.page in ["inventory","chest"]:')
a=s.index('func build_equipment()');b=s.index('\nfunc add_equipment',a)
s=s[:a]+'''func build_equipment() -> void:
 expedition.populate_loot()
'''+s[b:]
s=s.replace('weapon_kind: int = -1) -> void:\n var root','weapon_kind: int = -1, big: bool = false) -> void:\n var root')
s=s.replace('root.position = Vector3(pos.x,.08,pos.z)','root.position = Vector3(pos.x/expedition.scale_factor,.08,pos.z/expedition.scale_factor)\n root.scale = Vector3(1/expedition.scale_factor,1,1/expedition.scale_factor)')
s=s.replace(' if kind == "armor":\n  F.box(item',' if kind in ["armor","pants"]:\n  F.box(item')
s=s.replace('tier,"weapon_kind":weapon_kind,"taken":false','tier,"weapon_kind":weapon_kind,"big":big,"taken":false')
s=s.replace('(Gear.SHORT[tier] if kind=="armor" else Gear.NAMES[tier].split(" · ")[0]+"枪械升级")','Gear.loot_name(kind,tier,big)')
s=s.replace('var kind: String = "armor" if item.kind=="armor" else ("ak" if target_weapon==0 else "sg")','var kind: String = item.kind if item.kind in ["armor","pants"] else ("ak" if player.weapon==0 else "sg")\n var base = kind\n kind += "+" if item.get("big",false) else ""')
s=s.replace('career.equip("armor",item.tier)','career.equip(kind,item.tier)').replace('Gear.armor_rank(item.tier)>=Gear.armor_rank(player.armor_tier)','Gear.armor_rank(item.tier)*2+int(item.get("big",false))>=Gear.armor_rank(player.armor_tier)*2+int(player.armor_big)')
s=s.replace('  player.equip_armor(item.tier)\n  career.equip(kind,item.tier)','  career.equip(kind,item.tier)\n  player.armor_big = bool(item.get("big",false))\n  player.equip_armor(item.tier)')
s=s.replace('  player.switch_weapon(target_weapon)\n  player.upgrade_weapon(item.tier)\n  career.equip(kind,item.tier)','  target_weapon = player.weapon\n  if item.weapon_kind>=0 and item.weapon_kind<8:\n   if not item.weapon_kind in career.owned_models:\n    career.owned_models.append(item.weapon_kind)\n   career.models[base] = item.weapon_kind\n  career.equip(kind,item.tier)\n  apply_career()')
s=s.replace(' item.taken = true\n item.node.visible = false\n sound("pickup")\n message(Gear.NAMES', ' if item.kind=="pants":\n  career.equip(kind,item.tier)\n  player.update_pants_equipment()\n item.taken = true\n item.node.visible = false\n sound("pickup")\n message(Gear.NAMES')
s=s.replace('player.weapon_tiers[target_weapon]','player.weapon_tiers[player.weapon]')
s=s.replace('func apply_career() -> void:\n player.equip_armor','func apply_career() -> void:\n player.armor_big = career.sizes.armor==1\n player.weapon_big = [career.sizes.ak==1,career.sizes.sg==1]\n player.equip_armor')
s=s.replace(' player.weapon_tiers = [career.equipped.ak,career.equipped.sg]',' player.weapon_tiers = [career.equipped.ak,career.equipped.sg]\n player.set_weapon_models([career.models.ak,career.models.sg])')
s=s.replace('*(.45 if difficulty==1 else .65)','*(.45 if difficulty==1 else (1.30 if difficulty==3 else .65))')
s=s.replace('func throw_grenade(origin: Vector3, target: Vector3) -> void:','func throw_grenade(origin: Vector3, target: Vector3, friendly: bool = false) -> void:')
s=s.replace('"damage":Gear.GRENADE_BASE_DAMAGE*Gear.GRENADE_MULTIPLIER','"friendly":friendly,"damage":Gear.GRENADE_BASE_DAMAGE*Gear.GRENADE_MULTIPLIER*(2 if difficulty==3 and not friendly else 1)')
s=s.replace('explode_grenade(g.node.position,g.damage)','explode_grenade(g.node.position,g.damage,g.get("friendly",false))')
s=s.replace('func explode_grenade(origin: Vector3, amount: float) -> void:','func explode_grenade(origin: Vector3, amount: float, friendly: bool = false) -> void:\n if friendly:\n  for enemy in enemies:\n   if is_instance_valid(enemy) and enemy.hp>0:\n    var target = enemy.position+Vector3.UP\n    var distance = origin.distance_to(target)\n    var q = PhysicsRayQueryParameters3D.create(origin,target,1)\n    if distance<Gear.GRENADE_RADIUS and get_world_3d().direct_space_state.intersect_ray(q).is_empty():\n     enemy.take_hit(amount*(1-.65*distance/Gear.GRENADE_RADIUS))')
s=s.replace(' if not game.active or transitioning:',' if not game.active or transitioning:')
p.write_text(s)
p=Path('outputs/StarportSquad/scripts/expedition.gd');s=p.read_text().replace('if not game.active or transitioning:','if not game.active or transitioning or game.test_mode:');p.write_text(s)
p=Path('outputs/StarportSquad/scripts/drone.gd');s=p.read_text().replace('var hp := 100.0','var is_boss := false\nvar big := false\nvar hp := 100.0\nvar max_hp := 100.0')
s=s.replace(' armor = Gear.SHIELD[armor_tier]',' max_hp = hp\n armor = Gear.SHIELD[armor_tier]')
s=s.replace(' ammo = 30 if weapon_kind==0 else 8',' ammo = Gear.CAPACITY[weapon_kind]')
s=s.replace('Gear.SHORT[armor_tier]+" / "+("AK47" if weapon_kind==0 else "SG")','("首领 / 彩虹全套" if is_boss else Gear.SHORT[armor_tier])+" / "+Gear.MODEL_NAMES[weapon_kind]')
s=s.replace(' health_bar.visible = false',' health_bar.visible = false\n if armor_tier==5:\n  var rainbow = Gear.armor_surface(5)\n  for part in model.get_children():\n   if part is MeshInstance3D and part.material_override==body_material:\n    part.material_override = rainbow')
s=s.replace('(100+Gear.SHIELD[armor_tier])','(max_hp+Gear.SHIELD[armor_tier])')
s=s.replace('  game.drop_equipment(global_position,armor_tier,weapon_tier,weapon_kind)\n  game.drop_resources(global_position,40+game.difficulty*30)','  game.expedition.make_chest(global_position,armor_tier,weapon_tier,weapon_kind,big,is_boss)')
p.write_text(s)
