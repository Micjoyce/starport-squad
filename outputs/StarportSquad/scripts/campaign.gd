extends RefCounted

const Drone = preload("res://scripts/drone.gd")
const Art = preload("res://scripts/port_art.gd")
const F = preload("res://scripts/factory.gd")
var save_path := "user://campaign.cfg"
const TITLES = ["与小队会合", "守住登陆区", "突破星港外环", "夺取中继核心"]
const START = Vector3(2.3,.15,25)
const RALLY = Vector3(0,0,18)
const NORTH = Vector3(0,.2,-13.2)
const OUTER = Vector3(8,.15,3)
var game: Node3D
var enabled := false
var isolated := false
var checkpoint := 0
var completed := false
var reward := ""
var phase := 0
var lesson := 0
var capture := 0.0
var grenades := 3
var foes: Array[Node3D] = []
var reserves: Array[Vector3] = []
var enemy_serial := 0
const ACTIVE_ENEMIES := 5
var transport: Node3D
var rally_beacon: Node3D
var breach_beacon: Node3D
var radio := ""
var radio_time := 0.0
var notice := ""

func load_progress() -> void:
 if isolated:
  return
 var file = ConfigFile.new()
 if file.load(save_path)==OK:
  checkpoint = clampi(int(file.get_value("mission","checkpoint",0)),0,3)
  completed = bool(file.get_value("mission","completed",false))
  reward = str(file.get_value("mission","reward",""))

func persist() -> bool:
 if isolated:
  return true
 var file = ConfigFile.new()
 file.set_value("mission","checkpoint",checkpoint)
 file.set_value("mission","completed",completed)
 file.set_value("mission","reward",reward)
 if file.save(save_path+".tmp")!=OK:
  return false
 return DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path+".tmp"),ProjectSettings.globalize_path(save_path))==OK

func begin() -> void:
 if enabled or game.mode!="menu":
  return
 enabled = true
 phase = 0 if completed else checkpoint
 if game.get_tree().has_meta("campaign_retry_phase"):
  phase = int(game.get_tree().get_meta("campaign_retry_phase"))
  game.get_tree().remove_meta("campaign_retry_phase")
  game.pulse_charge.spent = bool(game.get_tree().get_meta("campaign_pulse_spent",false))
  game.get_tree().remove_meta("campaign_pulse_spent")
 if game.test_mode: game.difficulty = 0
 game.command.siege_enabled = false
 game.companions.enabled = false
 game.regiments.enabled = false
 for unit in game.enemies+game.allies:
  if is_instance_valid(unit):
   unit.queue_free()
 game.enemies.clear()
 game.allies.clear()
 for v in game.vehicles.fleet:
  if is_instance_valid(v):
   v.queue_free()
 game.vehicles.fleet.clear()
 for item in game.equipment+game.pickups:
  item.taken = true
  item.node.hide()
 game.expedition.portal.hide()
 Art.campaign_palette(game)
 game.player.set_view(false,false)
 game.player.armor_big = false
 game.player.equip_armor(0)
 game.player.weapon_tiers = [0,0]
 game.player.weapon_big = [false,false]
 game.player.set_weapon_models([0,8])
 game.player.switch_weapon(0)
 game.player.capacity = [30,8]
 game.player.ammo = game.player.capacity.duplicate()
 game.player.sync_helmet_stats()
 game.player.max_hp = 100
 game.player.hp = 100
 game.player.armor_material.albedo_color = Color("405562")
 for i in range(game.player.weapons.size()):
  var weapon: Node3D = game.player.weapons[i]
  Art.finish_weapon(weapon,i==1)
  var finish: StandardMaterial3D = weapon.get_meta("paint")
  finish.albedo_color = Color("344656")
  finish.metallic = .48
  finish.roughness = .53
 game.player.position = [START,RALLY+Vector3.UP*.15,OUTER,NORTH][phase]
 game.player.rotation = Vector3.ZERO
 game.player.camera.rotation = Vector3.ZERO
 if phase<3: game.player.rotation.y = .25
 game.player.shield = game.player.max_shield()
 game.command.order = "attack" if phase>=2 else "defend"
 for i in range(4 if reward=="squad" else 3):
  add_ally(i)
 transport = game.vehicles.spawn(Vector3(11,.3,6) if phase==2 else Vector3(8,.3,24),0,true,true)
 rally_beacon = beacon(RALLY,Color("70ddcf"))
 breach_beacon = beacon(Vector3(9,0,-13.3),Color("ffc27e"))
 set_phase(phase,false)
 game.start_game()

func add_ally(index: int) -> void:
 var ally = CharacterBody3D.new()
 ally.set_script(Drone)
 ally.game = game
 ally.friendly = true
 ally.slot = index
 ally.weapon_kind = 2
 ally.hp = 125.0
 game.add_child(ally)
 ally.position = (Vector3(0,.1,17) if phase<3 else game.player.position+Vector3(0,0,2)) + Vector3((index-1)*1.45,0,0)
 ally.home = ally.position
 game.allies.append(ally)

func beacon(at: Vector3, tint: Color) -> Node3D:
 var node = Node3D.new()
 game.world.add_child(node)
 node.position = at
 var material = F.mat(tint,.6)
 for i in range(4):
  var edge = F.box(node,Vector3.ZERO,Vector3(.7,.025,.06),material)
  edge.position = Vector3(cos(i*PI/2),.037,sin(i*PI/2))*1.6
  edge.rotation.y = -i*PI/2+PI/2
 return node

func say_line(line: String) -> void:
 radio = line
 radio_time = 7.0
 game.sound("switch",.48)

func set_phase(next: int, save: bool = true) -> void:
 phase = next
 reserves.clear()
 if save and not completed:
  checkpoint = next
  if not persist():
   notice = "检查点暂未写入"
 rally_beacon.visible = phase<=1
 breach_beacon.visible = phase==2
 match phase:
  0: say_line("领队，前面是集结点。小队正在等你。")
  1:
   spawn_group([Vector3(-3,.12,8),Vector3(2,.12,7),Vector3(8,.12,3),Vector3(-10,.12,2)])
   reserves.assign([Vector3(-7,.12,8),Vector3(9,.12,6),Vector3(-10,.12,4),Vector3(8,.12,2)])
   say_line("巡逻机正向登陆区靠近。左键射击，守住这里。")
  2:
   spawn_group([Vector3(-9,.12,-6),Vector3(9,.12,-9),Vector3(7,.12,-12)])
   reserves.assign([Vector3(-10,.12,-13),Vector3(10,.12,-6),Vector3(-8,.12,-10),Vector3(8,.12,-7)])
   say_line("按 2 换大狙上塔掩护，或按 E 驾车走右路。")
  3:
   for unit in foes:
    if is_instance_valid(unit):
     unit.queue_free()
   foes.clear()
   spawn_group([Vector3(-2,.12,-17),Vector3(2,.12,-18),Vector3(2,.12,-21)])
   reserves.assign([Vector3(-2,.12,-21),Vector3(1,.12,-22),Vector3(-2,.12,-19),Vector3(2,.12,-20)])
   say_line("看到中继站了。清掉核心守卫，步行进入发光区域。")

func spawn_group(points: Array) -> void:
 for point in points:
  var helmet: int = [1,0,2,1,3][enemy_serial%5]
  enemy_serial += 1
  var unit = game.spawn_enemy(point,false,false,helmet)
  unit.hp = 75.0+game.difficulty*22.0+game.career.HELMET_HEALTH[helmet]
  unit.max_hp = unit.hp
  unit.armor = 35.0+game.difficulty*20.0
  unit.q_used = true
  foes.append(unit)

func remaining() -> int:
 return deployed_count()+reserves.size()

func deployed_count() -> int:
 var count = 0
 for enemy in foes:
  if is_instance_valid(enemy) and enemy.hp>0:
   count += 1
 return count

func receive_order(order: String) -> void:
 if phase==0 and lesson>=2 and order=="defend":
  set_phase(1)

func tick(dt: float) -> void:
 radio_time = maxf(0,radio_time-dt)
 if not reserves.is_empty() and deployed_count()<=2:
  var count := mini(reserves.size(),ACTIVE_ENEMIES-deployed_count())
  for i in range(count):
   spawn_group([reserves.pop_front()])
  say_line("还有一支机器人小队正在靠近。")
 var p = game.player
 if game.command.alive_count()==0 and game.command.pending_recruits==0:
  fail("小队已失去作战能力。")
  return
 match phase:
  0:
   if lesson==0 and p.position.distance_to(RALLY)<2.4:
    lesson = 1
    say_line("已就位。按住右键瞄准前方通道。")
   if lesson==1 and p.ads:
    lesson = 2
    say_line("很好。按 J 命令小队守住这里。")
  1:
   if remaining()==0:
    game.command.set_order("attack")
    p.ammo = p.capacity.duplicate()
    p.shield = p.max_shield()
    set_phase(2)
  2:
   var approach: Vector3 = p.position if game.vehicles.current==null else game.vehicles.current.position
   if remaining()==0 and approach.z < -12 and approach.y<2.0:
    p.ammo = p.capacity.duplicate()
    set_phase(3)
  3:
   var inside: bool = game.vehicles.current==null and game.command.near_core(p.position,game.command.enemy_core.global_position,3.2)
   if inside and remaining()==0:
    capture = minf(8,capture+dt)
   else:
    capture = maxf(0,capture-dt)
   if capture>=8:
    finish()

func finish() -> void:
 if not completed:
  completed = true
  if not persist():
   completed = false
   notice = "存档写入失败，可以从检查点重试"
 game.active = false
 game.mode = "campaign_result"
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 game.sound("win")
 game.hud.show_page("campaign_result")

func choose_reward(choice: String) -> void:
 if not completed or reward!="":
  return
 reward = choice
 if not persist():
  reward = ""
  notice = "奖励写入失败，请重试"
 game.hud.show_page("campaign_result")

func fail(reason: String = "护盾和生命已耗尽。") -> void:
 notice = reason
 game.active = false
 game.mode = "campaign_failed"
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 game.hud.show_page("campaign_failed")

func objective() -> String:
 match phase:
  0: return ["WASD  前往集结点","右键  瞄准前方通道","J  下令驻守登陆区"][lesson]
  1: return "停机巡逻机  ·  剩余 %d" % remaining()
  2: return "清理外环  ·  剩余 %d" % remaining() if remaining()>0 else "越过外环通道"
  3: return "清理中继站  ·  剩余 %d" % remaining() if remaining()>0 else "步行进入核心区  ·  同步 %d%%" % int(capture*12.5)
 return ""
