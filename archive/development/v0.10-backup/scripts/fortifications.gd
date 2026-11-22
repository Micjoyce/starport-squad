extends RefCounted
const F = preload("res://scripts/factory.gd")
var game: Node3D
var roof: Node3D
var climbs := {}
const HEIGHT = 7.15
func build() -> void:
 climbs.clear()
 roof = Node3D.new()
 game.world.add_child(roof)
 roof.position = Vector3(0,0,16)
 var metal = F.mat(Color("425d70"))
 var glow = F.mat(Color("77ffda"),.8)
 F.box(roof,Vector3(0,7.0,0),Vector3(8,.2,7),metal,true)
 for x in [-4,4]:
  F.box(roof,Vector3(x,7.4,0),Vector3(.14,.6,7),metal,true)
  F.box(roof,Vector3(x,7.75,0),Vector3(.15,.05,7),glow)
 for side in [-1,1]:
  F.box(roof,Vector3(side*.45,3.55,5),Vector3(.09,7.1,.09),metal)
 for i in range(18):
  F.box(roof,Vector3(0,.25+i*.4,5),Vector3(.9,.06,.08),glow)
 var sign = F.text3d(roof,"狙击平台 / E 攀爬 / Z 趴下",Vector3(0,8.5,4),28,Color("7affdf"))
 sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
func base() -> Vector3:
 return roof.to_global(Vector3(0,.12,5))
func top() -> Vector3:
 return roof.to_global(Vector3(0,HEIGHT,2.4))
func sniper_point(unit: Node3D) -> Vector3:
 return roof.to_global(Vector3((unit.slot%5-2)*1.35,HEIGHT,((unit.slot/5)%6-2.5)*.9))
func is_rooftop(unit: Node3D) -> bool:
 return unit.position.y>6.5 and Vector2(unit.position.x-roof.global_position.x,unit.position.z-roof.global_position.z).length()<6*game.expedition.scale_factor
func start(unit: Node3D, up: bool) -> void:
 for key in climbs.keys():
  if not is_instance_valid(climbs[key].unit): climbs.erase(key)
 if unit==game.player: unit.set_prone(false)
 climbs[unit.get_instance_id()] = {"unit":unit,"from":unit.position,"up":up,"time":0.0}
 unit.velocity = Vector3.ZERO
func step(unit: Node3D, dt: float) -> bool:
 var id = unit.get_instance_id()
 if not climbs.has(id): return false
 var state = climbs[id]
 state.time = minf(3,state.time+dt)
 var outside = base()
 outside.y = HEIGHT
 var goal: Vector3
 if state.up:
  goal = state.from.lerp(outside,minf(1,state.time/2.1)) if state.time<2.1 else outside.lerp(top(),(state.time-2.1)/.9)
 else:
  goal = state.from.lerp(outside,minf(1,state.time/.9)) if state.time<.9 else outside.lerp(base(),(state.time-.9)/2.1)
 unit.move_and_collide(goal-unit.position)
 if unit==game.player: unit.update_view()
 if state.time>=3:
  climbs.erase(id)
  unit.velocity = Vector3.ZERO
 return true
func step_player(dt: float) -> bool:
 return step(game.player,dt)
func interact_player() -> bool:
 var p = game.player
 if climbs.has(p.get_instance_id()): return true
 if p.position.distance_to(base())<1.8:
  start(p,true)
  return true
 if p.position.distance_to(top())<2:
  start(p,false)
  return true
 return false
func step_unit(unit: Node3D, dt: float) -> bool:
 if step(unit,dt): return true
 if not unit.friendly: return false
 var guard = unit.role==1 and game.command.order=="defend"
 if guard and not is_rooftop(unit) and unit.position.distance_to(base())<1.5:
  start(unit,true)
  return true
 if not guard and is_rooftop(unit):
  start(unit,false)
  return true
 return false
