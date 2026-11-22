extends RefCounted
const Vehicle = preload("res://scripts/vehicle.gd")
var game: Node3D
var fleet: Array = []
var current: CharacterBody3D
var role := 0
var enabled := true
var cooldown := 0.0

func build() -> void:
 current = null
 fleet.clear()
 var sites = [Vector3(-22,.3,26),Vector3(-15,.3,26),Vector3(-8,.3,26),Vector3(8,.3,25),Vector3(15,.3,20),Vector3(22,.3,22),Vector3(11,.3,-2)]
 var used: Array = []
 for i in range(7):
  var point = find_space(sites[i],used)
  used.append(point)
  spawn(point*Vector3(game.expedition.scale_factor,1,game.expedition.scale_factor),i%3,i>=3,i<6)

func find_space(preferred: Vector3, used: Array) -> Vector3:
 var candidates = [preferred]
 for z in [26,21,7,0,-16]:
  for x in [-22,-15,-8,8,15,22]: candidates.append(Vector3(x,.3,z))
 for point in candidates:
  var safe := true
  for blocked in game.blockers:
   if blocked.grow(2.1).has_point(Vector2(point.x,point.z)):
    safe=false
    break
  for old in used:
   if point.distance_to(old)<6: safe=false
  if safe: return point
 return preferred

func spawn(pos: Vector3, tier: int, car: bool, friendly: bool) -> CharacterBody3D:
 var v = CharacterBody3D.new()
 v.set_script(Vehicle)
 v.game = game
 v.tier = tier
 v.armored_car = car
 v.friendly = friendly
 game.world.add_child(v)
 v.scale = Vector3(1/game.expedition.scale_factor,1,1/game.expedition.scale_factor)
 v.global_position = pos
 fleet.append(v)
 return v

func nearby() -> CharacterBody3D:
 if not enabled: return null
 for v in fleet:
  if is_instance_valid(v) and not v.destroyed and v.friendly and game.player.global_position.distance_to(v.global_position)<4:
   return v
 return null

func interact() -> bool:
 if not enabled: return false
 if current!=null:
  exit_vehicle()
  return true
 var v = nearby()
 if v==null: return false
 return enter(v)

func enter(v: CharacterBody3D) -> bool:
 if current!=null or not is_instance_valid(v) or v.destroyed or not v.friendly or v.seats_used()>=8: return false
 current = v
 role = 0
 game.player.set_prone(false)
 game.player.velocity = Vector3.ZERO
 game.player.collision_layer = 0
 game.player.collision_mask = 0
 v.passengers.append(game.player)
 for unit in game.allies:
  if v.seats_used()>=8: break
  if is_instance_valid(unit) and unit.hp>0 and unit.global_position.distance_to(v.global_position)<12:
   v.passengers.append(unit)
   unit.visible = false
   unit.collision_layer = 0
   unit.set_meta("aboard",true)
   game.forts.climbs.erase(unit.get_instance_id())
   unit.global_position = v.global_position
   unit.process_mode = Node.PROCESS_MODE_DISABLED
 v.refresh()
 game.message("已上车 · WASD 驾驶 · X 切换炮手 · E 下车 · AI 乘员协助",5)
 return true

func exit_vehicle(emergency: bool = false) -> bool:
 if current==null: return false
 var v = current
 var destination := Vector3.ZERO
 var found := false
 for offset in [Vector3(3.2,.2,0),Vector3(-3.2,.2,0),Vector3(0,.2,3.6),Vector3(0,.2,-3.6)]:
  var p: Vector3 = v.global_transform*offset
  var q = PhysicsShapeQueryParameters3D.new()
  q.shape = game.player.capsule_shape
  q.transform = Transform3D(Basis.IDENTITY,p+Vector3.UP*.9)
  q.collision_mask = 1
  if game.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty():
   destination = p
   found = true
   break
 if not found and not emergency:
  game.message("车门外有障碍，请移到空旷处下车")
  return false
 if not found: destination = game.extraction_position+Vector3.UP*.2
 current = null
 game.player.global_position = destination
 game.player.velocity = Vector3.ZERO
 game.player.collision_layer = 2
 game.player.collision_mask = 1
 game.player.pants.visible = true
 game.player.update_view()
 for unit in v.passengers:
  if is_instance_valid(unit) and unit!=game.player:
   unit.global_position = destination+Vector3(0,0,1+float(v.passengers.find(unit))*.7)
   unit.visible = true
   unit.collision_layer = 8
   unit.set_meta("aboard",false)
   unit.path_timer = 0
   unit.process_mode = Node.PROCESS_MODE_INHERIT
 v.passengers.clear()
 v.refresh()
 return true

func switch_seat() -> void:
 if current==null: return
 role = 1-role
 current.velocity.x = 0
 current.velocity.z = 0
 game.message("炮手位：鼠标瞄准 / 左键射击 · AI 驾驶员停车待命" if role==1 else "驾驶位：WASD 驾驶 · AI 炮手自动攻击")

func grenade(origin: Vector3, friendly: bool) -> void:
 for v in fleet:
  if not is_instance_valid(v) or v.destroyed or v.friendly==friendly: continue
  var target: Vector3 = v.global_position+Vector3.UP
  if origin.distance_to(target)>6.5: continue
  var q = PhysicsRayQueryParameters3D.create(origin,target,1)
  var hit = game.get_world_3d().direct_space_state.intersect_ray(q)
  if hit.is_empty() or hit.collider==v: v.take_grenade()
