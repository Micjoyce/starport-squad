extends RefCounted

const F = preload("res://scripts/factory.gd")
const FUSE := 3.0
const RADIUS := 4.5
const DAMAGE := 245.0
const RANGE := 16.0

var game: Node3D
var spent := false
var queued := false
var target: Node3D
var device: Node3D
var countdown: Label3D
var left := 0.0
var flight := 0.0
var departure := Vector3.ZERO
var destination := Vector3.ZERO

func request_launch() -> void:
 if spent or queued or not game.active or game.vehicles.current!=null:
  return
 queued = true

func tick(dt: float) -> void:
 if queued:
  queued = false
  launch()
  return
 if not is_instance_valid(device):
  return
 if is_instance_valid(target) and not target.is_queued_for_deletion():
  destination = target.global_position+Vector3.UP*1.05
 if flight>0:
  flight = maxf(0.0,flight-dt)
  var progress := 1.0-flight/.24
  device.global_position = departure.lerp(destination,progress)+Vector3.UP*sin(progress*PI)*.42
  return
 device.global_position = destination
 left = maxf(0.0,left-dt)
 var label := "%.1f" % left
 if countdown.text!=label: countdown.text = label
 if left<=0:
  var origin := device.global_position
  device.queue_free()
  device = null
  target = null
  detonate(origin)

func launch() -> void:
 if spent or not game.active or game.vehicles.current!=null or game.player.roll_left>0:
  return
 var camera: Camera3D = game.player.camera
 var from := camera.global_position
 var to := from-camera.global_basis.z*RANGE
 var rid: RID = game.player.get_rid()
 var space := game.get_world_3d().direct_space_state
 var aim := space.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,13,[rid]))
 if aim.is_empty():
  game.message("瞄准角色或墙面后再投放",2.0)
  return
 # Check the path from the actual character as well as the shoulder camera.
 var hand: Vector3 = game.player.global_position+Vector3.UP*1.25
 var impact: Vector3 = aim.position
 if hand.distance_to(impact)>RANGE:
  game.message("目标太远",2.0)
  return
 var ray := PhysicsRayQueryParameters3D.create(hand,impact+(impact-hand).normalized()*.06,13,[rid])
 var hit := space.intersect_ray(ray)
 if hit.is_empty():
  hit = aim
 var attached: Node3D = hit.collider if (hit.collider.collision_layer & 12)!=0 else null
 arm(hit.position+hit.normal*.08,attached)
 departure = hand
 flight = .24
 device.global_position = hand

func arm(origin: Vector3, attached: Node3D) -> void:
 spent = true
 target = attached
 left = FUSE
 destination = origin
 device = Node3D.new()
 game.add_child(device)
 device.global_position = origin
 var core = F.mat(Color("ff6847"),1.2)
 F.box(device,Vector3.ZERO,Vector3(.24,.15,.21),F.mat(Color("263441")))
 F.sphere(device,Vector3.UP*.10,.075,core)
 countdown = F.text3d(device,"3.0",Vector3.UP*.47,30,Color("ffc498"))
 countdown.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 countdown.no_depth_test = false
 game.sound("switch",.65)

func damage_at(origin: Vector3, point: Vector3) -> float:
 var distance := origin.distance_to(point)
 if distance>=RADIUS:
  return 0.0
 if distance>.10:
  var ray := PhysicsRayQueryParameters3D.create(origin,point,1)
  if not game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
   return 0.0
 return DAMAGE*(1.0-.72*distance/RADIUS)

func detonate(origin: Vector3) -> void:
 var player: CharacterBody3D = game.player
 for unit in game.allies+game.enemies:
  if not is_instance_valid(unit) or unit.hp<=0 or unit.get_meta("aboard",false):
   continue
  var splash := damage_at(origin,unit.global_position+Vector3.UP*.95)
  if splash>0:
   unit.take_hit(splash,true)
 var damage := damage_at(origin,player.global_position+Vector3.UP*.95)
 if damage>0 and game.vehicles.current==null:
  player.damage(damage,true)
 game.spark(origin,Color("ffb47e"),24)
 var flash = F.sphere(game,origin,.67,F.mat(Color("ff8359"),1.5))
 game.effects.append({"node":flash,"life":.21})
 game.sound("shotgun",.82)

func status() -> String:
 if is_instance_valid(device):
  return "脉冲倒计时 %.1f 秒 · 远离装置" % left
 return "脉冲装置已用完" if spent else "Y 定时脉冲 ×1"
