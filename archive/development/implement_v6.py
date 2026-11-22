from pathlib import Path
s=Path('outputs/StarportSquad/scripts')
p=s/'gear.gd'; t=p.read_text().replace('return BASE_INTERVAL[clampi(weapon,0,7)]*RATE[clampi(tier,0,5)]','return BASE_INTERVAL[clampi(weapon,0,7)]*RATE[clampi(tier,0,5)]*.70'); p.write_text(t)
p=s/'career.gd'; t=p.read_text().replace('var credits := 0','var castle_level := 0\nvar credits := 0').replace('"version":3,','"version":4,"castle_level":castle_level,').replace(' credits = clampi(int(data.get("credits",0)),0,2000000000)',' castle_level = clampi(int(data.get("castle_level",0)),0,11)\n credits = clampi(int(data.get("credits",0)),0,2000000000)');t+='''
func castle_cost() -> int:
 return 0 if castle_level>=11 else (castle_level+1)*1000

func upgrade_castle() -> bool:
 if castle_level>=11 or credits<castle_cost():
  return false
 var before = snapshot()
 credits -= castle_cost()
 castle_level += 1
 return commit(before)
''';p.write_text(t)
p=s/'game.gd';t=p.read_text().replace('var expedition: RefCounted','const Command = preload("res://scripts/command.gd")\nconst CommandChecks = preload("res://scripts/command_checks.gd")\nvar command: RefCounted\nvar allies: Array = []\nvar expedition: RefCounted').replace(' setup_inputs()',' command = Command.new()\n command.game = self\n setup_inputs()',1).replace('"forward":KEY_W,','"command":KEY_K,"forward":KEY_W,').replace(' build_navigation()\n batch_static_geometry()',' command.build_castle()\n build_navigation()\n batch_static_geometry()').replace(' if event.is_action_pressed("interact") and hud.page=="chest":',' if event.is_action_pressed("command"):\n  command.toggle_page()\n  return\n if event.is_action_pressed("interact") and hud.page=="chest":').replace('hud.page in ["inventory","chest"]','hud.page in ["inventory","chest","command"]').replace('career.record_win(100*(difficulty+1))','career.record_win(1000000)').replace('  career.record_win(1000000)\n  victory_paid = true','  if not career.record_win(1000000):\n   message("奖励存档失败，请再次撤离领取",4)\n   return\n  victory_paid = true').replace(' await ExpeditionChecks.run(self,failures)',' await ExpeditionChecks.run(self,failures)\n await CommandChecks.run(self,failures)');p.write_text(t)
p=s/'player.gd';t=p.read_text().replace('var overcharged := false','var knife: Node3D\nvar melee_ready := false\nvar overcharged := false').replace(' build_weapons()',' build_weapons()\n knife = Gear.make_knife(gun)\n knife.position = Vector3(0,-.03,-.15)\n knife.visible = false',1).replace(' flash.visible = cooldown >',' melee_ready = nearby_enemy()!=null\n knife.visible = melee_ready\n knife.rotation.z = sin(cooldown*18)*.55\n for i in range(2):\n  weapons[i].visible = i==weapon and not melee_ready\n for w in body_model.get_meta("guns"):\n  w.visible = false if melee_ready else w==body_model.get_meta("guns")[weapon]\n body_model.get_meta("knife").visible = melee_ready\n flash.visible = not melee_ready and cooldown >').replace(' if cooldown > 0 or reload_left > 0:\n  return',' if cooldown > 0:\n  return\n var close_enemy = nearby_enemy()\n if close_enemy!=null:\n  cooldown = .35\n  close_enemy.take_hit(160)\n  game.sound("hit",.6)\n  game.hit_marker = .15\n  return\n if reload_left > 0:\n  return',1);t+='''
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
''';p.write_text(t)
p=s/'gear.gd';t=p.read_text()+'''
static func make_knife(parent: Node3D) -> Node3D:
 var root = Node3D.new()
 parent.add_child(root)
 F.box(root,Vector3(0,0,0),Vector3(.065,.08,.20),F.mat(Color("162a34")))
 F.box(root,Vector3(0,0,-.12),Vector3(.18,.04,.04),F.mat(Color("4de2ce"),.5))
 F.box(root,Vector3(0,0,-.31),Vector3(.065,.025,.34),F.mat(Color("b7d5e3")))
 return root
''';p.write_text(t)
p=s/'operative.gd';t=p.read_text();# attach knife at body creation before returning
idx=t.rfind(' return ')
print('operative return:',t[idx:idx+80])
p=s/'expedition.gd';t=p.read_text().replace(' for enemy in game.enemies:\n  if is_instance_valid(enemy):\n   enemy.queue_free()',' for ally in game.allies:\n  if is_instance_valid(ally):\n   ally.queue_free()\n game.allies.clear()\n for enemy in game.enemies:\n  if is_instance_valid(enemy):\n   enemy.queue_free()').replace('  var pos = random_point(1)\n  if pos.distance_to(game.player.position)>8:\n   game.spawn_enemy(pos)','  game.command.enemy_wave()');p.write_text(t)
