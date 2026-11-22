extends RefCounted

const F = preload("res://scripts/factory.gd")
const SIZE := Vector2(56,64)
const INNER_LIFT := Vector3(12,0,23)
const OUTER_LIFT := Vector3(56,0,0)
const MAX_PATROL := 3

var game: Node3D
var enabled := false
var outside := false
var root: Node3D
var chunks := {}
var visited := {}
var patrol: Array[Node3D] = []
var sector := Vector2i.ZERO
var steel: Material
var charcoal: Material
var glow: Material
var deck: Material

func enable() -> void:
 if enabled:
  return
 enabled = true
 root = Node3D.new()
 game.add_child(root)
 steel = F.mat(Color("465c6b"))
 charcoal = F.mat(Color("263642"))
 glow = F.mat(Color("efa76b"),.68)
 deck = ShaderMaterial.new()
 deck.shader = preload("res://scripts/deck.gdshader")
 lift(root,INNER_LIFT,"外环升降台")
 # One continuous collision deck per strip. Visual and cover chunks load locally.
 for area in [
  [Vector3(-168,-.45,-32),Vector3(280,.9,640)],
  [Vector3(140,-.45,-32),Vector3(224,.9,640)],
  [Vector3(0,-.45,-192),Vector3(56,.9,320)],
  [Vector3(0,-.45,160),Vector3(56,.9,256)]
 ]:
  var floor_mesh := F.box(root,area[0],area[1],deck,true)
  floor_mesh.hide()

func lift(parent: Node3D, point: Vector3, caption: String) -> void:
 F.cylinder(parent,point+Vector3.UP*.035,2.25,.058,charcoal,16)
 for side in [-1,1]:
  F.box(parent,point+Vector3(side*1.6,.07,0),Vector3(.09,.05,3.0),glow)
 var label := F.text3d(parent,caption,point+Vector3.UP*1.6,29,Color("ffc48e"))
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func near_lift() -> bool:
 return enabled and game.player.position.distance_to(OUTER_LIFT if outside else INNER_LIFT)<3.0

func interact() -> bool:
 if not near_lift() or game.vehicles.current!=null:
  return false
 if is_instance_valid(game.pulse_charge.device):
  game.message("等定时脉冲结束后再使用升降台",2.0)
  return true
 outside = not outside
 game.player.position = (OUTER_LIFT if outside else INNER_LIFT)+Vector3.UP*.17
 game.player.velocity = Vector3.ZERO
 if outside:
  update_chunks()
 else:
  leave()
 return true

func leave() -> void:
 outside = false
 retire_patrol()
 for chunk in chunks.values(): chunk.queue_free()
 chunks.clear()

func tick() -> void:
 if not outside:
  return
 var point: Vector3 = game.player.position
 if cell(point)==Vector2i.ZERO:
  game.player.position = OUTER_LIFT+Vector3.UP*.2
  game.player.velocity = Vector3.ZERO
  return
 if point.x < -305 or point.x > 249 or point.z < -349 or point.z > 285:
  game.player.position = OUTER_LIFT+Vector3.UP*.2
  game.player.velocity = Vector3.ZERO
 var next := cell(game.player.position)
 if next!=sector:
  update_chunks()

func cell(point: Vector3) -> Vector2i:
 return Vector2i(roundi(point.x/SIZE.x),roundi(point.z/SIZE.y))

func update_chunks() -> void:
 sector = cell(game.player.position)
 var wanted := {}
 for z in range(sector.y-1,sector.y+2):
  for x in range(sector.x-1,sector.x+2):
   var id := Vector2i(x,z)
   if x< -5 or x>4 or z< -5 or z>4 or id==Vector2i.ZERO:
    continue
   wanted[id] = true
   if not chunks.has(id): chunks[id] = build_chunk(id)
 for id in chunks.keys():
  if not wanted.has(id):
   chunks[id].queue_free()
   chunks.erase(id)
 retire_patrol()
 if not visited.has(sector) and sector!=Vector2i.ZERO:
  visited[sector] = true
  var center := Vector3(sector.x*SIZE.x,0,sector.y*SIZE.y)
  var count := 2+absi(sector.x+sector.y)%2
  for i in range(mini(count,MAX_PATROL)):
   patrol.append(game.spawn_enemy(center+Vector3(-10+i*8,.12,-15)))

func retire_patrol() -> void:
 for unit in patrol:
  if is_instance_valid(unit):
   game.enemies.erase(unit)
   unit.queue_free()
 patrol.clear()

func build_chunk(id: Vector2i) -> Node3D:
 var chunk := Node3D.new()
 root.add_child(chunk)
 chunk.position = Vector3(id.x*SIZE.x,0,id.y*SIZE.y)
 F.box(chunk,Vector3(0,-.045,0),Vector3(SIZE.x,.085,SIZE.y),deck)
 var lane := 10.0 if absi(id.x+id.y)%2==0 else -10.0
 for side in [-1,1]:
  F.box(chunk,Vector3(side*6,.018,0),Vector3(.08,.02,62),glow)
  F.box(chunk,Vector3(side*21,1.1,lane),Vector3(5.6,2.2,7),steel,true)
  F.box(chunk,Vector3(side*21,2.35,lane),Vector3(6.0,.3,7.4),charcoal)
  F.box(chunk,Vector3(side*21,1.55,lane+3.51),Vector3(4,.13,.025),glow)
 for z in [-25,24]:
  F.box(chunk,Vector3(-20,3,z),Vector3(.53,6,.53),charcoal)
  F.box(chunk,Vector3(20,3,z),Vector3(.53,6,.53),charcoal)
  F.box(chunk,Vector3(0,6,z),Vector3(41,.44,.52),steel)
  F.box(chunk,Vector3(0,5.76,z),Vector3(15,.035,.23),glow)
 if id==Vector2i(1,0):
  lift(chunk,Vector3.ZERO,"返回星港")
 return chunk
