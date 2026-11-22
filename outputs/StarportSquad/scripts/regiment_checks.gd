extends RefCounted
const Career = preload("res://scripts/career.gd")
const Gear = preload("res://scripts/gear.gd")
static func run(game: Node3D, failures: Array[String]) -> void:
 var original = game.career
 var profile = Career.new()
 profile.path = game.report_path("regiment-save-test.json")
 profile.credits = 100000
 profile.rate_level = 3
 game.career = profile
 game.regiments.enabled = true
 game.companions.enabled = false
 game.command.siege_enabled = false
 game.regiments.visitor_timer = 99999
 game.mode = "menu"
 game.active = false
 game.select_difficulty(0)
 for unit in game.enemies:
  unit.set_physics_process(false)
  unit.position = Vector3(-22,.1,-28)*game.expedition.scale_factor
 game.check(profile.select_model("ak",8) and profile.select_model("sg",10),"new heavy sniper and Desert Eagle are unlocked and selectable",failures)
 game.apply_career()
 var p = game.player
 p.set_physics_process(false)
 p.position = Vector3(10,.15,12)
 p.rotation = Vector3.ZERO
 p.camera.rotation = Vector3.ZERO
 p.ammo[0] = 0
 p.reload_left = 0
 game.active = true
 game.mode = "playing"
 var before_shots: int = p.rounds_emitted
 var camera_rotation: Vector3 = p.camera.rotation
 for i in range(5):
  p.cooldown = 0
  p.shoot()
 game.check(p.rounds_emitted==before_shots+5 and p.ammo[0]==p.capacity[0] and p.reload_left==0,"player can fire repeatedly from zero ammo without reload or depletion",failures)
 game.check(p.camera.rotation==camera_rotation and p.recoil==0,"repeated firing adds no camera or weapon recoil",failures)
 var stage_before: int = game.expedition.sector
 game.expedition.sector = 1
 game.check(game.arsenal.speed_multiplier()==1,"first stage starts at fully modified base multiplier one",failures)
 profile.workshop("speed_stage")
 game.check(game.arsenal.speed_multiplier()==3,"second speed upgrade is exactly three times",failures)
 for i in range(12): profile.workshop("speed_stage")
 game.check(profile.speed_stage==8 and game.arsenal.speed_multiplier()==1000 and not profile.workshop("speed_stage"),"speed progression reaches and cannot exceed one thousand times",failures)
 profile.speed_stage = 1
 game.check(profile.workshop("speed_max") and profile.speed_stage==8,"one-click maximum upgrade reaches the capped top stage",failures)
 profile.speed_stage = 1
 game.expedition.sector = 2
 game.check(game.arsenal.speed_multiplier()==3,"the second region automatically applies the next three-times stage",failures)
 game.expedition.sector = stage_before
 profile.speed_stage = 8
 profile.squad_role = 1
 profile.save_profile()
 var restored = Career.new()
 restored.path = profile.path
 game.check(restored.load_profile() and restored.speed_stage==8 and restored.squad_role==1,"speed progression and troop selection survive actual save reload",failures)
 # Physically climb with the same collision capsule used in normal play.
 p.position = game.forts.base()
 p.velocity = Vector3.ZERO
 game.check(game.forts.interact_player(),"player can start climbing at the castle ladder",failures)
 for frame in range(190):
  game.forts.step_player(1.0/60)
  await game.get_tree().physics_frame
 game.check(p.position.y>7 and p.position.distance_to(game.forts.top())<.4,"real player capsule climbs and enters the castle sniper platform",failures)
 var floor_ray = PhysicsRayQueryParameters3D.create(p.position+Vector3.UP*.2,p.position-Vector3.UP*.4,1)
 game.check(not game.get_world_3d().direct_space_state.intersect_ray(floor_ray).is_empty(),"sniper platform has an actual supporting collision surface",failures)
 p.set_prone(true)
 game.check(p.prone and is_equal_approx(p.capsule_shape.height,.8) and p.camera.position.y<1,"player can lie prone with a shorter collider and lower camera",failures)
 profile.select_model("ak",9)
 game.apply_career()
 game.check(p.prone and is_equal_approx(p.body_model.rotation.x,-PI/2) and is_equal_approx(p.pants.rotation.x,-PI/2),"changing weapons preserves a complete prone body pose",failures)
 profile.select_model("ak",8)
 game.apply_career()
 p.set_prone(false)
 Input.action_press("aim")
 for frame in range(30): p._physics_process(1.0/60)
 Input.action_release("aim")
 game.check(p.camera.fov<20 and not p.gun.visible,"heavy sniper zoom remains clear of the first-person weapon mesh",failures)
 game.check(game.forts.interact_player(),"player can use the upper ladder to descend",failures)
 for frame in range(190):
  game.forts.step_player(1.0/60)
  await game.get_tree().physics_frame
 game.check(p.position.y<.5 and p.position.distance_to(game.forts.base())<.4,"player safely descends from castle roof to ground",failures)
 for ally in game.allies:
  if is_instance_valid(ally): ally.queue_free()
 game.allies.clear()
 game.command.order = "defend"
 game.check(game.command.recruit(),"a dedicated sniper squad can be recruited",failures)
 var all_snipers = true
 for ally in game.allies:
  ally.set_physics_process(false)
  all_snipers = all_snipers and ally.role==1 and ally.weapon_kind==8
 game.check(all_snipers,"only friendly recruited sniper squads carry the new heavy sniper",failures)
 var sniper = game.allies[0]
 var stations = {}
 var supported = true
 for i in range(30):
  sniper.slot = i
  var point = game.forts.sniper_point(sniper)
  stations[Vector2(point.x,point.z)] = true
  var ray = PhysicsRayQueryParameters3D.create(point+Vector3.UP*.2,point-Vector3.UP*.4,1)
  supported = supported and not game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
 sniper.slot = 0
 game.check(stations.size()==30 and supported,"a full thirty-sniper regiment has distinct physically supported rooftop stations",failures)
 sniper.position = game.forts.base()
 sniper._physics_process(.016)
 for frame in range(190):
  sniper._physics_process(1.0/60)
  await game.get_tree().physics_frame
 game.check(game.forts.is_rooftop(sniper) and sniper.position.y>7,"friendly sniper autonomously climbs the same ladder to defend from above",failures)
 var enemy = game.enemies[0]
 enemy.position = Vector3(-16,.15,4)*game.expedition.scale_factor
 enemy.hp = 1000
 enemy.max_hp = 1000
 enemy.armor = 0
 sniper.position = game.forts.sniper_point(sniper)
 await game.get_tree().physics_frame
 var health: float = enemy.hp
 sniper.look_at(Vector3(enemy.position.x,sniper.position.y,enemy.position.z))
 sniper.planned_aim = enemy.position+Vector3.UP*1.2
 sniper.fire_weapon()
 game.check(enemy.hp<health,"elevated sniper's real shot can damage an opposing soldier on the ground",failures)
 game.command.set_order("attack")
 for frame in range(190):
  sniper._physics_process(1.0/60)
  await game.get_tree().physics_frame
 game.check(sniper.position.y<.5,"attack command brings rooftop sniper down to follow the leader",failures)
 profile.squad_role = 2
 game.regiments.reform()
 game.check(game.allies[0].role==2 and game.allies[0].weapon_kind==9,"laser assault regiment receives super-shooter laser weapons",failures)
 profile.squad_role = 3
 game.regiments.reform()
 game.check(game.allies[0].role==3 and game.allies[0].weapon_kind==10,"pistol regiment is uniformly equipped with Desert Eagles",failures)
 game.regiments.configure(enemy,1)
 game.check(enemy.role!=1 and enemy.weapon_kind!=8,"opposing units cannot become the exclusive friendly sniper class",failures)
 var friendly_visitors := 0
 for i in range(10000):
  if game.regiments.join_friendly(game.rng.randf()): friendly_visitors += 1
 game.check(absf(friendly_visitors/10000.0-.5)<.03,"random stickman faction choice follows fifty-fifty probability",failures)
 game.check(game.regiments.join_friendly(.499) and not game.regiments.join_friendly(.5),"stickman selection uses the exact fifty-percent boundary",failures)
 var visitor = game.regiments.spawn(true,3,true)
 visitor.set_physics_process(false)
 game.check(visitor.is_stickman and visitor.friendly and visitor.weapon_kind==10,"friendly stickman visitor appears with a Desert Eagle",failures)
 var hostile_visitor = game.regiments.spawn(false,3,true)
 hostile_visitor.set_physics_process(false)
 game.check(hostile_visitor.is_stickman and not hostile_visitor.friendly and hostile_visitor.weapon_kind==10 and hostile_visitor.badge.text.contains("敌方"),"hostile stickman visitor can join the opposing army",failures)
 game.regiments.copies = [[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0]]
 game.regiments.copy_wait = [0.0,0.0]
 game.companions.enabled = true
 hostile_visitor.armor = 0
 hostile_visitor.take_hit(999999)
 game.check(game.regiments.copies[1][7]==2,"defeated ordinary robot queues two same-class replacements",failures)
 game.companions.enabled = false
 game.companions.budget = 2
 var count_before: int = game.regiments.team_count(false)
 game.regiments.tick(2.9)
 game.check(game.regiments.team_count(false)==count_before,"death copies wait three seconds before deploying",failures)
 game.regiments.tick(.2)
 game.check(game.regiments.team_count(false)==count_before+2 and game.regiments.copies[1][7]==0,"one death creates two actual additional soldiers after the delay",failures)
 var clone = game.enemies.back()
 clone.set_physics_process(false)
 game.companions.enabled = true
 clone.armor = 0
 clone.take_hit(999999)
 game.companions.enabled = false
 game.check(game.regiments.copies[1][7]==2,"copied soldiers can die and recursively schedule further copies",failures)
 game.regiments.enabled = false
 game.career = original
 game.active = false
 for path in [profile.path,profile.path+".tmp"]:
  if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
