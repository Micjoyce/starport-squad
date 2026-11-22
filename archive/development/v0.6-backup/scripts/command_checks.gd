extends RefCounted
const Career = preload("res://scripts/career.gd")
const Gear = preload("res://scripts/gear.gd")
static func run(game: Node3D, failures: Array[String]) -> void:
 var original = game.career
 var profile = Career.new()
 profile.path = ""
 profile.credits = 100000
 game.career = profile
 game.command.refresh_castle()
 game.check(profile.castle_level==0 and game.command.NAMES.size()==12,"castle starts small white and has twelve ordered levels",failures)
 for level in range(1,12):
  game.check(game.command.upgrade() and profile.castle_level==level,"castle upgrade level "+str(level),failures)
 var balance: int = profile.credits
 game.check(not game.command.upgrade() and profile.credits==balance,"maximum castle cannot consume more currency",failures)
 var data = profile.snapshot()
 var restored = Career.new()
 restored.restore(data)
 game.check(restored.castle_level==11,"castle level survives save data restoration",failures)
 restored.restore({"credits":123})
 game.check(restored.castle_level==0 and restored.credits==123,"legacy save defaults to free ordinary castle",failures)
 profile.credits = 999
 game.check(not game.command.recruit() and game.command.alive_count()==0,"recruitment rejects insufficient currency without spawning",failures)
 profile.credits = 10000
 var alive_before = 0
 for enemy in game.enemies:
  if is_instance_valid(enemy) and enemy.hp>0 and not enemy.is_boss:
   alive_before += 1
 game.active = false
 game.check(game.command.recruit() and game.command.alive_count()==10 and profile.credits==9000,"recruitment atomically pays for exactly ten allies",failures)
 var alive_after = 0
 for enemy in game.enemies:
  if is_instance_valid(enemy) and enemy.hp>0 and not enemy.is_boss:
   alive_after += 1
 game.check(alive_after==alive_before+10,"opposing army reinforces in a ten-soldier wave",failures)
 game.check(not game.command.recruit() and profile.credits==9000,"existing squad prevents duplicate recruitment charge",failures)
 for ally in game.allies:
  ally.set_physics_process(false)
  game.check(ally.friendly and ally.collision_layer==8,"ally faction and collision remain separate",failures)
 var unit = game.allies[0]
 game.player.position = game.extraction_position+Vector3(0,0,-5)
 unit.position = game.player.position+Vector3(0,0,10)
 game.active = true
 var before: float = unit.position.distance_to(game.player.position)
 for enemy in game.enemies:
  if is_instance_valid(enemy):
   enemy.set_physics_process(false)
   enemy.position = Vector3(-22,0,-28)*game.expedition.scale_factor
 for frame in range(90):
  unit._physics_process(1.0/60)
  await game.get_tree().physics_frame
 game.check(unit.position.distance_to(game.player.position)<before-1,"allied soldier physically follows the moving leader",failures)
 game.player.set_view(true,false)
 game.check(game.command.alive_count()==10 and game.player.third_person,"third-person switching preserves recruited squad",failures)
 game.player.set_view(false,false)
 game.check(game.command.alive_count()==10 and not game.player.third_person,"first-person switching preserves visible world allies",failures)
 var target = game.enemies.back()
 target.position = game.player.position+Vector3(0,0,-1.5)
 target.hp = 1000
 target.armor = 0
 await game.get_tree().physics_frame
 game.player.cooldown = 0
 game.player.reload_left = 0
 var ammo: int = game.player.ammo[game.player.weapon]
 var health: float = target.hp
 game.player.shoot()
 game.check(target.hp<health and game.player.ammo[game.player.weapon]==ammo,"nearby player uses knife without spending ammunition",failures)
 target.position = game.player.position+Vector3(0,0,-1.5)
 target.fire_timer = 0
 target.windup = -1
 var shield: float = game.player.shield
 game.player.hurt_cooldown = 0
 target._physics_process(.016)
 game.check(target.knife.visible and game.player.shield<shield,"nearby opposing soldier switches to damaging knife",failures)
 # An allied shot must actually damage an opponent while sparing the leader.
 unit.position = game.player.position+Vector3(4,0,0)
 target.position = unit.position+Vector3(0,0,-5)
 unit.look_at(Vector3(target.position.x,unit.position.y,target.position.z))
 await game.get_tree().physics_frame
 var enemy_total: float = target.hp+target.armor
 var leader_total: float = game.player.shield
 game.command.ally_shot(unit,unit.gun.to_global(Vector3(0,0,-.7)),target.position+Vector3.UP*1.1)
 game.check(target.hp+target.armor<enemy_total and game.player.shield==leader_total,"allied gunfire damages opposing army without friendly fire",failures)
 var ally_total: float = unit.hp+unit.armor
 game.explode_grenade(unit.position+Vector3.UP,200,false)
 game.check(unit.hp+unit.armor<ally_total,"enemy grenades can damage recruited soldiers",failures)
 var wall = game.command.walls[0]
 var from = wall.global_position+Vector3(-3,0,0)
 var to = wall.global_position+Vector3(3,0,0)
 var hit = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))
 game.check(not hit.is_empty(),"upgraded castle wall physically blocks projectile raycasts",failures)
 game.check(is_equal_approx(Gear.interval(0,0),Gear.BASE_INTERVAL[0]*Gear.RATE[0]*.7),"gun intervals reduced thirty percent for faster fire",failures)
 game.command.battle_started = true
 game.difficulty = 0
 game.victory_paid = false
 game.mode = "playing"
 balance = profile.credits
 for enemy in game.enemies:
  if is_instance_valid(enemy):
   enemy.hp = 0
 game.active = true
 game.command.tick()
 game.check(profile.credits==balance+1000000,"victory grants exactly one million coins",failures)
 game.resume_looting()
 game.win()
 game.check(profile.credits==balance+1000000,"repeated victory cannot duplicate million-coin payout",failures)
 for ally in game.allies:
  if is_instance_valid(ally):
   ally.queue_free()
 game.allies.clear()
 game.career = original
 game.command.refresh_castle()
 game.active = false
