extends RefCounted
const Pet = preload("res://scripts/pet.gd")
const Drone = preload("res://scripts/drone.gd")
const EGG_NAMES = ["基础蛋","白蛋","蓝蛋","紫蛋","金蛋","红蛋"]
const CHANCES = [.20,.20,.30,.50,.46,1.0]
const FRIEND_CAP = 30
const ENEMY_CAP = 40
var game: Node3D
var enabled := true
var pet: CharacterBody3D
var budget := 2
var budget_timer := 0.0
func sync_pet() -> void:
 if not enabled: return
 if is_instance_valid(pet) and pet.kind==game.career.pet_kind: return
 if is_instance_valid(pet): pet.queue_free()
 pet = null
 if game.career.pet_kind<0: return
 pet = CharacterBody3D.new()
 pet.set_script(Pet)
 pet.game = game
 pet.kind = game.career.pet_kind
 game.add_child(pet)
 pet.position = game.player.position+Vector3(1,0,1)
func tick(dt: float) -> void:
 if not enabled: return
 budget_timer -= dt
 if budget_timer<=0:
  budget = 2
  budget_timer = 1
 sync_pet()
 if is_instance_valid(pet): pet.step(dt)
func roll_eggs() -> Array:
 var result = []
 for chance in CHANCES: result.append(1 if game.rng.randf()<chance else 0)
 return result
func summon(parent: Node3D) -> bool:
 if not enabled or not game.active or parent.hp<=0 or budget<=0: return false
 game.allies = game.allies.filter(func(unit): return is_instance_valid(unit) and unit.hp>0)
 game.enemies = game.enemies.filter(func(unit): return is_instance_valid(unit) and unit.hp>0)
 var team = game.allies if parent.friendly else game.enemies
 var count = 0
 for unit in team:
  if is_instance_valid(unit) and unit.hp>0 and not unit.is_elite and not unit.is_boss: count += 1
 if count>=(FRIEND_CAP if parent.friendly else ENEMY_CAP): return false
 var goal = parent.position+parent.global_basis*Vector3(1.2,0,1.2)
 var grid = Vector2i(roundi(goal.x/game.expedition.scale_factor),roundi(goal.z/game.expedition.scale_factor))
 if not game.navigation.is_in_boundsv(grid) or game.navigation.is_point_solid(grid): return false
 budget -= 1
 var child: Node3D
 if parent.friendly:
  child = CharacterBody3D.new()
  child.set_script(Drone)
  child.game = game
  child.friendly = true
  child.slot = game.allies.size()
  child.weapon_tier = parent.weapon_tier
  child.generation = parent.generation+1
  game.add_child(child)
  child.position = goal+Vector3.UP*.1
  game.allies.append(child)
 else:
  child = game.spawn_enemy(goal+Vector3.UP*.1)
  child.generation = parent.generation+1
 return true
