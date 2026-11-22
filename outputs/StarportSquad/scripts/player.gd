extends CharacterBody3D
const F = preload("res://scripts/factory.gd")
const Gear = preload("res://scripts/gear.gd")
const Operative = preload("res://scripts/operative.gd")
var knife: Node3D
var melee_ready := false
var rounds_emitted := 0
const ROLL_DURATION := .42
const ROLL_COOLDOWN := 1.2
var sword: Node3D
var sword_selected := false
var sword_swing := 0.0
var roll_left := 0.0
var roll_ready_in := 0.0
var roll_direction := Vector3.ZERO
var roll_bank := 0.0
var slide_left := 0.0
var slide_distance := 0.0
var slide_direction := Vector3.ZERO
var prone := false
var capsule_shape: CapsuleShape3D
var body_collision: CollisionShape3D
var armor_broken := false
var broken_surface: Material
var hp := 100.0
var helmet_health := 0.0
var helmet_defense := 0.0
var max_hp := 100.0
var grenade_cooldown := 0.0
var overcharged := false
var armor_big := false
var weapon_models := [0,1]
var weapon_big := [false,false]
var third_person := false
var body_model: Node3D
var rainbow_material: Material
var game: Node3D
var camera: Camera3D
var gun: Node3D
var flash: Node3D
var weapons: Array[Node3D] = []
var armor_tier := 0
var weapon_tiers := [0,0]
var armor_material: StandardMaterial3D
var weapon := 0
var ammo := [30, 8]
var capacity := [30, 8]
var reload_left := 0.0
var cooldown := 0.0
var recoil := 0.0
var bob := 0.0
var shield := 100.0
var hurt_cooldown := 0.0
var shield_delay := 0.0
var ads := false
var sensitivity := 0.0022
var muzzle_light: OmniLight3D
var walking := false
var feet_timer := 0.0
var pants: Node3D
var pants_green: ShaderMaterial
var pants_plain: Material

func _ready() -> void:
 collision_layer = 2
 collision_mask = 1
 var capsule = CapsuleShape3D.new()
 capsule_shape = capsule
 capsule.radius = 0.34
 capsule.height = 1.8
 var shape = CollisionShape3D.new()
 body_collision = shape
 shape.shape = capsule
 shape.position.y = 0.9
 add_child(shape)
 camera = Camera3D.new()
 add_child(camera)
 camera.position.y = 1.58
 camera.fov = 82
 camera.near = 0.04
 gun = Node3D.new()
 camera.add_child(gun)
 gun.position = Vector3(0.28, -0.25, -0.46)
 build_weapons()
 knife = Gear.make_knife(gun)
 knife.position = Vector3(0,-.03,-.15)
 knife.visible = false
 sword = Gear.make_sword(gun)
 sword.hide()
 build_pants()
 rainbow_material = Gear.armor_surface(5)
 body_model = Operative.make_body(self,armor_material,pants_green,weapon,weapon_tiers,true,false)
 body_model.visible = false
 refresh_body()

func build_weapons() -> void:
 armor_material = F.mat(Gear.COLORS[armor_tier])
 var glove = F.mat(Color("111c29"))
 for i in range(2):
  var w = Gear.make_weapon(gun,weapon_models[i],weapon_tiers[i])
  weapons.append(w)
  F.box(w,Vector3(.04,-.17,.18),Vector3(.13,.15,.17),glove).rotation.x = -.3
  F.box(w,Vector3(.09,-.24,.32),Vector3(.17,.15,.32),armor_material).set_meta("armor",true)
  w.get_child(w.get_child_count()-1).rotation.x = -.35
  F.box(w,Vector3(-.05,-.10,-.20),Vector3(.14,.12,.16),glove)
  F.box(w,Vector3(-.10,-.20,-.03),Vector3(.16,.16,.30),armor_material).set_meta("armor",true)
  w.get_child(w.get_child_count()-1).rotation.x = .6
  w.visible = i == weapon
 flash = Node3D.new()
 gun.add_child(flash)
 flash.position = Vector3(0,0,-.69)
 F.sphere(flash,Vector3.ZERO,.065,F.mat(Color("ffe9a5"),3.0))
 flash.visible = false
 muzzle_light = OmniLight3D.new()
 muzzle_light.light_color = Color("ffd59b")
 muzzle_light.omni_range = 4
 muzzle_light.light_energy = 0
 flash.add_child(muzzle_light)

func _unhandled_input(event: InputEvent) -> void:
 if not game.active:
  return
 if event is InputEventMouseMotion:
  if game.capture_delay > 0 or game.smoke_mode:
   return
  rotate_y(-event.relative.x * sensitivity)
  camera.rotation.x = clamp(camera.rotation.x-event.relative.y*sensitivity, -1.35,1.35)
 if game.vehicles.current!=null:
  return
 if event.is_action_pressed("roll"):
  start_roll()
  return
 if roll_left>0:
  return
 if event.is_action_pressed("pulse_charge"):
  game.pulse_charge.request_launch()
 if event.is_action_pressed("slide"):
  start_slide()
 if event.is_action_pressed("prone"):
  set_prone(not prone)
 if event.is_action_pressed("overcharge"):
  activate_overcharge()
 if event.is_action_pressed("player_grenade"):
  throw_player_grenade()
 if event.is_action_pressed("view_toggle"):
  set_view(not third_person,not game.campaign.enabled)
 if event.is_action_pressed("coat_heal"):
  coat_heal()
 for i in range(3):
  if event.is_action_pressed(["skill_dash","skill_heal","skill_pulse"][i]):
   use_skill(i)
 if event.is_action_pressed("reload"):
  reload_weapon()
 if event.is_action_pressed("sword"):
  sword_selected = not sword_selected
  game.sound("switch",.7)
 if event.is_action_pressed("weapon1"):
  switch_weapon(0)
 if event.is_action_pressed("weapon2"):
  switch_weapon(1)
 if event is InputEventMouseButton and event.pressed:
  if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
   switch_weapon(1-weapon)

func switch_weapon(index: int) -> void:
 sword_selected = false
 if index == weapon:
  return
 reload_left = 0
 weapon = index
 for i in range(2):
  weapons[i].visible = i == weapon
 recoil = .10
 refresh_body()
 game.sound("switch",0.75)

func reload_weapon() -> void:
 if game.campaign.enabled:
  legacy_reload_weapon()
  return
 reload_left = 0
 return

func legacy_reload_weapon() -> void:
 if reload_left > 0 or ammo[weapon] == capacity[weapon]:
  return
 reload_left = 1.55 if weapon == 0 else 1.9
 game.sound("reload")

func _physics_process(dt: float) -> void:
 if not game.active:
  return
 roll_ready_in = maxf(0.0,roll_ready_in-dt)
 if game.vehicles.current!=null:
  if Input.is_action_just_pressed("interact"): game.interact()
  return
 if game.forts.step_player(dt): return
 if step_roll(dt) or step_slide(dt): return
 cooldown -= dt
 grenade_cooldown = maxf(0,grenade_cooldown-dt)
 hurt_cooldown = maxf(0,hurt_cooldown-dt)
 shield_delay = maxf(0,shield_delay-dt)
 if shield_delay == 0:
  shield = minf(max_shield(),shield+dt*10)
 if armor_broken and shield>0:
  armor_broken = false
  refresh_body()
 if reload_left > 0:
  cooldown = maxf(0,cooldown)
  reload_left = maxf(0,reload_left-dt)
  if reload_left == 0:
   ammo[weapon] = capacity[weapon]
   game.sound("switch",0.7)
 ads = not sword_selected and Input.is_action_pressed("aim") and reload_left == 0
 gun.visible = not third_person and not (ads and weapon_models[weapon] in [3,8])
 var axis = Input.get_vector("left","right","forward","back")
 var direction = transform.basis * Vector3(axis.x,0,axis.y)
 var speed = 7.4 if Input.is_action_pressed("sprint") and not ads else 5.0
 if ads:
  speed = 3.0
 if prone: speed = 1.5
 velocity.x = move_toward(velocity.x,direction.x*speed,dt*35)
 velocity.z = move_toward(velocity.z,direction.z*speed,dt*35)
 if not is_on_floor():
  velocity.y -= 20*dt
 elif Input.is_action_just_pressed("jump"):
  velocity.y = 7.2
 move_and_slide()
 update_view()
 walking = axis.length() > .1 and is_on_floor()
 if walking:
  bob += dt*speed*1.8
  feet_timer -= dt
  if feet_timer <= 0:
   game.sound("step",.35)
   feet_timer = .43 if speed < 7 else .31
 camera.fov = lerpf(camera.fov,(18.0 if weapon_models[weapon]==8 else (25.0 if weapon_models[weapon]==3 else 60.0)) if ads else 82.0,dt*12)
 recoil = move_toward(recoil,0,dt*.55) if game.campaign.enabled else 0.0
 var target = Vector3(.055,-.19,-.48) if ads else Vector3(.28,-.25,-.46)
 target.y += 0.0
 target.z += recoil*.45
 gun.position = gun.position.lerp(target,minf(1,dt*15))
 gun.rotation.x = recoil*.8 + (sin(reload_left*6)*.35 if reload_left > 0 else 0.0)
 gun.rotation.z = -.45 if reload_left > 0 else 0.0
 melee_ready = not sword_selected and not game.campaign.enabled and nearby_enemy()!=null
 knife.visible = melee_ready
 knife.rotation.z = sin(cooldown*18)*.55
 for i in range(2):
  weapons[i].visible = i==weapon and not melee_ready and not sword_selected
 for w in body_model.get_meta("guns"):
  w.visible = not sword_selected and not melee_ready and w==body_model.get_meta("guns")[weapon]
 body_model.get_meta("knife").visible = melee_ready
 if sword_selected and third_person:
  if not body_model.has_meta("sword"):
   var held = Gear.make_sword(body_model)
   held.position = Vector3(.45,1.04,-.26)
   body_model.set_meta("sword",held)
  body_model.get_meta("sword").show()
  body_model.get_meta("sword").rotation = sword.rotation
 elif body_model.has_meta("sword"):
  body_model.get_meta("sword").hide()
 sword.visible = sword_selected
 sword_swing = maxf(0.0,sword_swing-dt)
 sword.rotation = Vector3(-.33,.35-sin(sword_swing/.38*PI)*1.85,-.36)
 flash.visible = not sword_selected and not melee_ready and cooldown>0 and Input.is_action_pressed("fire")
 muzzle_light.light_energy = 1.5 if flash.visible else 0
 if sword_selected and Input.is_action_pressed("fire"):
  swing_sword()
 elif Input.is_action_pressed("fire"):
  for shot_index in range(2):
   if cooldown>0: break
   var count = mini(16,maxi(1,floori(-cooldown/game.arsenal.interval(weapon_models[weapon],weapon_tiers[weapon]))+1))
   var before_shots: int = game.shots
   shoot(count)
   if game.shots==before_shots: break
 else:
  cooldown = maxf(0,cooldown)
 if Input.is_action_just_pressed("interact"):
  game.interact()
 if position.y < -8:
  rescue()

func shoot(round_count: int = 1) -> void:
 if cooldown > 0:
  return
 var close_enemy = nearby_enemy()
 if close_enemy!=null and not game.campaign.enabled and weapon_models[weapon]!=11:
  cooldown = .35
  close_enemy.take_hit(160)
  game.sound("hit",.6)
  game.hit_marker = .15
  return
 if reload_left > 0:
  return
 if game.campaign.enabled:
  if ammo[weapon]<=0:
   legacy_reload_weapon()
   return
  round_count = mini(round_count,ammo[weapon])
  ammo[weapon] -= round_count
 else:
  ammo[weapon] = capacity[weapon]
 cooldown += game.arsenal.interval(weapon_models[weapon],weapon_tiers[weapon])*round_count
 recoil = 0
 if game.campaign.enabled and not game.low_motion: recoil = .09
 rounds_emitted += round_count
 game.shots += game.arsenal.speed_multiplier()*round_count
 if game.arsenal.trace_budget>0:
  game.sound("shock" if weapon_models[weapon]==11 else ("shotgun" if weapon_models[weapon]==1 else "ak"),.18 if game.career.silencer else .7)
 var origin = camera.global_position
 var forward = -camera.global_transform.basis.z
 var assist_target: Node3D = null
 var best_dot = .994 if game.assist else 1.0
 for enemy in game.enemies:
  if is_instance_valid(enemy) and enemy.hp > 0:
   var dir = (enemy.global_position+Vector3.UP*1.1-origin).normalized()
   var dot = forward.dot(dir)
   if dot > best_dot and game.clear_line(origin,enemy.global_position+Vector3.UP*1.1,enemy):
    best_dot = dot
    assist_target = enemy
 if assist_target:
  forward = (assist_target.global_position+Vector3.UP*1.1-origin).normalized()
 var hit_any = false
 var hit_metal := false
 for i in range(9 if weapon_models[weapon]==1 else 1):
  var spread = (.003 if ads else .012) if weapon_models[weapon] != 1 else (.045 if ads else .065)
  var dir = (forward+camera.global_basis.x*game.rng.randf_range(-spread,spread)+camera.global_basis.y*game.rng.randf_range(-spread,spread)).normalized()
  var reach = 13 if weapon_models[weapon]==11 else (220 if weapon_models[weapon]==8 else 85)
  var query = PhysicsRayQueryParameters3D.create(origin,origin+dir*reach,5)
  var hit = get_world_3d().direct_space_state.intersect_ray(query)
  var end = hit.position if not hit.is_empty() else origin+dir*reach
  if third_person:
   var obstruction = PhysicsRayQueryParameters3D.create(muzzle_position(),end,5)
   var blocked = get_world_3d().direct_space_state.intersect_ray(obstruction)
   if not blocked.is_empty():
    hit = blocked
  if not hit.is_empty():
   end = hit.position
   game.spark(end,Color("ffdc9b"),3)
   if hit.collider.has_method("take_hit"):
    var distance = origin.distance_to(end)
    var amount = Gear.damage(weapon_models[weapon],weapon_tiers[weapon],distance)*(1.25 if weapon_big[weapon] else 1.0)*game.arsenal.caliber_power()*game.arsenal.speed_multiplier()*round_count
    if weapon_models[weapon]==11:
     amount = Gear.damage(11,weapon_tiers[weapon],distance)
    if game.campaign.enabled:
     amount = (105.0 if weapon_models[weapon]==8 else 27.0)*round_count
    if hit.collider.has_method("receive_rounds"):
     hit.collider.receive_rounds(round_count*game.arsenal.speed_multiplier(),weapon_models[weapon] in [6,9] or weapon_tiers[weapon]==5)
    elif weapon_models[weapon] in [6,9] and hit.collider.has_method("take_laser"):
     hit.collider.take_laser(amount)
    else:
     hit.collider.take_hit(amount)
     if weapon_models[weapon]==11:
      hit.collider.shock_time = .65
    hit_any = true
   else:
    hit_metal = true
  game.arsenal.shot_trace(muzzle_position(),end,weapon_models[weapon] in [6,9])
 if hit_metal and not hit_any and game.arsenal.trace_budget>0: game.sound("metal",.23)
 if hit_any:
  game.hits += game.arsenal.speed_multiplier()*round_count
  game.hit_marker = .15
  if game.arsenal.trace_budget>0: game.sound("hit",.65)

func damage(amount: float, spill_shield: bool = false) -> void:
 if game.vehicles.current!=null:
  game.vehicles.current.take_hit(amount)
  return
 if hurt_cooldown > 0 or not game.active:
  return
 if shield>0:
  game.sound("shield",.53)
  var previous = shield
  var shield_damage = amount*(1.0-total_reduction())
  shield = maxf(0,shield-shield_damage)
  if spill_shield:
   hp = maxf(0.0,hp-maxf(0.0,shield_damage-previous))
  if previous>0 and shield==0:
   game.arsenal.shatter(global_position+Vector3.UP,armor_tier)
   armor_broken = true
   refresh_body()
 else:
  hp = maxf(0,hp-amount)
 shield_delay = 4.0
 hurt_cooldown = .45
 game.hurt_flash = .3
 game.sound("hurt",.6)
 if hp<=0:
  rescue()

func rescue() -> void:
 if roll_left>0: finish_roll()
 if game.campaign.enabled:
  sword_selected = false
  game.campaign.fail()
  return
 var lost_gear := false
 if hp<=0 and not game.test_mode:
  lost_gear = game.career.lose_carried_gear()
  if lost_gear:
   game.apply_career()
 if game.outer_port.outside: game.outer_port.leave()
 hp = max_hp
 shield = max_shield()
 position = game.extraction_position+Vector3.UP*.2
 velocity = Vector3.ZERO
 hurt_cooldown = 4
 game.rescues += 1
 game.message("携带装备已掉落 · 永久剑保留" if lost_gear else "护盾已修复 · 已返回出发点，能源保留",4)

func max_shield() -> float:
 if game.campaign.enabled: return 140.0 if game.campaign.reward=="armor" else 100.0
 if armor_tier==5 and overcharged:
  return 9999.0
 if game.career.armor_route_equipped: return float(game.career.ARMOR_ROUTE_HP[game.career.armor_route_level])+helmet_defense
 return Gear.SHIELD[armor_tier]*(1.2 if armor_big and armor_tier!=5 else 1.0)+helmet_defense

func equip_armor(tier: int) -> void:
 armor_tier = clampi(tier,0,5)
 overcharged = false
 armor_broken = false
 shield = max_shield()
 Gear.color_material(armor_material,armor_tier)
 refresh_body()

func upgrade_weapon(tier: int) -> void:
 weapon_tiers[weapon] = maxi(weapon_tiers[weapon],clampi(tier,0,5))
 Gear.paint_weapon(weapons[weapon],weapon_tiers[weapon])
 ammo[weapon] = capacity[weapon]
 refresh_body()

func build_pants() -> void:
 pants = Node3D.new()
 add_child(pants)
 var material = ShaderMaterial.new()
 material.shader = load("res://scripts/pants.gdshader")
 pants_green = material
 pants_plain = F.mat(Color("485567"))
 var boots = F.mat(Color("142b26"))
 for side in [-1,1]:
  F.box(pants,Vector3(side*.18,.62,-.02),Vector3(.24,.44,.27),material).set_meta("trousers",true)
  F.box(pants,Vector3(side*.18,.27,-.04),Vector3(.21,.36,.23),material).set_meta("trousers",true)
  F.box(pants,Vector3(side*.18,.07,-.13),Vector3(.25,.13,.39),boots)

func use_skill(index: int) -> bool:
 if game.campaign.enabled: return false
 if not game.active or index<0 or index>2 or not game.career.skills[index]:
  if game.active:
   game.message("技能尚未解锁 · 按 B 打开背包的技能页",2)
  return false
 if index==0:
  var direction = -global_basis.z
  direction.y = 0
  move_and_collide(direction.normalized()*7)
  game.spark(global_position+Vector3.UP,Color("6fffe1"),5)
 elif index==1:
  shield = max_shield()
  shield_delay = 0
  game.spark(global_position+Vector3.UP,Color("64eaa1"),6)
 else:
  for enemy in game.enemies:
   if is_instance_valid(enemy) and enemy.hp>0 and enemy.position.distance_to(position)<8 and game.clear_line(camera.global_position,enemy.position+Vector3.UP,enemy):
    enemy.take_hit(65)
  var ring = F.sphere(game,global_position+Vector3.UP,.7,F.mat(Color("64ead5"),1))
  game.effects.append({"node":ring,"life":.12})
 game.sound("pickup",.3)
 return true

func set_pants_style(green: bool) -> void:
 for part in pants.get_children():
  if part.has_meta("trousers"):
   part.material_override = pants_green if green else pants_plain
 update_pants_equipment()

func refresh_body() -> void:
 if not is_instance_valid(body_model):
  return
 if broken_surface==null: broken_surface = F.mat(Color("394854"))
 var material: Material = broken_surface if armor_broken else (rainbow_material if armor_tier==5 else armor_material)
 if not game.campaign.enabled and game.career.armor_route_equipped and not armor_broken:
  armor_material.albedo_color = game.career.ARMOR_ROUTE_COLORS[game.career.armor_route_level]
  material = armor_material
 for part in body_model.get_meta("armor_parts"):
  part.material_override = material
 for i in range(2):
  var model_gun = body_model.get_meta("guns")[i]
  model_gun.visible = i==weapon
  model_gun.scale = model_gun.get_meta("base_scale")*.85*(1.1 if weapon_big[i] else 1.0)
  weapons[i].scale = weapons[i].get_meta("base_scale")*(1.1 if weapon_big[i] else 1.0)
  Gear.paint_weapon(model_gun,weapon_tiers[i])
 body_model.get_meta("coat").visible = game.career.operator_coat
 for w in weapons:
  for part in w.get_children():
   if part.has_meta("armor"):
    part.material_override = material

func set_view(enabled: bool, persist: bool = true) -> bool:
 if persist and not game.career.set_view(enabled):
  return false
 third_person = enabled
 gun.visible = not third_person
 update_view()
 return true

func update_view() -> void:
 var eye_height = .70 if prone else 1.58
 if not third_person or ads and weapon_models[weapon] in [3,8]:
  camera.position = Vector3(0,eye_height,0)
  if is_instance_valid(body_model):
   body_model.visible = false
  return
 var eye = global_transform*Vector3(0,eye_height,0)
 var offset = camera.basis.z*3.6+camera.basis.x*.55+Vector3.UP*.18
 var motion = global_basis*offset
 var query = PhysicsShapeQueryParameters3D.new()
 var shape = SphereShape3D.new()
 shape.radius = .20
 query.shape = shape
 query.transform = Transform3D(Basis.IDENTITY,eye)
 query.motion = motion
 query.collision_mask = 1
 var fractions = get_world_3d().direct_space_state.cast_motion(query)
 var fraction = fractions[0] if fractions.size()>0 else 1.0
 camera.position = Vector3(0,eye_height,0)+offset*maxf(0,fraction-.015)
 body_model.visible = camera.position.distance_to(Vector3(0,eye_height,0))>.65
 for w in body_model.get_meta("guns"):
  w.rotation.x = camera.rotation.x+(PI/2 if prone else 0)

func muzzle_position() -> Vector3:
 if ads and weapon_models[weapon] in [3,8]:
  return camera.global_position-camera.global_basis.z*.3
 if third_person and prone:
  return global_position+Vector3.UP*.65-global_basis.z*.9
 if third_person:
  return body_model.get_meta("guns")[weapon].to_global(Vector3(0,0,-.7))
 return flash.global_position

func coat_heal() -> bool:
 if game.campaign.enabled: return false
 if not game.active or not game.career.operator_coat:
  return false
 hp = max_hp
 shield = max_shield()
 shield_delay = 0
 game.spark(global_position+Vector3.UP,Color("6affb3"),5)
 game.sound("pickup",.25)
 return true

func total_reduction() -> float:
 if game.campaign.enabled: return 0.0
 var pants_bonus = 0.0
 if game.difficulty==4:
  pants_bonus = .10
 elif game.career.pants_style>0:
  pants_bonus = game.career.equipped.pants*.02
 return minf(.65,Gear.REDUCTION[armor_tier]+pants_bonus+(.03 if armor_big else 0.0))

func activate_overcharge() -> bool:
 if game.campaign.enabled: return false
 if not game.active:
  return false
 max_hp = 999+helmet_health
 hp = max_hp
 if armor_tier==5:
  overcharged = true
  shield = 9999.0
 game.message("队长 Q 强化 · 生命 999"+(" / 彩虹护盾 9999" if armor_tier==5 else ""),3)
 return true

func throw_player_grenade() -> bool:
 if not game.active or grenade_cooldown>0 or game.grenades.size()>=64:
  return false
 if game.campaign.enabled:
  if game.campaign.grenades<=0: return false
  game.campaign.grenades -= 1
 grenade_cooldown = .8 if game.campaign.enabled else .25
 var origin = global_position+Vector3.UP*1.4-global_basis.z*.5
 var target = global_position-global_basis.z*12
 var q = PhysicsRayQueryParameters3D.create(camera.global_position,camera.global_position-camera.global_basis.z*18,1)
 var hit = get_world_3d().direct_space_state.intersect_ray(q)
 if not hit.is_empty():
  target = hit.position
 game.throw_grenade(origin,target,true)
 return true

func update_pants_equipment() -> void:
 if not is_instance_valid(pants):
  return
 var material: Material = pants_green if game.career.green_pants else pants_plain
 if game.career.pants_style>0 or game.difficulty==4:
  material = Gear.armor_surface(5 if game.difficulty==4 else game.career.equipped.pants)
 for part in pants.get_children():
  if part.has_meta("trousers"):
   part.material_override = material
   part.visible = true
   if game.career.pants_style==2 and game.difficulty!=4:
    if part.position.y<.4:
     part.material_override = F.mat(Color("a48368"))
    else:
     part.scale.y = .55
   else:
    part.scale.y = 1.0

func set_weapon_models(values: Array) -> void:
 if weapon_models==values and body_model.get_meta("helmet_index",0)==active_helmet():
  return
 weapon_models = values.duplicate()
 for i in range(2):
  var old = weapons[i]
  gun.remove_child(old)
  old.queue_free()
  var w = Gear.make_weapon(gun,weapon_models[i],weapon_tiers[i])
  weapons[i] = w
  var glove = F.mat(Color("111c29"))
  F.box(w,Vector3(.04,-.17,.18),Vector3(.13,.15,.17),glove)
  F.box(w,Vector3(.09,-.24,.32),Vector3(.17,.15,.32),armor_material).set_meta("armor",true)
  F.box(w,Vector3(-.05,-.10,-.20),Vector3(.14,.12,.16),glove)
  F.box(w,Vector3(-.10,-.20,-.03),Vector3(.16,.16,.30),armor_material).set_meta("armor",true)
  w.visible = i==weapon
  capacity[i] = Gear.CAPACITY[weapon_models[i]]
  ammo[i] = capacity[i]
 var old_body = body_model
 remove_child(old_body)
 old_body.queue_free()
 body_model = Operative.make_body(self,armor_material,pants_green,weapon,weapon_tiers,game.career.operator_coat,false,weapon_models,false,active_helmet())
 body_model.set_meta("helmet_index",active_helmet())
 refresh_body()
 set_prone(prone)

func nearby_enemy() -> Node3D:
 var best: Node3D = null
 var distance := 2.4
 for enemy in game.enemies:
  if is_instance_valid(enemy) and enemy.hp>0:
   var d = global_position.distance_to(enemy.global_position)
   if d<distance and game.clear_line(global_position+Vector3.UP,enemy.global_position+Vector3.UP,enemy):
    distance = d
    best = enemy
 return best

func set_prone(enabled: bool) -> void:
 prone = enabled
 capsule_shape.height = .8 if prone else 1.8
 body_collision.position.y = .4 if prone else .9
 body_model.rotation.x = -PI/2 if prone else 0
 body_model.position.y = .25 if prone else 0
 pants.rotation.x = -PI/2 if prone else 0
 pants.position.y = .25 if prone else 0
 body_model.get_meta("armor_parts")[1].rotation.x = PI/2 if prone else 0
 var face = body_model.get_meta("face")
 face.rotation.x = PI/2 if prone else 0
 face.position = Vector3(0,1.96,0) if prone else Vector3(0,1.74,-.23)
 for w in body_model.get_meta("guns"):
  w.position.z = .16 if prone else -.28
 update_view()

func start_slide() -> bool:
 if slide_left>0 or not is_on_floor() or game.vehicles.current!=null or game.forts.climbs.has(get_instance_id()): return false
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


func start_roll() -> bool:
 if not game.active or roll_ready_in>0 or not is_on_floor() or prone or slide_left>0:
  return false
 if game.vehicles.current!=null or game.forts.climbs.has(get_instance_id()):
  return false
 var axis = Input.get_vector("left","right","forward","back")
 if axis.length_squared()<.01:
  axis = Vector2(0,-1)
 roll_direction = (global_basis*Vector3(axis.x,0,axis.y)).normalized()
 roll_bank = signf(axis.x) if absf(axis.x)>.1 else 1.0
 roll_left = ROLL_DURATION
 roll_ready_in = ROLL_COOLDOWN
 ads = false
 flash.hide()
 muzzle_light.light_energy = 0.0
 gun.hide()
 body_collision.position.y = .47
 capsule_shape.height = .94
 game.sound("step",.75)
 return true

func step_roll(dt: float) -> bool:
 if roll_left<=0:
  return false
 var progress = 1.0-roll_left/ROLL_DURATION
 var travel_speed = lerpf(12.0,6.0,progress)
 velocity.x = roll_direction.x*travel_speed
 velocity.z = roll_direction.z*travel_speed
 velocity.y = -3.0 if is_on_floor() else velocity.y-20.0*dt
 move_and_slide()
 roll_left = maxf(0.0,roll_left-dt)
 if roll_left<=.0001:
  finish_roll()
  return true
 if position.y < -8:
  rescue()
  return true
 else:
  update_view()
  if third_person:
   body_model.rotation.x = -TAU*progress
   pants.rotation.x = body_model.rotation.x
  elif not game.low_motion:
   camera.position.y -= .48*sin(progress*PI)
   camera.rotation.z = .13*roll_bank*sin(progress*PI)
 return true

func finish_roll() -> void:
 roll_left = 0.0
 body_model.rotation.x = 0.0
 pants.rotation.x = 0.0
 camera.rotation.z = 0.0
 set_prone(false)
 update_view()

func swing_sword() -> void:
 if cooldown>0:
  return
 cooldown = .38
 sword_swing = .38
 game.sound("switch",.62)
 var from := global_position+Vector3.UP*1.15
 var forward := -global_basis.z
 for enemy in game.enemies:
  if not is_instance_valid(enemy) or enemy.hp<=0:
   continue
  var center: Vector3 = enemy.global_position+Vector3.UP
  var delta := center-from
  if delta.length()>2.65 or forward.dot(delta.normalized())<.45:
   continue
  if game.clear_line(from,center,enemy):
   enemy.take_hit(105.0)
   game.sound("metal",.52)
   game.hit_marker = .15
   break

func active_helmet() -> int:
 return 0 if game.campaign.enabled else game.career.helmet

func sync_helmet_stats() -> void:
 var index := active_helmet()
 var next_health: float = game.career.HELMET_HEALTH[index]
 var next_defense: float = game.career.HELMET_DEFENSE[index]
 var change := next_health-helmet_health
 max_hp += change
 hp = clampf(hp+change,0,max_hp)
 var extra := next_defense-helmet_defense
 helmet_health = next_health
 helmet_defense = next_defense
 shield = clampf(shield+extra,0,max_shield())
