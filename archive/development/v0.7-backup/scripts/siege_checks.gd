extends RefCounted
const Career = preload("res://scripts/career.gd")
static func run(game: Node3D, failures: Array[String]) -> void:
 var original = game.career
 var profile = Career.new()
 profile.path = ""
 profile.credits = 10000
 game.career = profile
 game.command.siege_enabled = true
 game.command.captured = false
 game.command.capture = 0
 game.command.enemy_capture = 0
 game.difficulty = 0
 game.victory_paid = false
 game.mode = "playing"
 game.active = true
 game.extracting = false
 var player = game.player
 player.set_physics_process(false)
 for unit in game.enemies:
  if is_instance_valid(unit):
   unit.queue_free()
 game.enemies.clear()
 await game.get_tree().physics_frame
 game.check(is_instance_valid(game.command.enemy_castle) and game.command.enemy_walls.size()==10,"enemy has a distinct complete fortified castle",failures)
 var base = game.command.castle.global_position
 var core = game.command.enemy_castle.global_position
 game.check(base.distance_to(core)>30,"opposing castles occupy separate ends of the battlefield",failures)
 var wall = game.command.enemy_walls[0]
 var hit = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(wall.global_position-Vector3.RIGHT*3,wall.global_position+Vector3.RIGHT*3,1))
 game.check(not hit.is_empty(),"enemy castle walls also block actual bullet raycasts",failures)
 var path = game.find_path(base,core)
 game.check(path.size()>1,"navigation connects both castles through open gateways",failures)
 # Physically walk the leader along the navigation route into the opposing core.
 player.position = base+Vector3.UP*.1
 player.rotation = Vector3.ZERO
 player.velocity = Vector3.ZERO
 game.command.siege_enabled = false
 player.set_physics_process(true)
 var reached = true
 for waypoint in path:
  var goal = Vector3(waypoint.x,player.position.y,waypoint.y)
  var frames = 0
  while Vector2(player.position.x-goal.x,player.position.z-goal.z).length()>.38 and frames<90:
   goal.y = player.position.y
   player.look_at(goal,Vector3.UP)
   Input.action_press("forward")
   Input.action_press("sprint")
   await game.get_tree().physics_frame
   frames += 1
  if frames>=90:
   reached = false
   break
 Input.action_release("forward")
 Input.action_release("sprint")
 game.check(reached and player.position.distance_to(core)<2,"player can physically traverse the battlefield and enemy castle gate",failures)
 player.set_physics_process(false)
 game.command.siege_enabled = true
 player.position = base+Vector3.UP*.1
 game.check(game.command.recruit(),"siege squad recruitment remains available",failures)
 for unit in game.enemies:
  unit.set_physics_process(false)
  unit.position = Vector3(22,.1,0)*game.expedition.scale_factor
 for ally in game.allies:
  ally.set_physics_process(false)
 var soldier = game.allies[0]
 soldier.position = base+Vector3(2,0,0)
 player.position = Vector3(15,.1,0)*game.expedition.scale_factor
 game.command.set_order("defend")
 game.check(game.command.anchor(soldier)==base and game.command.rally_point(soldier).distance_to(base)<4,"defend order anchors the squad to home castle instead of leader",failures)
 var before: float = soldier.position.distance_to(base)
 for frame in range(45):
  soldier._physics_process(1.0/60)
  await game.get_tree().physics_frame
 game.check(soldier.position.distance_to(base)<6*game.expedition.scale_factor,"guard physically remains at home while leader moves away",failures)
 game.command.set_order("attack")
 game.check(game.command.anchor(soldier)==player.position,"attack order restores leader-following anchor",failures)
 var dist: float = soldier.position.distance_to(player.position)
 for frame in range(100):
  soldier._physics_process(1.0/60)
  await game.get_tree().physics_frame
 game.check(soldier.position.distance_to(player.position)<dist-2,"guard physically leaves castle and follows leader after attack command",failures)
 game.command.set_order("defend")
 var enemy = game.enemies[0]
 enemy.position = base+Vector3(1,.1,0)
 soldier.position = base+Vector3(0,.1,1)
 game.check(soldier.select_target()==enemy,"castle guard selects an invading enemy while leader is far away",failures)
 game.command.enemy_capture = 0
 game.command.tick(1)
 game.check(game.command.enemy_capture==0,"friendly guard contests and prevents enemy capture of home core",failures)
 for ally in game.allies:
  ally.position = Vector3(20,.1,15)*game.expedition.scale_factor
 game.command.tick(1)
 game.check(game.command.enemy_capture==1,"unprotected home castle develops enemy occupation pressure",failures)
 player.position = base+Vector3.UP*.1
 game.command.tick(1)
 game.check(game.command.enemy_capture==1,"returning leader also stops enemy occupation progress",failures)
 enemy.position = Vector3(22,.1,0)*game.expedition.scale_factor
 game.command.tick(.5)
 game.check(game.command.enemy_capture==0,"home warning clears after invaders leave",failures)
 # No victory merely for eliminating all enemies: holding the core is required.
 player.position = base
 for unit in game.enemies:
  unit.hp = 0
 game.command.tick(1)
 game.check(game.mode=="playing" and profile.wins==0,"army elimination alone no longer wins the siege",failures)
 player.position = core+Vector3.UP*.1
 enemy.hp = 100
 enemy.position = core+Vector3(1,.1,0)
 game.command.tick(2)
 game.check(game.command.contested and game.command.capture==0,"living defenders block enemy-core capture",failures)
 enemy.position = Vector3(22,.1,0)*game.expedition.scale_factor
 game.command.tick(2)
 game.check(game.command.capture==2 and game.mode=="playing","cleared enemy core starts timed occupation without instant victory",failures)
 game.active = false
 game.command.tick(1)
 game.check(game.command.capture==2,"pause freezes castle occupation timer",failures)
 game.active = true
 player.position = base
 game.command.tick(.5)
 game.check(game.command.capture==1,"leaving enemy core causes occupation progress to decay",failures)
 soldier.position = core+Vector3.UP*.1
 game.command.tick(1)
 game.check(game.command.capture==2,"a recruited soldier can occupy the cleared enemy core",failures)
 game.difficulty = 3
 enemy.is_boss = true
 game.command.tick(1)
 game.check(game.command.contested and game.command.capture==2,"super-nightmare leader must be defeated before castle capture",failures)
 enemy.is_boss = false
 game.difficulty = 0
 var coins: int = profile.credits
 game.command.tick(6)
 game.check(game.mode=="win" and game.command.captured and profile.credits==coins+1000000,"capturing enemy castle wins and grants one million coins",failures)
 game.resume_looting()
 game.command.tick(10)
 game.check(profile.credits==coins+1000000,"captured castle cannot duplicate victory reward",failures)
 game.command.captured = false
 game.command.capture = 0
 soldier.position = Vector3(20,.1,15)*game.expedition.scale_factor
 player.position = core
 enemy.position = base+Vector3.UP*.1
 game.active = true
 game.mode = "playing"
 game.command.enemy_capture = 19
 game.command.tick(1)
 game.check(game.mode=="defeat" and not game.active,"enemy holding an undefended home core ends the siege in defeat",failures)
 game.check(profile.credits==coins+1000000,"losing the home castle preserves earned permanent currency",failures)
 for ally in game.allies:
  if is_instance_valid(ally):
   ally.queue_free()
 game.allies.clear()
 game.career = original
 game.command.siege_enabled = false
 game.active = false
