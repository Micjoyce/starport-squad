extends RefCounted
const F = preload("res://scripts/factory.gd")
const Gear = preload("res://scripts/gear.gd")
const Drone = preload("res://scripts/drone.gd")
const RECRUIT_COST = 1000
const NAMES = ["小白","小蓝","小紫","小金","小红","小彩","大白","大蓝","大紫","大金","大红","大彩"]
var battle_started := false
var game: Node3D
var castle: Node3D
var positions: Array[Vector3] = []
var walls: Array[MeshInstance3D] = []
var crown: Node3D
var label: Label3D

func alive_count() -> int:
 var count = 0
 for unit in game.allies:
  if is_instance_valid(unit) and unit.hp>0:
   count += 1
 return count

func build_castle() -> void:
 castle = Node3D.new()
 game.world.add_child(castle)
 castle.position = Vector3(0,0,16)
 walls.clear()
 var metal = F.mat(Color("c3d7e0"))
 # Four solid walls with front and rear gateways. Footprint stays fixed across upgrades.
 for side in [-1,1]:
  walls.append(F.box(castle,Vector3(side*5,1.6,0),Vector3(.6,3.2,8),metal,true))
  game.blockers.append(Rect2(Vector2(side*5-.7,11.5),Vector2(1.4,9)))
  for end in [-1,1]:
   walls.append(F.box(castle,Vector3(side*3.7,1.6,end*4),Vector3(2.6,3.2,.6),metal,true))
   game.blockers.append(Rect2(Vector2(side*3.7-1.7,16+end*4-.7),Vector2(3.4,1.4)))
 for x in [-5,5]:
  for z in [-4,4]:
   walls.append(F.box(castle,Vector3(x,2.0,z),Vector3(1.2,4,1.2),metal,true))
   for tooth in [-1,1]:
    F.box(castle,Vector3(x+tooth*.36,4.2,z),Vector3(.32,.5,1.3),metal)
 crown = Node3D.new()
 castle.add_child(crown)
 for side in [-1,1]:
  F.box(crown,Vector3(side*5,4.4,0),Vector3(.18,.18,7.5),F.mat(Color("53e5da"),1))
 label = F.text3d(castle,"",Vector3(0,4.7,-4),36,Color("8dfce2"))
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 refresh_castle()

func refresh_castle() -> void:
 if not is_instance_valid(castle):
  return
 var level: int = game.career.castle_level
 var surface = Gear.armor_surface(level%6)
 for wall in walls:
  wall.material_override = surface
  wall.scale.y = 1.0+level*.055
 crown.visible = level>=6
 label.text = "头领城堡 / "+NAMES[level]+" / K 建造与招兵"

func upgrade() -> bool:
 if not game.career.upgrade_castle():
  game.message("金币不足或城堡已达到大彩级",3)
  return false
 refresh_castle()
 return true

func recruit() -> bool:
 # One ten-unit squad at a time; survivors must remain with their leader.
 if alive_count()>0 or game.career.credits<RECRUIT_COST:
  game.message("招募需 1000 金币；现有小队全部退场后可再招十人",4)
  return false
 var points: Array[Vector3] = []
 for i in range(10):
  var desired = game.player.position+game.player.global_basis*Vector3((i%5-2)*1.8,0,2.5+float(i/5)*2)
  var cell = Vector2i(roundi(desired.x/game.expedition.scale_factor),roundi(desired.z/game.expedition.scale_factor))
  if not game.navigation.is_in_boundsv(cell) or game.navigation.is_point_solid(cell):
   desired = game.expedition.random_point(1)
  points.append(desired+Vector3.UP*.15)
 var before = game.career.snapshot()
 game.career.credits -= RECRUIT_COST
 if not game.career.commit(before):
  return false
 for unit in game.allies:
  if is_instance_valid(unit):
   unit.queue_free()
 game.allies.clear()
 for i in range(10):
  var unit = CharacterBody3D.new()
  unit.set_script(Drone)
  unit.game = game
  unit.friendly = true
  unit.slot = i
  unit.armor_tier = game.career.castle_level%6
  unit.weapon_tier = mini(4,game.career.castle_level%6)
  game.add_child(unit)
  unit.position = points[i]
  unit.home = points[i]
  game.allies.append(unit)
 enemy_wave()
 battle_started = true
 game.message("十名队友已加入 · 你是头领，队友跟随你；敌方增援十人",5)
 return true

func enemy_wave() -> int:
 game.enemies = game.enemies.filter(func(unit): return is_instance_valid(unit) and unit.hp>0)
 var count = 0
 for enemy in game.enemies:
  if is_instance_valid(enemy) and enemy.hp>0 and not enemy.is_boss:
   count += 1
 if count+10>Gear.BOT_COUNTS[game.difficulty]+10:
  return 0
 for i in range(10):
  var point = game.expedition.random_point(1)
  for attempt in range(80):
   if point.distance_to(game.player.position)>10:
    break
   point = game.expedition.random_point(1)
  game.spawn_enemy(point+Vector3.UP*.15)
 return 10

func ally_shot(unit: Node3D, origin: Vector3, aim: Vector3) -> void:
 var direction = (aim-origin).normalized()
 var q = PhysicsRayQueryParameters3D.create(origin,origin+direction*45,5)
 var hit = game.get_world_3d().direct_space_state.intersect_ray(q)
 var end = origin+direction*40
 if not hit.is_empty():
  end = hit.position
  if hit.collider.has_method("take_hit"):
   hit.collider.take_hit(Gear.damage(unit.weapon_kind,unit.weapon_tier,origin.distance_to(end))*.65)
 game.tracer(origin,end,Color("62ffe1"),.045)

func toggle_page() -> void:
 if game.hud.page=="command":
  game.close_backpack()
  return
 if game.mode=="transit":
  return
 if game.hud.page not in ["inventory","chest"]:
  game.inventory_origin = game.mode
 game.active = false
 if game.mode=="playing":
  game.mode = "paused"
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 game.hud.show_page("command")

func tick() -> void:
 if not battle_started or not game.active:
  return
 for unit in game.enemies:
  if is_instance_valid(unit) and unit.hp>0:
   return
 battle_started = false
 game.win()
