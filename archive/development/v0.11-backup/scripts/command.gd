extends RefCounted
const F = preload("res://scripts/factory.gd")
const Gear = preload("res://scripts/gear.gd")
const Drone = preload("res://scripts/drone.gd")
const RECRUIT_COST = 1000
const NAMES = ["小白","小蓝","小紫","小金","小红","小彩","大白","大蓝","大紫","大金","大红","大彩"]
const CAPTURE_SECONDS = 8.0
const DEFEND_SECONDS = 20.0
var siege_enabled := true
var order := "attack"
var enemy_castle: Node3D
var enemy_walls: Array[MeshInstance3D] = []
var enemy_core: Node3D
var home_core: Node3D
var capture := 0.0
var enemy_capture := 0.0
var captured := false
var contested := false
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
 build_enemy_castle()

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
  unit.armor_tier = 5 if game.difficulty==4 else game.career.castle_level%6
  unit.armor_big = game.difficulty==4
  unit.weapon_tier = mini(4,game.career.castle_level%6)
  game.regiments.configure_recruit(unit,i)
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
  if is_instance_valid(enemy) and enemy.hp>0 and not enemy.is_boss and not enemy.is_elite:
   count += 1
 if count+10>Gear.BOT_COUNTS[game.difficulty]+10:
  return 0
 if captured or capture>0 or near_core(game.player.position,enemy_castle.global_position,8):
  return 0
 for i in range(10):
  game.spawn_enemy(enemy_spawn(i)+Vector3.UP*.15)
 return 10

func ally_shot(unit: Node3D, origin: Vector3, aim: Vector3) -> void:
 var direction = (aim-origin).normalized()
 var q = PhysicsRayQueryParameters3D.create(origin,origin+direction*(180 if unit.role==1 else 45),5)
 var hit = game.get_world_3d().direct_space_state.intersect_ray(q)
 var end = origin+direction*(180 if unit.role==1 else 40)
 if not hit.is_empty():
  end = hit.position
  if hit.collider.has_method("take_hit"):
   var amount = Gear.damage(unit.weapon_kind,unit.weapon_tier,origin.distance_to(end))*.65
   if hit.collider.has_method("receive_rounds"):
    if not hit.collider.friendly: hit.collider.receive_rounds(1,unit.weapon_kind in [6,9] or unit.weapon_tier==5)
   elif unit.weapon_kind in [6,9]:
    hit.collider.take_laser(amount)
   else:
    hit.collider.take_hit(amount)
 if unit.weapon_kind in [6,9]:
  game.arsenal.shot_trace(origin,end,true)
 else:
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

func tick(dt: float = 1.0/60.0) -> void:
 if not siege_enabled or not game.active or game.mode!="playing" or captured:
  return
 var attackers = 1 if near_core(game.player.position,enemy_castle.global_position,3.2) else 0
 var defenders = 1 if near_core(game.player.position,castle.global_position,4) else 0
 var enemy_home = 0
 var enemy_away = 0
 for unit in game.allies:
  if is_instance_valid(unit) and unit.hp>0 and not unit.get_meta("aboard",false):
   if near_core(unit.position,enemy_castle.global_position,3.2):
    attackers += 1
   if near_core(unit.position,castle.global_position,6):
    defenders += 1
 for unit in game.enemies:
  if is_instance_valid(unit) and unit.hp>0 and not unit.get_meta("aboard",false):
   if near_core(unit.position,enemy_castle.global_position,6):
    enemy_home += 1
   if near_core(unit.position,castle.global_position,3.2):
    enemy_away += 1
 contested = attackers>0 and (enemy_home>0 or (game.difficulty==3 and game.expedition.boss_alive()))
 if attackers>0 and not contested:
  capture = minf(CAPTURE_SECONDS,capture+dt)
 elif attackers==0:
  capture = maxf(0,capture-dt*2)
 if enemy_away>0 and defenders==0:
  enemy_capture = minf(DEFEND_SECONDS,enemy_capture+dt)
 elif enemy_away==0:
  enemy_capture = maxf(0,enemy_capture-dt*2)
 enemy_core.rotation.y += dt*.7
 home_core.rotation.y -= dt*.7
 if capture>=CAPTURE_SECONDS:
  game.win()
  if game.mode=="win":
   captured = true
   battle_started = false
   game.message("敌方城堡已占领 · 获得 1,000,000 金币",6)
 elif enemy_capture>=DEFEND_SECONDS:
  game.active = false
  game.mode = "defeat"
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
  game.hud.show_page("defeat")

func build_enemy_castle() -> void:
 capture = 0
 enemy_capture = 0
 captured = false
 contested = false
 enemy_castle = Node3D.new()
 game.world.add_child(enemy_castle)
 enemy_castle.position = Vector3(0,0,-19)
 enemy_walls.clear()
 var metal = F.mat(Color("713c4c"))
 var light = F.mat(Color("ff6a52"),1.3)
 for side in [-1,1]:
  enemy_walls.append(F.box(enemy_castle,Vector3(side*5,1.8,0),Vector3(.6,3.6,8),metal,true))
  game.blockers.append(Rect2(Vector2(side*5-.7,-23.5),Vector2(1.4,9)))
  for end in [-1,1]:
   enemy_walls.append(F.box(enemy_castle,Vector3(side*3.7,1.8,end*4),Vector3(2.6,3.6,.6),metal,true))
   game.blockers.append(Rect2(Vector2(side*3.7-1.7,-19+end*4-.7),Vector2(3.4,1.4)))
 for x in [-5,5]:
  for z in [-4,4]:
   enemy_walls.append(F.box(enemy_castle,Vector3(x,2.2,z),Vector3(1.2,4.4,1.2),metal,true))
   F.box(enemy_castle,Vector3(x,4.5,z),Vector3(1.5,.18,1.5),light)
 var title = F.text3d(enemy_castle,"敌方城堡 / 占领核心 8 秒",Vector3(0,5,-4),38,Color("ff9875"))
 title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 enemy_core = make_core(enemy_castle,Color("ff745b"))
 home_core = make_core(castle,Color("63ffe1"))

func make_core(parent: Node3D, color: Color) -> Node3D:
 var core = Node3D.new()
 parent.add_child(core)
 var glow = F.mat(color,.8)
 F.cylinder(core,Vector3(0,.035,0),3.2,.04,glow,32)
 for side in [-1,1]:
  F.box(core,Vector3(side*.28,1.2,0),Vector3(.06,1.4,.06),glow)
 var gem = F.box(core,Vector3(0,1.7,0),Vector3(.42,.42,.42),glow)
 gem.rotation.z = PI/4
 return core

func near_core(point: Vector3, center: Vector3, radius: float) -> bool:
 return absf(point.y-center.y)<2.2 and Vector2(point.x-center.x,point.z-center.z).length()<radius*game.expedition.scale_factor

func set_order(value: String) -> bool:
 if value not in ["defend","attack"]:
  return false
 order = value
 for unit in game.allies:
  if is_instance_valid(unit):
   unit.path_timer = 0
   unit.windup = -1
 game.message("全队驻守我方城堡" if order=="defend" else "全队跟随头领，进攻敌方城堡",4)
 return true

func anchor(unit: Node3D) -> Vector3:
 if unit.is_elite:
  return game.rival.tactical_anchor(unit)
 if unit.friendly:
  return castle.global_position if order=="defend" else game.player.position
 return castle.global_position if unit.slot%2==1 and not unit.is_boss and game.elapsed>8 else enemy_castle.global_position

func rally_point(unit: Node3D) -> Vector3:
 var point: Vector3
 if unit.friendly and order=="attack":
  point = game.player.position+unit.formation_offset()
 else:
  var angle = float(unit.slot%10)/10*TAU
  point = anchor(unit)+Vector3(sin(angle)*2.2,0,cos(angle)*2.2)*game.expedition.scale_factor
 var cell = Vector2i(roundi(point.x/game.expedition.scale_factor),roundi(point.z/game.expedition.scale_factor))
 return anchor(unit) if not game.navigation.is_in_boundsv(cell) or game.navigation.is_point_solid(cell) else point

func enemy_spawn(index: int) -> Vector3:
 for attempt in range(160):
  var point = Vector3(game.rng.randi_range(-3,3),.05,-19+game.rng.randi_range(-3,3))*game.expedition.scale_factor
  var valid = true
  for unit in game.enemies:
   if is_instance_valid(unit) and unit.hp>0 and point.distance_to(unit.position)<1.2:
    valid = false
  if valid:
   return point
 return Vector3((index%5-2)*2.0,.05,-26-float(index/5))*game.expedition.scale_factor
