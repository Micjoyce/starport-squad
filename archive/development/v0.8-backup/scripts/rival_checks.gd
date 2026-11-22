extends RefCounted
const Career = preload("res://scripts/career.gd")
const Gear = preload("res://scripts/gear.gd")
static func run(game: Node3D, failures: Array[String]) -> void:
 var original = game.career
 var profile = Career.new()
 profile.path = ""
 profile.credits = 100000
 game.career = profile
 game.command.siege_enabled = false
 game.mode = "menu"
 game.active = false
 game.select_difficulty(0)
 profile.add_item("armor+",2)
 profile.equip("armor+",2)
 profile.add_item("pants+",3)
 profile.equip("pants+",3)
 profile.set_pants_style(2)
 profile.set_coat(false)
 game.apply_career()
 var mirrored = true
 for bot in game.enemies:
  bot.set_physics_process(false)
  mirrored = mirrored and bot.armor_tier==2 and bot.armor_big and bot.pants_tier==3 and bot.pants_big and bot.pants_style==2 and not bot.coat_enabled
 game.check(mirrored,"ordinary enemies mirror player's large armor, shorts and coat setting",failures)
 var bot = game.enemies[0]
 bot.armor = bot.max_armor()*.4
 var fraction: float = bot.armor/bot.max_armor()
 profile.equip("armor",0)
 profile.set_coat(true)
 game.apply_career()
 game.check(bot.armor_tier==0 and not bot.armor_big and bot.coat.visible,"changing player outfit updates already-spawned enemies visually",failures)
 game.check(is_equal_approx(bot.armor/bot.max_armor(),fraction),"mirroring equipment preserves damage fraction instead of fully healing enemies",failures)
 var extra = game.spawn_enemy(Vector3(12,.1,0))
 extra.set_physics_process(false)
 game.check(extra.armor_tier==game.player.armor_tier and extra.pants_style==2,"reinforcements inherit the current outfit immediately",failures)
 var stored = profile.snapshot()
 game.mode = "menu"
 game.select_difficulty(4)
 game.check(Gear.MODES.size()==5 and game.difficulty==4,"super-hard is a fifth selectable difficulty",failures)
 game.check(game.player.armor_tier==5 and game.player.armor_big and game.player.max_shield()==1119,"super-hard gives player actual large rainbow armor",failures)
 game.check(is_equal_approx(game.player.total_reduction(),.53),"temporary rainbow pants provide their real defense bonus",failures)
 game.check(profile.snapshot()==stored,"temporary super-hard loadout does not grant or overwrite saved inventory",failures)
 var elites = 0
 var all_rainbow = true
 for enemy in game.enemies:
  enemy.set_physics_process(false)
  all_rainbow = all_rainbow and enemy.armor_tier==5 and enemy.armor_big and enemy.pants_tier==5 and enemy.pants_big
  if enemy.is_elite:
   elites += 1
 game.check(all_rainbow and elites==1 and game.enemies.size()==21,"super-hard spawns twenty large-rainbow soldiers and exactly one elite commander",failures)
 game.player.position = game.extraction_position+Vector3.UP*.1
 game.check(game.command.recruit(),"super-hard can recruit a friendly squad",failures)
 all_rainbow = true
 for ally in game.allies:
  ally.set_physics_process(false)
  all_rainbow = all_rainbow and ally.armor_tier==5 and ally.armor_big and ally.pants_tier==5 and ally.pants_big
 game.check(all_rainbow,"all ten friendly soldiers also wear large rainbow equipment",failures)
 for enemy in game.enemies:
  enemy.set_physics_process(false)
 var elite = game.rival.unit
 elite.set_physics_process(false)
 var boxes: int = game.expedition.chests.size()
 elite.take_hit(999999)
 elite.take_hit(999999)
 game.check(game.rival.respawn_left==10 and game.expedition.chests.size()==boxes+1,"elite defeat starts one ten-second respawn and creates only one loot box",failures)
 game.active = false
 game.rival.tick(5)
 game.check(game.rival.respawn_left==10,"pause freezes elite respawn timer",failures)
 game.active = true
 game.mode = "playing"
 game.command.capture = 0
 game.rival.tick(9)
 game.check(game.rival.respawn_left==1 and game.rival.unit==null,"elite stays absent until respawn countdown ends",failures)
 game.rival.tick(1)
 game.check(is_instance_valid(game.rival.unit) and game.rival.unit.hp==999 and game.rival.lives==2,"elite returns with restored health after countdown",failures)
 game.rival.tick(100)
 game.check(game.rival.lives==2,"living elite cannot be duplicated by extra timer updates",failures)
 game.rival.unit.set_physics_process(false)
 game.rival.unit.take_hit(999999)
 game.command.capture = 1
 game.rival.tick(20)
 game.check(game.rival.unit==null and game.rival.respawn_left==0,"elite respawn waits while enemy core is being captured",failures)
 game.command.capture = 0
 game.player.position = game.command.enemy_castle.global_position
 game.rival.tick(1)
 game.check(game.rival.unit==null,"elite never respawns on top of a player inside its castle",failures)
 game.player.position = game.extraction_position
 game.rival.tick(1)
 elite = game.rival.unit
 elite.set_physics_process(false)
 game.check(game.rival.lives==3 and elite.armor_big and elite.armor_tier==5,"elite can respawn repeatedly without a life limit",failures)
 game.elapsed = 15
 game.player.position = Vector3(16,.1,0)*game.expedition.scale_factor
 for ally in game.allies:
  ally.position = Vector3(20,.1,0)*game.expedition.scale_factor
 game.check(game.rival.tactical_anchor(elite)==game.command.castle.global_position,"elite selects a poorly defended opposing castle for attack",failures)
 for i in range(3):
  game.allies[i].position = game.command.castle.global_position
 game.check(game.rival.tactical_anchor(elite)==game.command.enemy_castle.global_position,"elite avoids rushing a heavily guarded opposing core",failures)
 game.player.position = game.command.enemy_castle.global_position+Vector3(1,0,0)
 game.check(game.rival.tactical_anchor(elite)==game.command.enemy_castle.global_position and game.rival.decision=="回防核心","elite prioritizes defense when its castle is threatened",failures)
 elite.position = Vector3(-13,.1,14)*game.expedition.scale_factor
 game.player.position = Vector3(-13,.1,8)*game.expedition.scale_factor
 elite.armor = 1
 elite.reload_left = 1
 game.rival.cover_timer = 0
 await game.get_tree().physics_frame
 var goal = game.rival.destination(elite,game.player,game.player.position)
 var ray = PhysicsRayQueryParameters3D.create(game.player.position+Vector3.UP*1.4,goal+Vector3.UP*1.2,1)
 var covered = not game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
 game.check(covered and game.find_path(elite.position,goal).size()>1,"damaged or reloading elite chooses reachable cover that blocks enemy sight",failures)
 for enemy in game.enemies:
  if is_instance_valid(enemy) and enemy!=elite:
   enemy.position = Vector3(-22,.1,-28)*game.expedition.scale_factor
 elite.position = Vector3(10,.1,0)
 game.player.position = Vector3(10,.1,-7)
 elite.armor = elite.max_armor()
 elite.reload_left = 0
 await game.get_tree().physics_frame
 goal = game.rival.destination(elite,game.player,game.player.position)
 game.check(goal!=game.player.position and game.find_path(elite.position,goal).size()>1 and game.rival.decision=="侧移交火","healthy elite strafes on navigable ground during visible combat",failures)
 game.active = false
 elite.take_hit(999999)
 game.mode = "win"
 game.rival.tick(100)
 game.check(game.rival.unit==null,"finished matches never respawn another commander",failures)
 game.mode = "menu"
 game.select_difficulty(0)
 game.check(game.player.armor_tier==profile.equipped.armor and game.player.armor_big==(profile.sizes.armor==1),"leaving super-hard restores the player's saved gear",failures)
 for ally in game.allies:
  if is_instance_valid(ally):
   ally.queue_free()
 game.allies.clear()
 game.rival.reset()
 game.career = original
 game.active = false
