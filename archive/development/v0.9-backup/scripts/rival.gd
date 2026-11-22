extends RefCounted
const RESPAWN_SECONDS = 10.0
var game: Node3D
var unit: Node3D
var respawn_left := -1.0
var lives := 0
var cover_timer := 0.0
var goal := Vector3.ZERO
var decision := "守卫核心"

func reset() -> void:
 unit = null
 respawn_left = -1
 cover_timer = 0
 lives = 0

func start_round() -> void:
 reset()
 if game.difficulty==4:
  spawn()

func spawn() -> void:
 if game.difficulty!=4 or is_instance_valid(unit) and unit.hp>0:
  return
 unit = game.spawn_enemy(game.command.enemy_spawn(0)+Vector3.UP*.1,false,true)
 lives += 1
 respawn_left = -1
 decision = "守卫核心"

func defeated(victim: Node3D) -> void:
 if victim!=unit or respawn_left>=0:
  return
 respawn_left = RESPAWN_SECONDS
 unit = null
 game.message("敌方精英指挥官已被击败 · 10 秒后重新部署",4)

func tick(dt: float) -> void:
 if game.difficulty!=4 or not game.active or game.mode!="playing":
  return
 cover_timer = maxf(0,cover_timer-dt)
 if respawn_left<0:
  return
 respawn_left = maxf(0,respawn_left-dt)
 # Never materialize into an ongoing core occupation or on top of the player.
 if respawn_left==0 and game.command.capture==0 and not game.command.near_core(game.player.position,game.command.enemy_castle.global_position,8):
  spawn()

func tactical_anchor(bot: Node3D) -> Vector3:
 if game.command.capture>0 or game.command.near_core(game.player.position,game.command.enemy_castle.global_position,12):
  decision = "回防核心"
  return game.command.enemy_castle.global_position
 var guarded = 0
 for ally in game.allies:
  if is_instance_valid(ally) and ally.hp>0 and game.command.near_core(ally.position,game.command.castle.global_position,8):
   guarded += 1
 if guarded<3 and game.elapsed>8:
  decision = "突袭薄弱城堡"
  return game.command.castle.global_position
 decision = "守卫核心"
 return game.command.enemy_castle.global_position

func destination(bot: Node3D, target: Node3D, fallback: Vector3) -> Vector3:
 if target==null:
  return fallback
 var sees = game.clear_line(bot.position+Vector3.UP*1.4,target.position+Vector3.UP*1.2,target)
 if not sees:
  return fallback
 if bot.reload_left>0 or bot.armor<bot.max_armor()*.3:
  if cover_timer<=0:
   cover_timer = 1.2
   goal = find_cover(bot,target)
  decision = "寻找掩体" if goal.distance_to(bot.position)>1 else "保持掩护"
  return goal
 var to_target = target.position-bot.position
 to_target.y = 0
 if to_target.length()>4 and to_target.length()<18:
  var side = Vector3(to_target.z,0,-to_target.x).normalized()
  var point = bot.position+side*(2.5 if int(game.elapsed/2)%2==0 else -2.5)
  var path = game.find_path(bot.position,point)
  if path.size()>1:
   decision = "侧移交火"
   return point
 return fallback

func find_cover(bot: Node3D, target: Node3D) -> Vector3:
 var best = bot.position
 var score := INF
 for x in [-6,-3,0,3,6]:
  for z in [-6,-3,0,3,6]:
   var point = bot.position+Vector3(x,0,z)
   var path = game.find_path(bot.position,point)
   if path.size()<2:
    continue
   var ray = PhysicsRayQueryParameters3D.create(target.position+Vector3.UP*1.4,point+Vector3.UP*1.2,1)
   if game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
    continue
   var cost = point.distance_to(bot.position)+point.distance_to(game.command.enemy_castle.global_position)*.05
   if cost<score:
    score = cost
    best = point
 return best
