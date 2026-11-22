extends RefCounted
const Gear = preload("res://scripts/gear.gd")
const Drone = preload("res://scripts/drone.gd")
const NAMES = ["混编步兵","我方狙击兵","激光冲锋兵","沙漠之鹰手枪兵"]
var game: Node3D
var enabled := true
var visitor_timer := 3.0
var initial_visitors := 3
var pending_side := -1
var copies := [[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0]]
var copy_wait := [0.0,0.0]
var cleanup_left := 0.0
func configure(unit: Node3D, selected: int) -> void:
 unit.role = selected
 if not unit.friendly and unit.role==1: unit.role = 0
 if unit.role==0 and not unit.is_elite and not unit.is_boss: unit.weapon_kind = 0
 if unit.role>0: unit.weapon_kind = [0,8,9,10][unit.role]
 unit.ammo = Gear.CAPACITY[unit.weapon_kind]
 unit.reload_left = 0
func configure_recruit(unit: Node3D, index: int) -> void:
 configure(unit,index%4 if game.career.squad_role==0 else game.career.squad_role)
func reform() -> void:
 for i in range(game.allies.size()):
  var unit = game.allies[i]
  if is_instance_valid(unit) and unit.hp>0:
   configure_recruit(unit,i)
   unit.rebuild_model()
   unit.path_timer = 0
func team_count(friendly: bool) -> int:
 var count = 0
 for unit in (game.allies if friendly else game.enemies):
  if is_instance_valid(unit) and unit.hp>0 and not unit.is_elite and not unit.is_boss: count += 1
 return count
func join_friendly(roll: float) -> bool:
 return roll<.5
func spawn(friendly: bool, role: int, stick: bool = false) -> Node3D:
 if team_count(friendly)>=(30 if friendly else 40): return null
 if not friendly and (game.command.capture>0 or game.command.near_core(game.player.position,game.command.enemy_castle.global_position,8)): return null
 var unit: Node3D
 if friendly:
  unit = CharacterBody3D.new()
  unit.set_script(Drone)
  unit.game = game
  unit.friendly = true
  unit.slot = game.allies.size()
  unit.is_stickman = stick
  configure(unit,role)
  game.add_child(unit)
  unit.position = game.command.castle.global_position+Vector3(game.rng.randf_range(-1,1),.15,0)
  game.allies.append(unit)
 else:
  unit = game.spawn_enemy(game.command.enemy_spawn(0)+Vector3.UP*.15)
  configure(unit,role)
  unit.is_stickman = stick
  unit.rebuild_model()
 return unit
func died(unit: Node3D) -> void:
 if not enabled or not game.companions.enabled or unit.is_elite or unit.is_boss: return
 var side = 0 if unit.friendly else 1
 var kind = unit.role+(4 if unit.is_stickman else 0)
 if copies[side].all(func(count): return count==0): copy_wait[side] = 3
 copies[side][kind] = mini(2000000000,copies[side][kind]+2)
func tick(dt: float) -> void:
 if not enabled or not game.active or game.mode!="playing": return
 cleanup_left -= dt
 if cleanup_left<=0:
  cleanup_left = 1
  game.allies = game.allies.filter(func(unit): return is_instance_valid(unit) and unit.hp>0)
  game.enemies = game.enemies.filter(func(unit): return is_instance_valid(unit) and unit.hp>0)
 for side in range(2):
  copy_wait[side] = maxf(0,copy_wait[side]-dt)
  if copy_wait[side]>0: continue
  for kind in range(8):
   while copies[side][kind]>0 and game.companions.budget>0:
    var unit = spawn(side==0,kind%4,kind>=4)
    if unit!=null:
     copies[side][kind] -= 1
     game.companions.budget -= 1
    else:
     break
 visitor_timer -= dt
 if visitor_timer>0 or game.companions.budget<=0: return
 if pending_side<0: pending_side = 0 if join_friendly(game.rng.randf()) else 1
 var visitor = spawn(pending_side==0,3,true)
 if visitor!=null:
  game.companions.budget -= 1
  pending_side = -1
  initial_visitors = maxi(0,initial_visitors-1)
  visitor_timer = 2 if initial_visitors>0 else 15
