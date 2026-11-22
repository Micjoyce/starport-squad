extends Node3D
const F = preload("res://scripts/factory.gd")
const Gear = preload("res://scripts/gear.gd")
const PlayerScript = preload("res://scripts/player.gd")
const DroneScript = preload("res://scripts/drone.gd")
const HudScript = preload("res://scripts/hud.gd")
const GearChecks = preload("res://scripts/gear_checks.gd")
const Career = preload("res://scripts/career.gd")
const CareerChecks = preload("res://scripts/career_checks.gd")
var career: RefCounted
var resources: Array = []
var inventory_origin := "menu"
var rng := RandomNumberGenerator.new()
var world: Node3D
var player: CharacterBody3D
var menu_camera: Camera3D
var hud: Control
var difficulty := 0
var equipment: Array = []
var grenades: Array = []
var enemies: Array = []
var pickups: Array = []
var bolts: Array = []
var effects: Array = []
var blockers: Array[Rect2] = []
var navigation := AStarGrid2D.new()
var capture_delay := 0.0
var active := false
var mode := "menu"
var elapsed := 0.0
var world_time := 0.0
var kills := 0
var shots := 0
var hits := 0
var rescues := 0
var cells := 0
var extraction := 0.0
var extracting := false
var hit_marker := 0.0
var hurt_flash := 0.0
var toast := ""
var toast_time := 0.0
var assist := true
var music_on := true
var sfx_on := true
var low_motion := false
var sensitivity := .0022
var extraction_position := Vector3(0,0,24)
var reactor: Node3D
var pad: MeshInstance3D
var sounds := {}
var sound_pool: Array[AudioStreamPlayer] = []
var sound_index := 0
var music: AudioStreamPlayer
var ui_accumulator := 0.0
var perf_samples: Array[float] = []
var test_mode := false
var smoke_mode := false
var cyan: StandardMaterial3D
var orange: StandardMaterial3D
var dark: StandardMaterial3D
var steel: StandardMaterial3D
var light_metal: StandardMaterial3D
var black: StandardMaterial3D
var floor_mat: StandardMaterial3D

func _ready() -> void:
 DisplayServer.window_set_title("星港小队 · STARPORT SQUAD")
 rng.seed = 42031
 test_mode = "--self-test" in OS.get_cmdline_user_args()
 smoke_mode = "--render-test" in OS.get_cmdline_user_args() or "--ui-test" in OS.get_cmdline_user_args()
 setup_inputs()
 load_settings()
 if test_mode:
  difficulty = 0
 elif "--nightmare" in OS.get_cmdline_user_args():
  difficulty = 2
 elif "--hard" in OS.get_cmdline_user_args():
  difficulty = 1
 career = Career.new()
 if test_mode or smoke_mode:
  career.path = ""
 career.load_profile()
 build_audio()
 cyan = F.mat(Color("57e3db"),1.5)
 orange = F.mat(Color("ffb05e"),1.0)
 dark = F.mat(Color("26394b"))
 steel = F.mat(Color("455c70"))
 light_metal = F.mat(Color("a0b1bb"))
 black = F.mat(Color("111e2b"))
 floor_mat = F.mat(Color("304553"))
 build_world()
 player = CharacterBody3D.new()
 player.set_script(PlayerScript)
 player.game = self
 add_child(player)
 player.position = Vector3(0,.15,23)
 player.sensitivity = sensitivity
 apply_career()
 menu_camera = Camera3D.new()
 add_child(menu_camera)
 menu_camera.position = Vector3(19,10,24)
 menu_camera.look_at(Vector3(-2,2,-6))
 menu_camera.fov = 68
 menu_camera.current = true
 var canvas = CanvasLayer.new()
 add_child(canvas)
 hud = Control.new()
 hud.set_script(HudScript)
 hud.game = self
 canvas.add_child(hud)
 hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 spawn_enemies()
 if test_mode:
  call_deferred("run_tests")
 elif "--ui-test" in OS.get_cmdline_user_args():
  call_deferred("run_ui_test")
 elif smoke_mode:
  start_game()
  call_deferred("run_render_test")

func setup_inputs() -> void:
 var keys = {"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"jump":KEY_SPACE,"sprint":KEY_SHIFT,"reload":KEY_R,"interact":KEY_E,"weapon1":KEY_1,"weapon2":KEY_2,"pause":KEY_ESCAPE,"inventory":KEY_B,"skill_dash":KEY_Q,"skill_heal":KEY_F,"skill_pulse":KEY_G}
 for action in keys:
  InputMap.add_action(action)
  var event = InputEventKey.new()
  event.physical_keycode = keys[action]
  InputMap.action_add_event(action,event)
 for pair in [["fire",MOUSE_BUTTON_LEFT],["aim",MOUSE_BUTTON_RIGHT]]:
  InputMap.add_action(pair[0])
  var event = InputEventMouseButton.new()
  event.button_index = pair[1]
  InputMap.action_add_event(pair[0],event)

func build_audio() -> void:
 for key in ["ak","shotgun","reload","switch","hit","hurt","break","pickup","step","win","bolt"]:
  sounds[key] = load("res://assets/"+key+".wav")
 for i in range(16):
  var a = AudioStreamPlayer.new()
  a.bus = "SFX"
  add_child(a)
  sound_pool.append(a)
 music = AudioStreamPlayer.new()
 music.stream = load("res://assets/orbital_drift.wav")
 music.bus = "Music"
 add_child(music)
 if not test_mode:
  music.play()
 apply_audio()

func sound(key: String, volume: float = 1.0) -> void:
 if test_mode:
  return
 var a = sound_pool[sound_index % sound_pool.size()]
 sound_index += 1
 a.stream = sounds[key]
 a.volume_db = linear_to_db(volume)
 a.pitch_scale = rng.randf_range(.96,1.04) if key in ["ak","shotgun","step","break"] else 1
 a.play()

func apply_audio() -> void:
 AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),not music_on)
 AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"),not sfx_on)

func load_settings() -> void:
 var cfg = ConfigFile.new()
 if cfg.load("user://settings.cfg") == OK:
  music_on = cfg.get_value("audio","music",true)
  sfx_on = cfg.get_value("audio","sfx",true)
  assist = cfg.get_value("game","assist",true)
  low_motion = cfg.get_value("game","low_motion",false)
  sensitivity = cfg.get_value("game","sensitivity",.0022)
  difficulty = clampi(int(cfg.get_value("game","difficulty",0)),0,2)

func save_settings() -> void:
 var cfg = ConfigFile.new()
 cfg.set_value("audio","music",music_on)
 cfg.set_value("audio","sfx",sfx_on)
 cfg.set_value("game","assist",assist)
 cfg.set_value("game","low_motion",low_motion)
 cfg.set_value("game","sensitivity",sensitivity)
 cfg.set_value("game","difficulty",difficulty)
 cfg.save("user://settings.cfg")

func solid(pos: Vector3, size: Vector3, material: Material, nav: bool = true) -> MeshInstance3D:
 if nav:
  blockers.append(Rect2(Vector2(pos.x-size.x/2-.45,pos.z-size.z/2-.45),Vector2(size.x+.9,size.z+.9)))
 return F.box(world,pos,size,material,true)

func build_world() -> void:
 world = Node3D.new()
 add_child(world)
 var env_node = WorldEnvironment.new()
 var env = Environment.new()
 env.background_mode = Environment.BG_SKY
 var sky = Sky.new()
 var sky_material = ShaderMaterial.new()
 sky_material.shader = load("res://scripts/space.gdshader")
 sky.sky_material = sky_material
 env.sky = sky
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("94c7e0")
 env.ambient_light_energy = .65
 env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 env_node.environment = env
 add_child(env_node)
 var sun = DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-55,-35,0)
 sun.light_color = Color("d8edff")
 sun.light_energy = 1.7
 sun.shadow_enabled = true
 sun.directional_shadow_max_distance = 65
 add_child(sun)
 solid(Vector3(0,-.4,0),Vector3(56,.8,64),floor_mat,false)
 # Inlaid deck panels, navigation lanes, and warning stripes.
 var alternate_floor = F.mat(Color("354b59"))
 for x in range(-26,28,4):
  for z in range(-30,32,4):
   F.box(world,Vector3(x,.006,z),Vector3(3.93,.015,3.93),floor_mat if (x+z)%8 else alternate_floor)
 for x in [-25,25]:
  F.box(world,Vector3(x,.025,0),Vector3(.12,.025,61),cyan)
 for x in [-9,9]:
  F.box(world,Vector3(x,.026,1),Vector3(.10,.025,48),orange)
 for z in range(-26,28,4):
  for x in [-9.4,9.4]:
   F.box(world,Vector3(x,.035,z),Vector3(.55,.025,1.2),orange)
 # Reinforced hull ribs frame large open observation bays.
 for side in [-1,1]:
  solid(Vector3(side*28,1.0,0),Vector3(.8,2,64),dark)
  solid(Vector3(side*28,7,0),Vector3(1,1.2,64),dark)
  for z in range(-30,34,10):
   solid(Vector3(side*27.4,4,z),Vector3(1.2,8,1.2),steel)
   F.box(world,Vector3(side*26.7,4,z),Vector3(.08,5,.14),cyan)
  for z in range(-25,30,10):
   for h in [2.7,5.7]:
    F.box(world,Vector3(side*27.8,h,z),Vector3(.15,.12,8.8),light_metal)
 # Bulkhead and gate.
 solid(Vector3(0,4,-32),Vector3(56,8,1),dark)
 solid(Vector3(0,2.3,32),Vector3(56,4.6,1),dark)
 for x in [-20,-10,0,10,20]:
  F.box(world,Vector3(x,4,-31.4),Vector3(7,5,.15),steel)
  F.box(world,Vector3(x,6.8,-31.25),Vector3(6,.08,.03),cyan)
 F.text3d(world,"ORBITAL / 07",Vector3(0,5,-31.1),150,Color("a0c9da"))
 F.text3d(world,"REACTOR OPERATIONS",Vector3(0,3.3,-31.08),40,Color("ffb05e"))
 for z in [-22,-6,10,28]:
  F.box(world,Vector3(0,8,z),Vector3(55,.7,.7),dark)
  F.box(world,Vector3(0,7.6,z),Vector3(20,.08,.30),light_metal)
  for x in [-18,18]:
   var support = F.box(world,Vector3(x,6.7,z),Vector3(5,.35,.6),steel)
   support.rotation.z = -.5 if x < 0 else .5
 # Central reactor, with protected solid footprint.
 reactor = Node3D.new()
 world.add_child(reactor)
 reactor.position = Vector3(0,0,-9)
 solid(Vector3(0,1.1,-9),Vector3(6,2.2,6),dark)
 F.cylinder(reactor,Vector3(0,1,0),4.5,.4,black,12)
 F.cylinder(reactor,Vector3(0,1.28,0),3.7,.22,orange,12)
 F.cylinder(reactor,Vector3(0,1.5,0),3.4,.3,steel,12)
 F.cylinder(reactor,Vector3(0,3.6,0),1.6,4,cyan,12)
 for y in [2,3.1,4.2,5.5]:
  F.cylinder(reactor,Vector3(0,y,0),2.05,.22,dark,12)
 for i in range(6):
  var a = float(i)/6*TAU
  F.box(reactor,Vector3(sin(a)*2.2,3.6,cos(a)*2.2),Vector3(.32,4.8,.32),light_metal)
 F.cylinder(reactor,Vector3(0,6.1,0),3,.5,steel,12)
 F.cylinder(reactor,Vector3(0,6.4,0),2.7,.09,orange,12)
 # Cargo stacks: cover, silhouettes, and clear routes on each side.
 for spec in [[-17,14,3.6,2.7], [16,12,4.2,3.0], [-17,-4,4.0,3.2], [17,-9,3.5,2.5],[-13,-22,4.3,2.8],[14,-24,4.0,3.0],[6,9,2.2,1.2],[-7,3,2.8,1.3]]:
  build_crate(Vector3(spec[0],0,spec[1]),float(spec[2]),float(spec[3]))
 # Wall machinery and coolant pipes.
 for side in [-1,1]:
  for z in [-22,-10,2,14]:
   solid(Vector3(side*24,1.1,z),Vector3(2.6,2.2,4),steel)
   F.box(world,Vector3(side*22.65,1.4,z),Vector3(.035,.55,1.5),black)
   F.box(world,Vector3(side*22.61,1.4,z),Vector3(.04,.08,1.1),cyan)
  for h in [3.1,3.8]:
   var pipe = F.cylinder(world,Vector3(side*26.3,h,0),.16,58,light_metal)
   pipe.rotation.x = PI/2
 # Departure pad and a small rescue shuttle.
 pad = F.cylinder(world,Vector3(0,.035,24),4,.06,F.mat(Color("326c75"),.35),32)
 for i in range(12):
  var a = i*TAU/12
  var marker = F.box(world,Vector3(sin(a)*3.7,.08,24+cos(a)*3.7),Vector3(.25,.06,.8),cyan)
  marker.rotation.y = a
 F.text3d(world,"03 / EXTRACTION",Vector3(0,3.8,30.9),75,Color("5fe8dd")).rotation.y = PI
 var shuttle = Node3D.new()
 world.add_child(shuttle)
 shuttle.position = Vector3(16,2.5,26)
 F.box(shuttle,Vector3.ZERO,Vector3(5,2,6),light_metal)
 F.box(shuttle,Vector3(0,.4,-3.0),Vector3(3.6,1.1,.1),F.mat(Color("1d6579"),.6))
 for side in [-1,1]:
  F.box(shuttle,Vector3(side*3,-.5,.5),Vector3(3,.35,4),steel)
  var engine = F.cylinder(shuttle,Vector3(side*2.5,0,2.7),.6,2.8,dark)
  engine.rotation.x = PI/2
  var glow = F.cylinder(shuttle,Vector3(side*2.5,0,4.15),.45,.03,cyan)
  glow.rotation.x = PI/2
 # Energy stations placed on three distinct, reachable routes.
 build_cell(Vector3(-19,0,-18),"A", "CARGO")
 build_cell(Vector3(18,0,-20),"B", "COOLANT")
 build_cell(Vector3(1,0,-26),"C", "REACTOR")
 build_navigation()
 batch_static_geometry()
 build_equipment()

func batch_static_geometry() -> void:
 var groups := {}
 for child in world.get_children():
  if child is MeshInstance3D and child.mesh:
   var material = child.material_override
   var key = material.get_instance_id()
   if not groups.has(key):
    groups[key] = {"surface":SurfaceTool.new(),"material":material,"meshes":[]}
    groups[key].surface.begin(Mesh.PRIMITIVE_TRIANGLES)
   groups[key].surface.append_from(child.mesh,0,child.transform)
   groups[key].meshes.append(child)
 for key in groups:
  var group = groups[key]
  var combined = MeshInstance3D.new()
  combined.mesh = group.surface.commit()
  combined.material_override = group.material
  world.add_child(combined)
  for old in group.meshes:
   for nested in old.get_children():
    nested.reparent(world,true)
   old.queue_free()

func build_crate(pos: Vector3, width: float, height: float) -> void:
 solid(pos+Vector3(0,height/2,0),Vector3(width,height,3.3),dark)
 F.box(world,pos+Vector3(0,height/2,1.67),Vector3(width-.3,height-.3,.05),steel)
 for x in [-width/2+.25,width/2-.25]:
  F.box(world,pos+Vector3(x,height/2,1.72),Vector3(.14,height-.2,.07),light_metal)
 F.box(world,pos+Vector3(0,height-.25,1.75),Vector3(width-.55,.16,.04),orange)
 F.text3d(world,"OR / 07",pos+Vector3(0,height/2,1.78),28,Color("c8d8df"))
 if height > 2.5:
  F.box(world,pos+Vector3(0,height+.12,0),Vector3(width+.1,.24,3.4),black)

func build_cell(pos: Vector3, letter: String, area: String) -> void:
 var root = Node3D.new()
 world.add_child(root)
 root.position = pos
 F.cylinder(root,Vector3(0,.2,0),1.15,.4,steel,8)
 F.cylinder(root,Vector3(0,.44,0),.9,.08,cyan,8)
 var item = Node3D.new()
 root.add_child(item)
 item.position.y = 1.25
 F.cylinder(item,Vector3.ZERO,.28,.80,cyan,6)
 F.cylinder(item,Vector3(0,.43,0),.36,.14,light_metal,6)
 F.cylinder(item,Vector3(0,-.43,0),.36,.14,light_metal,6)
 var label = F.text3d(root,letter+" / ENERGY",Vector3(0,2.3,0),48,Color("65f5e3"))
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 pickups.append({"node":root,"item":item,"pos":pos,"letter":letter,"area":area,"taken":false})

func build_navigation() -> void:
 navigation.region = Rect2i(-27,-31,55,63)
 navigation.cell_size = Vector2.ONE
 navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
 navigation.update()
 for x in range(-27,28):
  for z in range(-31,32):
   for rect in blockers:
    if rect.has_point(Vector2(x,z)):
     navigation.set_point_solid(Vector2i(x,z))
     break

func find_path(from: Vector3, to: Vector3) -> PackedVector2Array:
 var a = Vector2i(roundi(from.x),roundi(from.z))
 var b = Vector2i(clampi(roundi(to.x),-26,26),clampi(roundi(to.z),-30,30))
 if not navigation.is_in_boundsv(a) or navigation.is_point_solid(a) or navigation.is_point_solid(b):
  return PackedVector2Array()
 return navigation.get_point_path(a,b)

func spawn_enemies() -> void:
 var positions = [Vector3(-11,.1,-15),Vector3(11,.1,-18),Vector3(-20,.1,1),Vector3(19,.1,0),Vector3(-5,.1,-25),Vector3(7,.1,-27),Vector3(-11,.1,10),Vector3(11,.1,16),Vector3(-20,.1,19),Vector3(20,.1,20)]
 for i in range(Gear.BOT_COUNTS[difficulty]):
  spawn_enemy(positions[i])

func spawn_enemy(pos: Vector3) -> Node3D:
 var bot = CharacterBody3D.new()
 bot.set_script(DroneScript)
 bot.game = self
 var index = enemies.size()%Gear.BOT_COUNTS[difficulty]
 bot.armor_tier = Gear.BOT_ARMOR[difficulty][index]
 bot.weapon_tier = Gear.BOT_GUNS[difficulty][index]
 bot.weapon_kind = index%2
 add_child(bot)
 bot.position = pos
 bot.home = pos
 enemies.append(bot)
 return bot

func start_game() -> void:
 active = true
 capture_delay = .2
 mode = "playing"
 player.camera.current = true
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 hud.show_page("playing")
 message("任务开始 · 按 E 收集能源，跟随 A / B / C 标记",5)

func pause_game() -> void:
 if mode == "playing":
  active = false
  mode = "paused"
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
  hud.show_page("paused")
 elif mode == "paused":
  start_game()

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("inventory"):
  open_backpack()
  return
 if event.is_action_pressed("pause") and hud.page=="inventory":
  close_backpack()
  return
 if event.is_action_pressed("pause"):
  pause_game()
 if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == "playing" and not smoke_mode and not test_mode:
  pause_game()

func _process(dt: float) -> void:
 if is_instance_valid(music):
  music.volume_db = lerpf(music.volume_db,2.0 if extracting else (-2.0 if active else 0.0),minf(1,dt*2))
 if mode == "menu":
  world_time += dt
  menu_camera.position.x = 19+sin(world_time*.10)*1.8
  menu_camera.look_at(Vector3(-2,2,-6))
 if active:
  capture_delay = maxf(0,capture_delay-dt)
  elapsed += dt
  world_time += dt
  hit_marker = maxf(0,hit_marker-dt)
  hurt_flash = maxf(0,hurt_flash-dt)
  toast_time = maxf(0,toast_time-dt)
  if extracting:
   if player.position.distance_to(extraction_position) < 4.3:
    extraction += dt
   if extraction >= 12:
    win()
  if elapsed > 150 and (absf(player.position.x)>23 or player.position.z < -28):
   player.damage(5)
  perf_samples.append(dt)
  if perf_samples.size() > 3600:
   perf_samples.pop_front()
 for item in equipment:
  if not item.taken:
   item.item.rotation.y += dt*.5
 for item in pickups:
  if not item.taken:
   item.item.rotation.y += dt*.8
   item.item.position.y = 1.25+sin(world_time*2+float(item.letter.unicode_at(0)))*.12
 ui_accumulator += dt
 if ui_accumulator > .03:
  hud.queue_redraw()
  ui_accumulator = 0

func _physics_process(dt: float) -> void:
 if not active:
  return
 step_grenades(dt)
 for i in range(bolts.size()-1,-1,-1):
  var b = bolts[i]
  b.life -= dt
  var old: Vector3 = b.node.position
  var next: Vector3 = old+b.dir*dt*12
  var q = PhysicsRayQueryParameters3D.create(old,next,3)
  var hit = get_world_3d().direct_space_state.intersect_ray(q)
  if not hit.is_empty():
   if hit.collider == player:
    player.damage(12)
   spark(hit.position,Color("ff987a"),3)
   b.life = 0
  b.node.position = next
  if b.life <= 0:
   b.node.queue_free()
   bolts.remove_at(i)
 for i in range(effects.size()-1,-1,-1):
  var fx = effects[i]
  fx.life -= dt
  if fx.has("velocity"):
   fx.node.position += fx.velocity*dt
   fx.velocity.y -= dt*4
   fx.node.scale *= .96
  if fx.life <= 0:
   fx.node.queue_free()
   effects.remove_at(i)

func clear_line(from: Vector3, to: Vector3, target: Node3D) -> bool:
 var q = PhysicsRayQueryParameters3D.create(from,to,1 | 2 | 4)
 if is_instance_valid(player):
  if target != player:
   q.exclude = [player.get_rid()]
 var hit = get_world_3d().direct_space_state.intersect_ray(q)
 return hit.is_empty() or hit.collider == target

func launch_bolt(origin: Vector3, direction: Vector3) -> void:
 var mesh = F.sphere(self,origin,.13,F.mat(Color("ff8469"),2))
 bolts.append({"node":mesh,"dir":direction,"life":3.0})
 if player.position.distance_to(origin)<16:
  sound("bolt",.18)

func tracer(from: Vector3, to: Vector3, color: Color, life: float) -> void:
 var mid = (from+to)/2
 var beam = F.box(self,mid,Vector3(.012,.012,from.distance_to(to)),F.mat(color,1))
 if from.distance_squared_to(to) > .0001:
  beam.look_at(to,Vector3.UP)
 effects.append({"node":beam,"life":life})

func spark(pos: Vector3, color: Color, count: int) -> void:
 for i in range(count):
  var mesh = F.box(self,pos,Vector3(.045,.045,.045),F.mat(color,1.5))
  effects.append({"node":mesh,"life":rng.randf_range(.15,.4),"velocity":Vector3(rng.randf_range(-2,2),rng.randf_range(1,3),rng.randf_range(-2,2))})

func nearby_cell() -> int:
 for i in range(pickups.size()):
  if not pickups[i].taken and player.position.distance_to(pickups[i].pos) < 2.5:
   return i
 return -1

func interact() -> void:
 var i = nearby_cell()
 if i >= 0:
  pickups[i].taken = true
  pickups[i].node.visible = false
  cells += 1
  career.earn(25)
  sound("pickup")
  player.shield = minf(player.max_shield(),player.shield+25)
  if cells == 3:
   message("能源收集完成！返回青色撤离平台，按 E 启动飞船",6)
  else:
   message("能源 "+str(cells)+" / 3 · 护盾补充 +25",3)
 elif nearby_resource()>=0:
  collect_resource(nearby_resource())
 elif nearby_equipment()>=0:
  take_equipment(nearby_equipment())
 elif cells == 3 and player.position.distance_to(extraction_position) < 4.3 and not extracting:
  extracting = true
  sound("pickup")
  message("飞船充能中 · 留在平台内完成撤离",5)
  spawn_enemy(Vector3(-10,.1,5))
  spawn_enemy(Vector3(10,.1,2))

func message(value: String, duration: float = 3.0) -> void:
 toast = value
 toast_time = duration

func win() -> void:
 if mode=="win":
  return
 career.record_win(100*(difficulty+1))
 active = false
 mode = "win"
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 sound("win")
 hud.show_page("win")

func restart() -> void:
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 get_tree().reload_current_scene()

func run_tests() -> void:
 await get_tree().physics_frame
 await get_tree().physics_frame
 var failures: Array[String] = []
 check(pickups.size()==3,"three energy cells",failures)
 check(enemies.size()==6,"six robots",failures)
 check(sounds.size()==11 and sounds.ak.get_length()>0,"eleven sound effects load",failures)
 check(music.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"original music loops",failures)
 check(player.ammo==[30,8],"initial magazines",failures)
 for item in pickups:
  check(find_path(Vector3(0,0,23),item.pos).size()>1,"reachable station "+item.letter,failures)
 start_game()
 player.switch_weapon(1)
 check(player.weapon==1 and player.weapons[1].visible and not player.weapons[0].visible,"weapon switch",failures)
 player.ammo[1] = 2
 player.reload_weapon()
 check(player.reload_left>0,"reload begins",failures)
 player.reload_left = .001
 await get_tree().physics_frame
 await get_tree().physics_frame
 check(player.ammo[1]==8,"reload completes",failures)
 player.switch_weapon(0)
 # Real physics ray: isolated stationary robot in an unobstructed firing lane.
 var bot = spawn_enemy(Vector3(0,.1,17))
 player.position = Vector3(0,.1,23)
 player.rotation = Vector3.ZERO
 player.camera.rotation = Vector3.ZERO
 await get_tree().physics_frame
 await get_tree().physics_frame
 var old_hp: float = bot.hp+bot.armor
 var old_ammo: int = player.ammo[0]
 player.shoot()
 check(player.ammo[0]==old_ammo-1,"firing consumes ammo",failures)
 check(bot.hp+bot.armor<old_hp,"hitscan damages robot",failures)
 # Verify physical movement, collision, jumping, ammunition rules, and projectile impacts.
 for enemy in enemies:
  if is_instance_valid(enemy):
   enemy.set_physics_process(false)
 player.position = Vector3(0,.1,23)
 player.rotation = Vector3.ZERO
 player.camera.rotation = Vector3.ZERO
 player.cooldown = 0
 Input.action_press("forward")
 for frame in range(30):
  await get_tree().physics_frame
 Input.action_release("forward")
 check(player.position.z<21,"W moves player forward",failures)
 Input.action_press("back")
 for frame in range(180):
  await get_tree().physics_frame
 Input.action_release("back")
 check(player.position.z<31.3 and player.position.z>30,"bulkhead collision blocks movement",failures)
 for frame in range(15):
  await get_tree().physics_frame
 Input.action_press("jump")
 await get_tree().physics_frame
 await get_tree().physics_frame
 Input.action_release("jump")
 var jump_height: float = player.position.y
 for frame in range(10):
  await get_tree().physics_frame
 check(player.position.y>jump_height+.2,"space jumps",failures)
 for frame in range(70):
  await get_tree().physics_frame
 check(player.is_on_floor(),"jump lands on deck",failures)
 player.ammo[0] = 0
 player.cooldown = 0
 player.reload_left = 0
 player.shoot()
 check(player.reload_left>0 and player.ammo[0]==0,"empty magazine auto reloads",failures)
 player.switch_weapon(1)
 check(player.reload_left==0,"switch cancels reload without filling ammo",failures)
 player.position = Vector3(0,.1,23)
 player.camera.rotation = Vector3.ZERO
 player.rotation = Vector3.ZERO
 var close_bot = spawn_enemy(Vector3(0,.1,19))
 close_bot.set_physics_process(false)
 player.ammo[1] = 8
 player.cooldown = 0
 await get_tree().physics_frame
 await get_tree().physics_frame
 player.shoot()
 check(player.ammo[1]==7,"shotgun consumes one shell",failures)
 check(close_bot.hp+close_bot.armor<100+Gear.SHIELD[close_bot.armor_tier],"shotgun pellets damage robot",failures)
 var after_shot: int = player.ammo[1]
 player.shoot()
 check(player.ammo[1]==after_shot,"fire rate limits repeated shots",failures)
 for enemy in enemies:
  if is_instance_valid(enemy):
   enemy.collision_layer = 0
 player.hurt_cooldown = 0
 player.shield = 100
 player.shield_delay = 10
 launch_bolt(player.camera.global_position+Vector3(0,0,-2),Vector3.BACK)
 for frame in range(20):
  await get_tree().physics_frame
 check(player.shield<100,"enemy energy projectile damages shield",failures)
 player.hurt_cooldown = 0
 player.damage(5)
 var shield_before: float = player.shield
 player.damage(5)
 check(player.shield==shield_before,"brief damage protection",failures)
 player.shield_delay = 0
 for frame in range(20):
  await get_tree().physics_frame
 check(player.shield>shield_before,"shield regenerates after delay",failures)
 # Walk complete grid paths using the same W + Shift input as a player.
 player.position = Vector3(0,.1,23)
 player.velocity = Vector3.ZERO
 player.reload_left = 0
 for item in pickups:
  var route = find_path(player.position,item.pos)
  var walk_ok = true
  for waypoint in route:
   var goal = Vector3(waypoint.x,player.position.y,waypoint.y)
   var frames = 0
   while Vector2(player.position.x-goal.x,player.position.z-goal.z).length()>.35 and frames<90:
    goal.y = player.position.y
    player.look_at(goal,Vector3.UP)
    Input.action_press("forward")
    Input.action_press("sprint")
    await get_tree().physics_frame
    frames += 1
   if frames>=90:
    walk_ok = false
    break
  Input.action_release("forward")
  Input.action_release("sprint")
  check(walk_ok and player.position.distance_to(item.pos)<2,"physical route to station "+item.letter,failures)
 # Restore collision state before the rest of the mission tests.
 for enemy in enemies:
  if is_instance_valid(enemy) and enemy.hp>0:
   enemy.collision_layer = 4

 var old_shield: float = player.shield
 player.hurt_cooldown = 0
 player.damage(12)
 check(player.shield==old_shield-12,"shield damage",failures)
 player.hurt_cooldown = 0
 player.damage(1000)
 check(player.shield==100 and rescues>=1,"rescue on shield depleted",failures)
 for item in pickups:
  player.position = item.pos+Vector3(0,.1,0)
  interact()
 check(cells==3,"collect all cells",failures)
 interact()
 check(cells==3,"no duplicate collection",failures)
 player.position = extraction_position+Vector3.UP*.1
 interact()
 check(extracting,"extraction begins",failures)
 var previous: float = extraction
 player.position = Vector3(10,.1,24)
 _process(.1)
 check(extraction==previous,"extraction stops outside pad",failures)
 player.position = extraction_position
 _process(.1)
 check(extraction>previous,"extraction progresses inside pad",failures)
 pause_game()
 check(not active and mode=="paused","pause",failures)
 var saved: float = elapsed
 _process(.2)
 check(elapsed==saved,"pause freezes mission",failures)
 pause_game()
 check(active,"resume",failures)
 extraction = 11.99
 _process(.02)
 check(mode=="win" and not active,"successful extraction",failures)
 await GearChecks.run(self,failures)
 await CareerChecks.run(self,failures)
 var report = "STARPORT SQUAD — INTEGRATION TEST\nGodot "+Engine.get_version_info().string+"\n"
 report += "Failures: "+str(failures.size())+"\n"+"\n".join(failures)
 var out = FileAccess.open(report_path("test-results.txt"),FileAccess.WRITE)
 out.store_string(report)
 print(report)
 await get_tree().process_frame
 await get_tree().process_frame
 stop_audio()
 await get_tree().create_timer(.15).timeout
 get_tree().quit(0 if failures.is_empty() else 1)

func check(condition: bool, label: String, failures: Array[String]) -> void:
 print(("PASS " if condition else "FAIL ")+label)
 if not condition:
  failures.append(label)

func run_render_test() -> void:
 await get_tree().create_timer(.5).timeout
 player.rotation = Vector3.ZERO
 player.camera.rotation = Vector3.ZERO
 if "--gear-preview" in OS.get_cmdline_user_args():
  player.equip_armor(4)
  player.upgrade_weapon(4)
 await get_tree().create_timer(2.5).timeout
 # Native rendered menu / gameplay capture, never substitutes for human interaction testing.
 capture_frame("gameplay.png")
 var frame_durations: Array[float] = []
 var starting_enemies = enemies.size()
 var grenade_peak = 0
 for i in range(1200):
  if i == 60:
   Input.action_press("forward")
  elif i == 240:
   Input.action_release("forward")
   Input.action_press("right")
  elif i == 360:
   Input.action_release("right")
   Input.action_press("aim")
   Input.action_press("fire")
  elif i == 650:
   player.switch_weapon(1)
  elif i == 1000:
   Input.action_release("fire")
   Input.action_release("aim")
  await get_tree().process_frame
  frame_durations.append(get_process_delta_time())
  grenade_peak = maxi(grenade_peak,grenades.size())
 Input.action_release("forward")
 Input.action_release("right")
 Input.action_release("fire")
 Input.action_release("aim")
 var sum_dt := 0.0
 for value in frame_durations:
  sum_dt += value
 frame_durations.sort()
 var report = "Rendered combat benchmark, 1200 frames\nScenario: movement, AK47 + shotgun fire, reloads, active robots + grenades where enabled\nAverage FPS: %.1f\np95 frame time: %.2f ms\np99 frame time: %.2f ms\nDraw calls: %d\nObjects: %d\n" % [1200.0/sum_dt,frame_durations[1139]*1000,frame_durations[1187]*1000,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)]
 report += "Difficulty: "+Gear.MODES[difficulty]+"\nInitial robots: "+str(starting_enemies)+"\nPeak simultaneous grenades: "+str(grenade_peak)+"\n"
 FileAccess.open(report_path("benchmark.txt"),FileAccess.WRITE).store_string(report)
 print(report)
 if difficulty>0:
  throw_grenade(player.position+Vector3(0,.6,-4),player.position+Vector3(0,0,-3))
  await get_tree().create_timer(.25).timeout
  capture_frame("grenade-warning.png")
  await get_tree().create_timer(2.1).timeout
 open_backpack()
 hud.inventory_tab = 0
 hud.refresh_inventory()
 await get_tree().create_timer(.35).timeout
 capture_frame("inventory.png")
 hud.inventory_tab = 3
 hud.refresh_inventory()
 await get_tree().create_timer(.25).timeout
 capture_frame("skills.png")
 hud.inventory_tab = 4
 hud.refresh_inventory()
 await get_tree().create_timer(.35).timeout
 capture_frame("green-pants.png")
 active = false
 mode = "menu"
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 menu_camera.current = true
 hud.show_page("menu")
 await get_tree().create_timer(.4).timeout
 capture_frame("menu.png")
 stop_audio()
 await get_tree().create_timer(.15).timeout
 get_tree().quit()

func stop_audio() -> void:
 if is_instance_valid(music):
  music.stop()
  music.stream = null
 for audio in sound_pool:
  if is_instance_valid(audio):
   audio.stop()
   audio.stream = null
 sounds.clear()

func _exit_tree() -> void:
 stop_audio()

func report_path(filename: String) -> String:
 var directory = OS.get_environment("STARPORT_TEST_OUTPUT")
 if directory.is_empty():
  directory = ProjectSettings.globalize_path("res://..")
 return directory.path_join(filename)

func select_difficulty(value: int) -> void:
 if mode != "menu":
  return
 difficulty = clampi(value,0,2)
 for enemy in enemies:
  if is_instance_valid(enemy):
   enemy.queue_free()
 enemies.clear()
 spawn_enemies()
 if not test_mode:
  save_settings()
 hud.queue_redraw()

func build_equipment() -> void:
 var armor_positions = [Vector3(-6,0,20),Vector3(-10,0,12),Vector3(-20,0,-11),Vector3(20,0,-16),Vector3(5,0,-23)]
 var gun_positions = [Vector3(6,0,20),Vector3(11,0,5),Vector3(-10,0,-17),Vector3(10,0,-23),Vector3(-5,0,-26)]
 for tier in range(5):
  add_equipment(armor_positions[tier],"armor",tier)
  add_equipment(gun_positions[tier],"gun",tier)

func add_equipment(pos: Vector3, kind: String, tier: int, weapon_kind: int = -1) -> void:
 var root = Node3D.new()
 world.add_child(root)
 root.position = Vector3(pos.x,.08,pos.z)
 var material = F.mat(Gear.COLORS[tier],.7)
 F.cylinder(root,Vector3(0,.06,0),.65,.08,material,8)
 var item = Node3D.new()
 root.add_child(item)
 item.position.y = .85
 if kind == "armor":
  F.box(item,Vector3.ZERO,Vector3(.65,.55,.18),material)
  for side in [-1,1]:
   F.box(item,Vector3(side*.40,.13,0),Vector3(.17,.25,.22),material)
  F.box(item,Vector3(0,0,-.11),Vector3(.16,.20,.04),black)
 else:
  var display_gun = Gear.make_weapon(item,0 if weapon_kind<0 else weapon_kind,tier)
  display_gun.rotation.y = PI/2
 F.batch_meshes(item)
 var label = F.text3d(root,(Gear.SHORT[tier] if kind=="armor" else Gear.NAMES[tier].split(" · ")[0]+"枪械升级"),Vector3(0,1.6,0),23,Gear.COLORS[tier])
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 equipment.append({"node":root,"item":item,"pos":pos,"kind":kind,"tier":tier,"weapon_kind":weapon_kind,"taken":false})

func nearby_equipment() -> int:
 var best := -1
 var best_distance := 2.2
 for i in range(equipment.size()):
  var item = equipment[i]
  if item.taken:
   continue
  var distance = player.position.distance_to(item.pos)
  if distance<best_distance:
   best_distance = distance
   best = i
 return best

func take_equipment(index: int) -> void:
 var item = equipment[index]
 if item.taken:
  return
 var target_weapon: int = player.weapon if item.weapon_kind<0 else item.weapon_kind
 var kind: String = "armor" if item.kind=="armor" else ("ak" if target_weapon==0 else "sg")
 if not career.add_item(kind,item.tier):
  message("存档写入失败，装备仍留在原地",3)
  return
 if item.kind=="armor" and item.tier>=player.armor_tier:
  player.equip_armor(item.tier)
  career.equip("armor",item.tier)
 elif item.kind=="gun" and item.tier>=player.weapon_tiers[target_weapon]:
  player.switch_weapon(target_weapon)
  player.upgrade_weapon(item.tier)
  career.equip(kind,item.tier)
 item.taken = true
 item.node.visible = false
 sound("pickup")
 message(Gear.NAMES[item.tier]+("盔甲" if kind=="armor" else "枪械")+" · 已存入永久背包",3)

func drop_equipment(pos: Vector3, armor_tier: int, gun_tier: int, weapon_kind: int) -> void:
 # Two real, separately pickable drops; avoid growing the scene indefinitely.
 if equipment.size()<50:
  add_equipment(pos+Vector3(-.65,0,0),"armor",armor_tier)
  add_equipment(pos+Vector3(.65,0,0),"gun",gun_tier,weapon_kind)

func enemy_shot(bot: Node3D, origin: Vector3, aim: Vector3) -> void:
 var forward = (aim-origin).normalized()
 var total_damage := 0.0
 var pellets = 1 if bot.weapon_kind==0 else 9
 for pellet in range(pellets):
  var spread = .008 if bot.weapon_kind==0 else .065
  var direction = (forward+bot.global_basis.x*rng.randf_range(-spread,spread)+Vector3.UP*rng.randf_range(-spread,spread)).normalized()
  var q = PhysicsRayQueryParameters3D.create(origin,origin+direction*55,3)
  var hit = get_world_3d().direct_space_state.intersect_ray(q)
  var endpoint = origin+direction*40
  if not hit.is_empty():
   endpoint = hit.position
   if hit.collider==player:
    total_damage += Gear.damage(bot.weapon_kind,bot.weapon_tier,origin.distance_to(endpoint))*(.45 if difficulty==1 else .65)
  tracer(origin,endpoint,Gear.COLORS[bot.weapon_tier],.055)
 if total_damage>0:
  player.damage(total_damage)
 if origin.distance_to(player.position)<26:
  sound("ak" if bot.weapon_kind==0 else "shotgun",.28)
 spark(origin,Gear.COLORS[bot.weapon_tier],2)

func throw_grenade(origin: Vector3, target: Vector3) -> void:
 var g = Node3D.new()
 add_child(g)
 g.position = origin
 F.sphere(g,Vector3.ZERO,.18,F.mat(Color("27394a")))
 F.box(g,Vector3.ZERO,Vector3(.38,.06,.12),orange)
 var ring = MeshInstance3D.new()
 var mesh = TorusMesh.new()
 mesh.inner_radius = Gear.GRENADE_RADIUS-.10
 mesh.outer_radius = Gear.GRENADE_RADIUS
 mesh.rings = 32
 mesh.ring_segments = 6
 ring.mesh = mesh
 ring.material_override = F.mat(Color("ff7653"),1.5)
 add_child(ring)
 var flight := 1.15
 var landing = Vector3(target.x,.22,target.z)
 var velocity = (landing-origin)/flight+Vector3.UP*7*flight
 grenades.append({"node":g,"ring":ring,"velocity":velocity,"fuse":Gear.GRENADE_FUSE,"damage":Gear.GRENADE_BASE_DAMAGE*Gear.GRENADE_MULTIPLIER})
 sound("switch",.4)

func step_grenades(dt: float) -> void:
 for i in range(grenades.size()-1,-1,-1):
  var g = grenades[i]
  g.fuse -= dt
  g.velocity.y -= 14*dt
  var old: Vector3 = g.node.position
  var next: Vector3 = old+g.velocity*dt
  var q = PhysicsRayQueryParameters3D.create(old,next,1)
  var hit = get_world_3d().direct_space_state.intersect_ray(q)
  if not hit.is_empty():
   g.node.position = hit.position+hit.normal*.19
   g.velocity = g.velocity.bounce(hit.normal)*.30
  else:
   g.node.position = next
  var landing = g.node.position
  landing.y = .10
  g.ring.position = landing
  var pulse = .92+sin(g.fuse*16)*.08
  g.ring.scale = Vector3(pulse,1,pulse)
  if g.fuse<=0:
   explode_grenade(g.node.position,g.damage)
   g.node.queue_free()
   g.ring.queue_free()
   grenades.remove_at(i)

func grenade_damage_at(origin: Vector3, amount: float) -> float:
 var target = player.position+Vector3.UP*.8
 var distance = origin.distance_to(target)
 if distance>=Gear.GRENADE_RADIUS:
  return 0.0
 var q = PhysicsRayQueryParameters3D.create(origin,target,1)
 if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
  return 0.0
 return amount*(1.0-.65*distance/Gear.GRENADE_RADIUS)

func explode_grenade(origin: Vector3, amount: float) -> void:
 var damage = grenade_damage_at(origin,amount)
 if damage>0:
  player.damage(damage)
 spark(origin,Color("ffbd71"),24)
 var blast = F.sphere(self,origin,.8,F.mat(Color("ffac61"),2.0))
 effects.append({"node":blast,"life":.18})
 sound("shotgun",.75)

func apply_career() -> void:
 player.equip_armor(career.equipped.armor)
 player.weapon_tiers = [career.equipped.ak,career.equipped.sg]
 for i in range(2):
  Gear.paint_weapon(player.weapons[i],player.weapon_tiers[i])
 player.set_pants_style(career.green_pants)

func equip_owned(kind: String, tier: int) -> void:
 if career.equip(kind,tier):
  apply_career()
  message("装备已穿戴并保存",2)
 else:
  message("无法装备：检查库存或存档写入",2)

func open_backpack() -> void:
 if hud.page=="inventory":
  close_backpack()
  return
 inventory_origin = mode
 active = false
 if mode=="playing":
  mode = "paused"
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 hud.show_page("inventory")

func close_backpack() -> void:
 if inventory_origin=="playing":
  start_game()
 else:
  mode = inventory_origin
  hud.show_page(mode)

func drop_resources(pos: Vector3, amount: int) -> void:
 if resources.size()>=64:
  return
 var root = Node3D.new()
 world.add_child(root)
 root.position = Vector3(pos.x,.12,pos.z)
 var material = F.mat(Color("78ef99"),1)
 F.box(root,Vector3(0,.20,0),Vector3(.32,.35,.32),material).rotation.y = PI/4
 var label = F.text3d(root,"资源 +"+str(amount),Vector3(0,.9,0),24,Color("78ef99"))
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 resources.append({"node":root,"pos":pos,"amount":amount,"taken":false})

func nearby_resource() -> int:
 for i in range(resources.size()):
  if not resources[i].taken and player.position.distance_to(resources[i].pos)<2.2:
   return i
 return -1

func collect_resource(index: int) -> void:
 var item = resources[index]
 if item.taken:
  return
 if career.earn(item.amount):
  item.taken = true
  item.node.visible = false
  sound("pickup")
  message("资源币 +"+str(item.amount)+" · 已永久保存",3)
 else:
  message("存档写入失败，资源仍留在原地",3)

func capture_frame(filename: String) -> void:
 RenderingServer.force_draw()
 get_viewport().get_texture().get_image().save_png(report_path(filename))

func run_ui_test() -> void:
 open_backpack()
 for tab in [0,3,4]:
  hud.inventory_tab = tab
  hud.refresh_inventory()
  await get_tree().create_timer(.3).timeout
  capture_frame(["inventory.png","skills.png","green-pants.png"][[0,3,4].find(tab)])
 stop_audio()
 await get_tree().create_timer(.15).timeout
 get_tree().quit()
