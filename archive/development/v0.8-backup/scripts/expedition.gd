extends RefCounted
const F = preload("res://scripts/factory.gd")
const Gear = preload("res://scripts/gear.gd")
var game: Node3D
var sector := 1
var scale_factor := 1.0
var chests: Array = []
var current_chest := -1
var portal: Node3D
var portal_position := Vector3(0,0,-28)
var spawn_timer := 15.0
var transitioning := false

func random_point(separation: float = 2.2) -> Vector3:
 var candidate = Vector3.ZERO
 for attempt in range(600):
  candidate = Vector3(game.rng.randi_range(-22,22),0,game.rng.randi_range(-26,22))*scale_factor
  var grid = Vector2i(roundi(candidate.x/scale_factor),roundi(candidate.z/scale_factor))
  if game.navigation.is_point_solid(grid):
   continue
  if candidate.distance_to(Vector3(0,0,24)*scale_factor)<5 or candidate.distance_to(portal_position)<4:
   continue
  var blocked = false
  for station in game.pickups:
   if station.pos.distance_to(candidate)<3.3:
    blocked = true
  for loot in game.equipment:
   if loot.pos.distance_to(candidate)<separation:
    blocked = true
  if not blocked:
   return candidate
 return Vector3(10,0,18)*scale_factor

func populate_loot() -> void:
 for tier in range(6):
  for big in [false,true]:
   game.add_equipment(random_point(),"armor",tier,-1,big)
   var model = 7 if tier==4 and big else (6 if tier==5 else game.rng.randi_range(0,5))
   game.add_equipment(random_point(),"gun",tier,model,big)
  game.add_equipment(random_point(),"pants",tier,-1,game.rng.randf()>.5)

func build_portal() -> void:
 portal_position = Vector3(0,0,-28)*scale_factor
 portal = Node3D.new()
 game.world.add_child(portal)
 portal.position = Vector3(0,0,-28)
 var metal = F.mat(Color("425c78"))
 var glow = F.mat(Color("7c88ff"),2)
 for side in [-1,1]:
  F.box(portal,Vector3(side*1.7,1.9,0),Vector3(.45,3.8,.75),metal)
  F.box(portal,Vector3(side*1.42,1.9,-.01),Vector3(.07,3.3,.8),glow)
 F.box(portal,Vector3(0,3.9,0),Vector3(3.8,.4,.75),metal)
 F.box(portal,Vector3(0,.08,0),Vector3(3.5,.12,1.7),glow)
 var label = F.text3d(portal,"02 / NEXUS GATE" if sector==1 else "NEXUS / EXTRACTION",Vector3(0,4.6,0),42,Color("b2a5ff"))
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 if sector==2:
  build_technology()

func build_technology() -> void:
 var glow = F.mat(Color("5a9eff"),1.2)
 var white = F.mat(Color("a2c0d0"))
 for x in [-22,-11,11,22]:
  for z in [-24,-12,0,12,24]:
   # Cosmetic hologram pillars do not block the established navigation lanes.
   F.cylinder(game.world,Vector3(x,3.6,z),.12,7,glow,8)
   F.cylinder(game.world,Vector3(x,6.8,z),.55,.15,white,8)
 for z in range(-28,29,4):
  F.box(game.world,Vector3(0,.035,z),Vector3(42,.02,.04),glow)
 F.text3d(game.world,"N E X U S  /  0 2",Vector3(0,6.5,-30.8),110,Color("8ebaff"))

func nearby_chest() -> int:
 for i in range(chests.size()):
  if not chests[i].looted and game.player.position.distance_to(chests[i].pos)<2.7:
   return i
 return -1

func make_chest(pos: Vector3, armor_tier: int, gun_tier: int, model: int, big: bool = false, boss: bool = false, costume: Dictionary = {}) -> void:
 var root = Node3D.new()
 game.add_child(root)
 root.position = Vector3(pos.x,.08,pos.z)
 var steel = F.mat(Color("374b5e"))
 var dark = F.mat(Color("101e2a"))
 var color = F.mat(Gear.COLORS[armor_tier],.5)
 F.box(root,Vector3(0,.27,0),Vector3(1.05,.55,.68),steel)
 F.box(root,Vector3(0,.29,-.35),Vector3(.78,.28,.025),dark)
 for side in [-1,1]:
  F.box(root,Vector3(side*.44,.27,0),Vector3(.09,.58,.72),dark)
  F.box(root,Vector3(side*.33,.27,-.37),Vector3(.06,.34,.025),color)
 var lid = Node3D.new()
 root.add_child(lid)
 lid.position = Vector3(0,.56,.33)
 F.box(lid,Vector3(0,.055,-.33),Vector3(1.08,.12,.72),dark)
 F.box(root,Vector3(0,.30,-.39),Vector3(.16,.14,.06),color)
 var name = "首领宝箱" if boss else "士兵战利品箱"
 var label = F.text3d(root,name+" / E",Vector3(0,1.10,0),25,Gear.COLORS[armor_tier])
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 var suffix = "+" if big else ""
 var armor_suffix = ("+" if costume.armor_large else "") if costume.has("armor_large") else suffix
 var pants_suffix = ("+" if costume.pants_large else "") if costume.has("pants_large") else suffix
 var payload = [{"kind":"armor"+armor_suffix,"tier":armor_tier},{"kind":"ak"+suffix,"tier":gun_tier,"model":model},{"kind":"pants"+pants_suffix,"tier":costume.get("pants_tier",5 if boss else game.rng.randi_range(0,5))}]
 var cups = 1 if boss or game.rng.randf()<.15 else 0
 if boss:
  payload.append({"kind":"ak+","tier":4,"model":7})
 var trophy: Node3D = null
 if cups>0:
  trophy = Node3D.new()
  root.add_child(trophy)
  trophy.visible = false
  var gold = F.mat(Color("ffc950"),.5)
  F.cylinder(trophy,Vector3(0,.59,0),.17,.06,gold,12)
  F.cylinder(trophy,Vector3(0,.75,0),.04,.28,gold,12)
  F.cylinder(trophy,Vector3(0,.94,0),.18,.22,gold,12)
  for side in [-1,1]:
   F.sphere(trophy,Vector3(side*.22,.95,0),.075,gold)
 chests.append({"trophy":trophy,"node":root,"lid":lid,"pos":pos,"payload":payload,"money":300 if boss else 40+game.difficulty*30,"cups":cups,"grenades":2 if boss else 1,"looted":false,"name":name})

func open_chest(index: int) -> void:
 if index<0 or index>=chests.size() or chests[index].looted:
  return
 current_chest = index
 if is_instance_valid(chests[index].trophy):
  chests[index].trophy.visible = true
 game.inventory_origin = game.mode
 game.mode = "paused"
 game.active = false
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 var tween = game.create_tween()
 tween.tween_property(chests[index].lid,"rotation:x",-.95,.25)
 game.hud.show_page("chest")

func claim_chest() -> bool:
 if current_chest<0 or current_chest>=chests.size():
  return false
 var chest = chests[current_chest]
 if chest.looted:
  return false
 if not game.career.grant_loot(chest.payload,chest.money,chest.cups,chest.grenades):
  game.message("存档写入失败，箱内战利品仍保留",3)
  return false
 chest.looted = true
 if is_instance_valid(chest.trophy):
  chest.trophy.visible = false
 game.message("战利品、资源、手榴弹已永久保存",4)
 game.close_backpack()
 return true

func tick(dt: float) -> void:
 if not game.active or transitioning or game.test_mode:
  return
 spawn_timer -= dt
 if spawn_timer>0:
  return
 spawn_timer = [18.0,14.0,10.0,8.0,8.0][game.difficulty]
 var alive = 0
 for enemy in game.enemies:
  if is_instance_valid(enemy) and enemy.hp>0 and not enemy.is_boss and not enemy.is_elite:
   alive += 1
 if alive<Gear.BOT_COUNTS[game.difficulty]:
  game.command.enemy_wave()

func near_portal() -> bool:
 return game.player.position.distance_to(portal_position)<3.2

func travel() -> void:
 if transitioning or game.cells<3:
  return
 if game.difficulty==3 and boss_alive():
  game.message("击败彩虹首领后，才能使用这座传送门",4)
  return
 if sector==2:
  game.win()
  return
 transitioning = true
 game.rival.reset()
 game.active = false
 game.mode = "transit"
 for enemy in game.enemies:
  if is_instance_valid(enemy):
   enemy.queue_free()
 game.enemies.clear()
 for array in [game.effects,game.bolts,game.grenades]:
  for fx in array:
   if is_instance_valid(fx.node):
    fx.node.queue_free()
   if fx.has("ring"):
    fx.ring.queue_free()
  array.clear()
 for chest in chests:
  chest.node.queue_free()
 chests.clear()
 game.remove_child(game.world)
 game.world.queue_free()
 for child in game.get_children():
  if child is WorldEnvironment or child is DirectionalLight3D:
   child.queue_free()
 game.equipment.clear()
 game.pickups.clear()
 game.resources.clear()
 game.blockers.clear()
 await game.get_tree().process_frame
 sector = 2
 scale_factor = sqrt(2.0)
 game.victory_paid = false
 game.cells = 0
 game.elapsed = 0
 game.extraction = 0
 game.extracting = false
 game.extraction_position = Vector3(0,0,24)*scale_factor
 game.build_world()
 game.player.position = game.extraction_position+Vector3.UP*.2
 game.player.velocity = Vector3.ZERO
 game.spawn_enemies()
 for ally in game.allies:
  if is_instance_valid(ally) and ally.hp>0:
   ally.position = game.player.position+ally.formation_offset()
   ally.path_timer = 0
 game.command.battle_started = false
 for ally in game.allies:
  if is_instance_valid(ally) and ally.hp>0 and game.command.order=="defend":
   ally.position = game.command.rally_point(ally)
   ally.path_timer = 0
 transitioning = false
 game.start_game()
 game.message("进入 NEXUS 科技区 · 地面面积为星港的 2 倍",6)

func boss_alive() -> bool:
 for enemy in game.enemies:
  if is_instance_valid(enemy) and enemy.is_boss and enemy.hp>0:
   return true
 return false
