extends RefCounted
const Career = preload("res://scripts/career.gd")
static func run(g: Node3D, failures: Array[String]) -> void:
 var c = Career.new()
 c.path = ""
 g.check(c.pack_capacity()==16,"white backpack has 16 slots",failures)
 c.credits = 10000
 for level in range(1,4):
  g.check(c.upgrade_pack() and c.pack_capacity()==16+16*level,"backpack expands to tier "+str(level),failures)
 var copy = Career.new()
 copy.restore(c.snapshot())
 g.check(copy.backpack_level==3,"backpack tier survives save restore",failures)
 copy.restore({"items":{},"equipped":{}})
 g.check(copy.backpack_level==0 and not copy.tutorial_seen,"old saves receive tutorial and white pack",failures)
 c = Career.new()
 c.path = ""
 for kind in c.items:
  for tier in range(6):
   if c.pack_used()>=16: break
   c.add_item(kind,tier)
 g.check(c.pack_used()==16,"distinct stacks fill backpack",failures)
 var key = "pants+"
 g.check(not c.add_item(key,5),"full backpack rejects new stack",failures)
 g.check(c.add_item("armor",0),"full backpack accepts existing stack",failures)
 var before: Dictionary = c.snapshot()
 g.check(not c.grant_loot([{"kind":key,"tier":5}],500),"full backpack rejects complete chest transaction",failures)
 g.check(c.snapshot()==before,"rejected chest does not consume loot or award money",failures)
 c.credits=50000
 for i in range(10):
  g.check(c.upgrade_armor_route(),"new armor route stage "+str(i),failures)
 g.check(c.ARMOR_ROUTE_HP[c.armor_route_level]==2200,"pale yellow green armor is final route tier",failures)
 g.check(c.complete_tutorial() and c.tutorial_seen,"tutorial completion persists",failures)
 copy.restore(c.snapshot())
 g.check(copy.armor_route_level==9 and copy.armor_route_equipped and copy.tutorial_seen,"new armor and tutorial survive profile restore",failures)
 var Vehicle = preload("res://scripts/vehicle.gd")
 for tier in range(3):
  for car in [false,true]:
   var v = g.vehicles.spawn(Vector3(21,0,27),tier,car,true)
   v.process_mode = Node.PROCESS_MODE_DISABLED
   v.collision_layer = 0
   var rounds: int = Vehicle.RAINBOW_HITS[tier]
   v.receive_rounds(rounds-1,true)
   g.check(not v.destroyed,"vehicle survives rainbow threshold minus one "+str(tier)+str(car),failures)
   v.receive_rounds(1,true)
   g.check(v.destroyed,"vehicle destroyed at exact rainbow threshold "+str(tier)+str(car),failures)
   v.destroyed=false
   v.durability=1
   for n in range(Vehicle.GRENADE_HITS[tier]-1): v.take_grenade()
   g.check(not v.destroyed,"vehicle survives grenade threshold minus one "+str(tier)+str(car),failures)
   v.take_grenade()
   g.check(v.destroyed,"vehicle destroyed at exact grenade threshold "+str(tier)+str(car),failures)
 g.active=true
 g.mode="playing"
 g.vehicles.enabled=true
 var v = g.vehicles.fleet[0]
 v.destroyed=false
 v.durability=1
 g.check(g.vehicles.enter(v),"player enters vehicle with AI driver and gunner",failures)
 g.check(v.seats_used()>=3 and v.seats_used()<=8,"vehicle crew includes player and respects eight seats",failures)
 g.vehicles.switch_seat()
 g.check(g.vehicles.role==1,"switch to gunner seat",failures)
 g.check(g.vehicles.exit_vehicle(true) and g.player.collision_layer==2,"exit restores player collision",failures)
 var profile: Dictionary = g.career.snapshot()
 g.career.tutorial_seen=false
 g.smoke_mode=false
 g.test_mode=false
 g.start_game()
 g.check(not g.active and g.hud.page=="tutorial","new player sees tutorial before battle",failures)
 g.fieldkit.finish_tutorial()
 g.check(g.active and g.career.tutorial_seen,"tutorial completion enters battle",failures)
 g.test_mode=true
 g.career.restore(profile)
 g.player.slide_direction=Vector3.RIGHT
 g.player.slide_left=.65
 g.player.slide_distance=0
 g.player.position=Vector3(-7,.2,30*g.expedition.scale_factor)
 g.player.set_prone(true)
 for n in range(40): g.player.step_slide(1.0/60)
 g.check(g.player.slide_distance<=10.001 and g.player.slide_distance>9.8,"slide travels ten meters in clear lane",failures)
 g.check(g.player.slide_left==0 and not g.player.prone,"slide restores upright pose",failures)
 g.player.position=Vector3(26*g.expedition.scale_factor,.2,30*g.expedition.scale_factor)
 g.player.slide_direction=Vector3.RIGHT
 g.player.slide_left=.65
 g.player.slide_distance=0
 for n in range(40): g.player.step_slide(1.0/60)
 g.check(g.player.slide_distance<3,"slide stops at solid wall",failures)
 var live = g.vehicles.spawn(Vector3(-20,1,40),2,false,true)
 for n in range(65): await g.get_tree().physics_frame
 g.check(live.global_position.y>-.5 and live.is_on_floor(),"live vehicle rests on ground without sinking",failures)
 g.check(g.vehicles.enter(live),"live vehicle supports boarding",failures)
 var start: Vector3 = live.global_position
 Input.action_press("forward")
 for n in range(60): await g.get_tree().physics_frame
 Input.action_release("forward")
 g.check(live.global_position.distance_to(start)>2,"driver input moves tank through real physics",failures)
 g.check(g.player.global_position.distance_to(live.global_position)<3,"player remains seated in moving tank",failures)
 g.vehicles.switch_seat()
 var shots: int = live.shot_count
 Input.action_press("fire")
 for n in range(25): await g.get_tree().physics_frame
 Input.action_release("fire")
 g.check(live.shot_count>shots,"gunner input fires mounted weapon",failures)
 live.durability=1
 g.explode_grenade(live.global_position+Vector3(0,1,2.6),200,false)
 g.check(is_equal_approx(live.durability,1.0-1.0/199),"one hostile grenade causes one vehicle grenade hit with occupied hull",failures)
 var anchor: Vector3 = live.global_position
 g.active=false
 Input.action_press("forward")
 for n in range(10): await g.get_tree().physics_frame
 Input.action_release("forward")
 g.check(live.global_position.is_equal_approx(anchor),"pause freezes vehicle motion",failures)
 g.active=true
 g.vehicles.exit_vehicle(true)
 var former_allies: Array = g.allies.duplicate()
 g.allies.clear()
 var Drone = preload("res://scripts/drone.gd")
 for i in range(7):
  var unit = CharacterBody3D.new()
  unit.set_script(Drone)
  unit.game=g
  unit.friendly=true
  g.add_child(unit)
  unit.position=live.global_position+Vector3(3,.2,float(i)*.4)
  unit.process_mode=Node.PROCESS_MODE_DISABLED
  g.allies.append(unit)
 g.check(g.vehicles.enter(live) and live.seats_used()==8,"boarding fills exactly eight seats and leaves excess allies outside",failures)
 var hidden := 0
 for unit in g.allies:
  if not unit.visible and unit.collision_layer==0: hidden+=1
 g.check(hidden==5,"five passenger allies board without leaving invisible colliders",failures)
 g.vehicles.exit_vehicle(true)
 var released := true
 for unit in g.allies:
  released = released and unit.visible and unit.collision_layer==8 and not unit.get_meta("aboard",false)
  unit.queue_free()
 g.check(released,"all passengers disembark with restored visuals and collision",failures)
 g.allies=former_allies
 var saved_profile: Dictionary = g.career.snapshot()
 g.career.armor_route_level=9
 g.career.armor_route_equipped=true
 g.check(g.player.max_shield()==2200,"new armor route affects actual player protection",failures)
 g.wardrobe.last_key=""
 g.wardrobe.sync()
 var mirror = g.spawn_enemy(Vector3(20,.2,25))
 g.check(mirror.max_armor()==2200,"ordinary enemies mirror new player armor route",failures)
 g.career.restore(saved_profile)
 g.wardrobe.last_key=""
 g.wardrobe.sync()
 g.active=false
 g.hud.show_page("menu")
