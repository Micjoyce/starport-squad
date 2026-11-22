from pathlib import Path
root=Path('outputs/StarportSquad/scripts')
p=root/'career.gd'; s=p.read_text();s=s.replace('var speed_stage := 1','''const PACK_NAMES = ["白色背包","蓝色背包","红色背包","绿色背包"]
const PACK_SLOTS = [16,32,48,64]
const PACK_COSTS = [0,300,1200,4000]
const ARMOR_ROUTE = ["白","蓝","红","紫","金","赤红","深红","绿","浅绿","淡黄绿"]
const ARMOR_ROUTE_COLORS = [Color("e7e9df"),Color("4996d5"),Color("eb6363"),Color("b87ce0"),Color("dbc467"),Color("c53940"),Color("6d2132"),Color("357e44"),Color("88bb70"),Color("d4df8c")]
const ARMOR_ROUTE_HP = [100,150,220,300,420,600,850,1200,1600,2200]
var backpack_level := 0
var tutorial_seen := false
var armor_route_level := -1
var armor_route_equipped := false
var speed_stage := 1''');s=s.replace('"version":6,','"version":7,"backpack_level":backpack_level,"tutorial_seen":tutorial_seen,"armor_route_level":armor_route_level,"armor_route_equipped":armor_route_equipped,');s=s.replace('func restore(data: Dictionary) -> void:\n','''func restore(data: Dictionary) -> void:
 backpack_level = clampi(int(data.get("backpack_level",0)),0,3)
 tutorial_seen = bool(data.get("tutorial_seen",false))
 armor_route_level = clampi(int(data.get("armor_route_level",-1)),-1,9)
 armor_route_equipped = bool(data.get("armor_route_equipped",false)) and armor_route_level>=0
''');s=s.replace(' items[kind][tier] += 1\n return commit(before)',' if items[kind][tier]==0 and pack_used()>=pack_capacity(): return false\n items[kind][tier] += 1\n return commit(before)',1);s=s.replace(' equipped[base] = tier',' if base=="armor": armor_route_equipped = false\n equipped[base] = tier',1);s=s.replace(' credits -= price(kind,tier)\n items[kind][tier] += 1',' if items[kind][tier]==0 and pack_used()>=pack_capacity(): return false\n credits -= price(kind,tier)\n items[kind][tier] += 1');s=s.replace(' var before = snapshot()\n for item in payload:', ''' var before = snapshot()
 var pending := {}
 for item in payload:
  if items.has(item.kind) and item.tier>=0 and item.tier<6 and items[item.kind][item.tier]==0:
   pending[str(item.kind)+str(item.tier)] = true
 if pack_used()+pending.size()>pack_capacity(): return false
 for item in payload:''');s+='''
func pack_used() -> int:
 return pack_entries().size()

func pack_capacity() -> int:
 return PACK_SLOTS[backpack_level]

func pack_entries() -> Array:
 var result := []
 for kind in items:
  for tier in range(6):
   if items[kind][tier]>0:
    result.append({"kind":kind,"tier":tier,"count":items[kind][tier]})
 return result

func upgrade_pack() -> bool:
 if backpack_level>=3 or credits<PACK_COSTS[backpack_level+1]: return false
 var before = snapshot()
 credits -= PACK_COSTS[backpack_level+1]
 backpack_level += 1
 return commit(before)

func upgrade_armor_route() -> bool:
 if armor_route_level>=9: return false
 var cost = (armor_route_level+2)*200
 if credits<cost: return false
 var before = snapshot()
 credits -= cost
 armor_route_level += 1
 armor_route_equipped = true
 return commit(before)

func complete_tutorial() -> bool:
 var before = snapshot()
 tutorial_seen = true
 return commit(before)
''';p.write_text(s)
p=root/'game.gd';s=p.read_text();s=s.replace('var forts: RefCounted','const Vehicles = preload("res://scripts/vehicles.gd")\nconst FieldKit = preload("res://scripts/field_kit.gd")\nconst FieldChecks = preload("res://scripts/field_checks.gd")\nvar vehicles: RefCounted\nvar fieldkit: RefCounted\nvar forts: RefCounted');s=s.replace(' setup_inputs()',' vehicles = Vehicles.new()\n vehicles.game = self\n fieldkit = FieldKit.new()\n fieldkit.game = self\n setup_inputs()',1);s=s.replace('smoke_mode = "--regiment-preview"','smoke_mode = "--field-preview" in OS.get_cmdline_user_args() or "--regiment-preview"',1);s=s.replace(' if test_mode:\n  call_deferred("run_tests")',' vehicles.build()\n if test_mode:\n  call_deferred("run_tests")\n elif "--field-preview" in OS.get_cmdline_user_args():\n  start_game()\n  call_deferred("run_field_preview")');s=s.replace('var keys = {','var keys = {"slide":KEY_CTRL,"vehicle_seat":KEY_X,',1);s=s.replace('func start_game() -> void:\n','''func start_game() -> void:
 if not test_mode and not smoke_mode and not career.tutorial_seen:
  fieldkit.open_tutorial(true)
  return
''');s=s.replace('func _unhandled_input(event: InputEvent) -> void:\n','''func _unhandled_input(event: InputEvent) -> void:
 if hud.page=="tutorial":
  if event.is_action_pressed("pause"): fieldkit.finish_tutorial()
  return
 if active and event.is_action_pressed("vehicle_seat"):
  vehicles.switch_seat()
  return
''');s=s.replace('func interact() -> void:\n','func interact() -> void:\n if vehicles.interact(): return\n',1);s=s.replace('func explode_grenade(origin: Vector3, amount: float, friendly: bool = false) -> void:\n','func explode_grenade(origin: Vector3, amount: float, friendly: bool = false) -> void:\n if vehicles.enabled: vehicles.grenade(origin,friendly)\n');s=s.replace('func run_tests() -> void:\n','''func run_tests() -> void:
 vehicles.enabled = false
 for v in vehicles.fleet:
  v.collision_layer = 0
  v.process_mode = Node.PROCESS_MODE_DISABLED
''');s=s.replace(' await RegimentChecks.run(self,failures)',' await RegimentChecks.run(self,failures)\n await FieldChecks.run(self,failures)');s+='''
func run_field_preview() -> void:
 companions.enabled = false
 regiments.enabled = false
 command.siege_enabled = false
 for e in enemies: e.process_mode = Node.PROCESS_MODE_DISABLED
 career.credits = 50000
 for i in range(3): career.upgrade_pack()
 fieldkit.open_tutorial(false)
 await get_tree().create_timer(.5).timeout
 capture_frame("新手教程.png")
 fieldkit.finish_tutorial()
 open_backpack()
 hud.inventory_tab = 6
 hud.refresh_inventory()
 await get_tree().create_timer(.5).timeout
 capture_frame("格子背包.png")
 close_backpack()
 player.position = Vector3(-11,.2,29)
 player.rotation.y = 0
 player.camera.position = Vector3(0,5,7)
 player.camera.look_at(Vector3(-16,1,15))
 await get_tree().create_timer(.5).timeout
 capture_frame("装甲车库.png")
 var v = vehicles.fleet[2]
 vehicles.enter(v)
 await get_tree().create_timer(.5).timeout
 capture_frame("坦克驾驶.png")
 stop_audio()
 get_tree().quit()
''';p.write_text(s)
p=root/'player.gd';s=p.read_text();s=s.replace('var prone := false','var slide_left := 0.0\nvar slide_distance := 0.0\nvar slide_direction := Vector3.ZERO\nvar prone := false');s=s.replace(' if event.is_action_pressed("prone"):', ' if game.vehicles.current!=null:\n  return\n if event.is_action_pressed("slide"):\n  start_slide()\n if event.is_action_pressed("prone"):',1);s=s.replace(' if game.forts.step_player(dt): return',''' if game.vehicles.current!=null:
  if Input.is_action_just_pressed("interact"): game.interact()
  return
 if game.forts.step_player(dt): return
 if step_slide(dt): return''',1);s=s.replace('    if weapon_models[weapon] in [6,9] and hit.collider.has_method("take_laser"):', '''    if hit.collider.has_method("receive_rounds"):
     hit.collider.receive_rounds(round_count*game.arsenal.speed_multiplier(),weapon_models[weapon] in [6,9] or weapon_tiers[weapon]==5)
    elif weapon_models[weapon] in [6,9] and hit.collider.has_method("take_laser"):''');s=s.replace('func damage(amount: float) -> void:\n','''func damage(amount: float) -> void:
 if game.vehicles.current!=null:
  game.vehicles.current.take_hit(amount)
  return
''');s=s.replace(' return Gear.SHIELD[armor_tier]*',' if game.career.armor_route_equipped: return float(game.career.ARMOR_ROUTE_HP[game.career.armor_route_level])\n return Gear.SHIELD[armor_tier]*',1);s=s.replace(' for part in body_model.get_meta("armor_parts"):', ''' if game.career.armor_route_equipped and not armor_broken:
  armor_material.albedo_color = game.career.ARMOR_ROUTE_COLORS[game.career.armor_route_level]
  material = armor_material
 for part in body_model.get_meta("armor_parts"):''',1);s+='''
func start_slide() -> bool:
 if slide_left>0 or not is_on_floor() or game.vehicles.current!=null or game.forts.climbing: return false
 slide_direction = -global_basis.z
 slide_left = .65
 slide_distance = 0
 set_prone(true)
 game.message("滑铲 · 最远 10 米 · 遇到障碍停止",1.5)
 return true

func step_slide(dt: float) -> bool:
 if slide_left<=0: return false
 var travel = minf(10-slide_distance,dt*10/.65)
 var before = global_position
 var hit = move_and_collide(slide_direction*travel)
 slide_distance += global_position.distance_to(before)
 slide_left = maxf(0,slide_left-dt)
 update_view()
 if hit!=null or slide_distance>=9.999 or slide_left<=.00001:
  slide_left = 0
  velocity = Vector3.ZERO
  set_prone(false)
 return true
''';s=s.replace('or game.forts.climbing','or game.forts.climb_left>0');p.write_text(s)
p=root/'expedition.gd';s=p.read_text();s=s.replace(' transitioning = true',' if game.vehicles.current!=null:\n  game.vehicles.exit_vehicle(true)\n transitioning = true');s=s.replace(' game.build_world()',' game.build_world()\n game.vehicles.build()');p.write_text(s)
