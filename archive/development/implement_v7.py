from pathlib import Path
s=Path('outputs/StarportSquad/scripts')
p=s/'command.gd';t=p.read_text().replace('var battle_started := false','const CAPTURE_SECONDS = 8.0\nconst DEFEND_SECONDS = 20.0\nvar order := "attack"\nvar enemy_castle: Node3D\nvar enemy_walls: Array[MeshInstance3D] = []\nvar enemy_core: Node3D\nvar home_core: Node3D\nvar capture := 0.0\nvar enemy_capture := 0.0\nvar captured := false\nvar contested := false\nvar battle_started := false').replace(' refresh_castle()\n\nfunc refresh_castle',' refresh_castle()\n build_enemy_castle()\n\nfunc refresh_castle',1)
start=t.index(' for i in range(10):\n  var point = game.expedition.random_point',t.index('func enemy_wave'))
end=t.index('\n return 10',start)
t=t[:start]+''' if captured or capture>0 or near_core(game.player.position,enemy_castle.global_position,8):
  return 0
 for i in range(10):
  game.spawn_enemy(enemy_spawn(i)+Vector3.UP*.15)'''+t[end:]
start=t.index('func tick() -> void:');t=t[:start]+'''func tick(dt: float = 1.0/60.0) -> void:
 if not game.active or game.mode!="playing" or captured:
  return
 var attackers = 1 if near_core(game.player.position,enemy_castle.global_position,3.2) else 0
 var defenders = 1 if near_core(game.player.position,castle.global_position,4) else 0
 var enemy_home = 0
 var enemy_away = 0
 for unit in game.allies:
  if is_instance_valid(unit) and unit.hp>0:
   if near_core(unit.position,enemy_castle.global_position,3.2):
    attackers += 1
   if near_core(unit.position,castle.global_position,6):
    defenders += 1
 for unit in game.enemies:
  if is_instance_valid(unit) and unit.hp>0:
   if near_core(unit.position,enemy_castle.global_position,6):
    enemy_home += 1
   if near_core(unit.position,castle.global_position,3.2):
    enemy_away += 1
 contested = attackers>0 and (enemy_home>0 or (game.difficulty==3 and game.expedition.boss_alive()))
 if attackers>0 and not contested:
  capture = minf(CAPTURE_SECONDS,capture+dt)
 elif attackers==0:
  capture = maxf(0,capture-dt*2)
 if enemy_away>0 and defenders==0:
  enemy_capture = minf(DEFEND_SECONDS,enemy_capture+dt)
 elif enemy_away==0:
  enemy_capture = maxf(0,enemy_capture-dt*2)
 enemy_core.rotation.y += dt*.7
 home_core.rotation.y -= dt*.7
 if capture>=CAPTURE_SECONDS:
  game.win()
  if game.mode=="win":
   captured = true
   battle_started = false
   game.message("敌方城堡已占领 · 获得 1,000,000 金币",6)
 elif enemy_capture>=DEFEND_SECONDS:
  game.active = false
  game.mode = "defeat"
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
  game.hud.show_page("defeat")

func build_enemy_castle() -> void:
 capture = 0
 enemy_capture = 0
 captured = false
 contested = false
 enemy_castle = Node3D.new()
 game.world.add_child(enemy_castle)
 enemy_castle.position = Vector3(0,0,-19)
 enemy_walls.clear()
 var metal = F.mat(Color("713c4c"))
 var light = F.mat(Color("ff6a52"),1.3)
 for side in [-1,1]:
  enemy_walls.append(F.box(enemy_castle,Vector3(side*5,1.8,0),Vector3(.6,3.6,8),metal,true))
  game.blockers.append(Rect2(Vector2(side*5-.7,-23.5),Vector2(1.4,9)))
  for end in [-1,1]:
   enemy_walls.append(F.box(enemy_castle,Vector3(side*3.7,1.8,end*4),Vector3(2.6,3.6,.6),metal,true))
   game.blockers.append(Rect2(Vector2(side*3.7-1.7,-19+end*4-.7),Vector2(3.4,1.4)))
 for x in [-5,5]:
  for z in [-4,4]:
   enemy_walls.append(F.box(enemy_castle,Vector3(x,2.2,z),Vector3(1.2,4.4,1.2),metal,true))
   F.box(enemy_castle,Vector3(x,4.5,z),Vector3(1.5,.18,1.5),light)
 var title = F.text3d(enemy_castle,"敌方城堡 / 占领核心 8 秒",Vector3(0,5,-4),38,Color("ff9875"))
 title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 enemy_core = make_core(enemy_castle,Color("ff745b"))
 home_core = make_core(castle,Color("63ffe1"))

func make_core(parent: Node3D, color: Color) -> Node3D:
 var core = Node3D.new()
 parent.add_child(core)
 var glow = F.mat(color,.8)
 F.cylinder(core,Vector3(0,.035,0),3.2,.04,glow,32)
 for side in [-1,1]:
  F.box(core,Vector3(side*.28,1.2,0),Vector3(.06,1.4,.06),glow)
 var gem = F.box(core,Vector3(0,1.7,0),Vector3(.42,.42,.42),glow)
 gem.rotation.z = PI/4
 return core

func near_core(point: Vector3, center: Vector3, radius: float) -> bool:
 return absf(point.y-center.y)<2.2 and Vector2(point.x-center.x,point.z-center.z).length()<radius*game.expedition.scale_factor

func set_order(value: String) -> bool:
 if value not in ["defend","attack"]:
  return false
 order = value
 for unit in game.allies:
  if is_instance_valid(unit):
   unit.path_timer = 0
   unit.windup = -1
 game.message("全队驻守我方城堡" if order=="defend" else "全队跟随头领，进攻敌方城堡",4)
 return true

func anchor(unit: Node3D) -> Vector3:
 if unit.friendly:
  return castle.global_position if order=="defend" else game.player.position
 return castle.global_position if unit.slot%2==1 and not unit.is_boss and game.elapsed>8 else enemy_castle.global_position

func rally_point(unit: Node3D) -> Vector3:
 var point: Vector3
 if unit.friendly and order=="attack":
  point = game.player.position+unit.formation_offset()
 else:
  var angle = float(unit.slot%10)/10*TAU
  point = anchor(unit)+Vector3(sin(angle)*2.2,0,cos(angle)*2.2)*game.expedition.scale_factor
 var cell = Vector2i(roundi(point.x/game.expedition.scale_factor),roundi(point.z/game.expedition.scale_factor))
 return anchor(unit) if not game.navigation.is_in_boundsv(cell) or game.navigation.is_point_solid(cell) else point

func enemy_spawn(index: int) -> Vector3:
 for attempt in range(160):
  var point = Vector3(game.rng.randi_range(-3,3),.05,-19+game.rng.randi_range(-3,3))*game.expedition.scale_factor
  var valid = true
  for unit in game.enemies:
   if is_instance_valid(unit) and unit.hp>0 and point.distance_to(unit.position)<1.2:
    valid = false
  if valid:
   return point
 return Vector3((index%5-2)*2.0,.05,-26-float(index/5))*game.expedition.scale_factor
''';p.write_text(t)
p=s/'game.gd';t=p.read_text().replace('command.tick()','command.tick(dt)',1).replace('"command":KEY_K,','"guard":KEY_J,"assault":KEY_L,"command":KEY_K,').replace(' if event.is_action_pressed("command"):', ' if active and event.is_action_pressed("guard"):\n  command.set_order("defend")\n  return\n if active and event.is_action_pressed("assault"):\n  command.set_order("attack")\n  return\n if event.is_action_pressed("command"):').replace(' var pos = expedition.random_point(1)\n  for attempt',' var pos = command.enemy_spawn(i) if i%2==0 else expedition.random_point(1)\n  for attempt',1).replace('spawn_enemy(Vector3(0,.1,-24)*expedition.scale_factor,true)','spawn_enemy(Vector3(0,.1,-19)*expedition.scale_factor,true)').replace(' bot.is_boss = boss',' bot.slot = enemies.size()\n bot.is_boss = boss').replace('任务开始 · 按 E 收集能源，跟随 A / B / C 标记','目标：占领敌方城堡核心 8 秒 · J 守城 / L 跟随进攻 / K 招兵');p.write_text(t)
p=s/'drone.gd';t=p.read_text();start=t.index(' var following = friendly and');end=t.index(' var distance =',start);t=t[:start]+''' var anchor = game.command.anchor(self)
 var leash = 10.0 if friendly and game.command.order=="defend" else (14.0 if friendly else 16.0)
 var following = target_unit==null or position.distance_to(anchor)>leash
 if following:
  target_unit = null
  target = game.command.rally_point(self)
'''+t[end:];t=t.replace(' var destination = target if friendly or distance < 28 else home+Vector3(sin(phase*.12)*3,0,cos(phase*.12)*3)',' var destination = target').replace(' var closest: Node3D = null if friendly else game.player\n var limit = 22.0 if friendly else position.distance_to(game.player.position)',' var closest: Node3D = null\n var anchor = game.command.anchor(self)\n var leash = 12.0 if friendly and game.command.order=="defend" else (22.0 if friendly else 16.0)\n var limit = leash\n if not friendly and game.player.position.distance_to(anchor)<leash and position.distance_to(game.player.position)<limit:\n  closest = game.player\n  limit = position.distance_to(game.player.position)').replace('   if distance<limit and game.clear_line','   if unit.position.distance_to(anchor)<leash and distance<limit and game.clear_line');p.write_text(t)
