extends RefCounted
const Career = preload("res://scripts/career.gd")
const Gear = preload("res://scripts/gear.gd")
static func run(game: Node3D, failures: Array[String]) -> void:
 var original = game.career
 var profile = Career.new()
 profile.path = game.report_path("workshop-save-test.json")
 profile.credits = 5000
 game.career = profile
 game.companions.enabled = false
 game.command.siege_enabled = false
 game.mode = "menu"
 game.active = false
 game.select_difficulty(0)
 for unit in game.enemies:
  unit.set_physics_process(false)
  unit.position = Vector3(-22,.1,-28)*game.expedition.scale_factor
 game.check(profile.workshop("silencer") and profile.silencer and profile.credits==4500,"workshop purchases and saves a silencer",failures)
 var balance: int = profile.credits
 game.check(not profile.workshop("silencer") and profile.credits==balance,"owned silencer cannot be charged twice",failures)
 for i in range(5): profile.workshop("chip")
 game.check(profile.chips==5 and profile.credits==3000,"rate chips can be bought as separate inventory items",failures)
 game.check(profile.workshop("fuse") and profile.rate_level==1 and profile.chips==4,"first chip installs a twenty-times rate upgrade",failures)
 game.check(is_equal_approx(game.arsenal.interval(0,0),Gear.interval(0,0)*.25/20),"level-one chip applies actual twenty-times firing speed",failures)
 profile.workshop("fuse")
 profile.workshop("fuse")
 game.check(profile.rate_level==3 and profile.chips==0 and not profile.workshop("fuse"),"fusion consumes two spare chips per further level and stops at level three",failures)
 game.check(is_equal_approx(game.arsenal.interval(0,0),1.0/1200),"extreme rate is simulated at a bounded twelve-hundred rounds per second",failures)
 profile.workshop("magazine")
 profile.workshop("magazine")
 game.apply_career()
 game.check(game.player.capacity==[90,24] and profile.mag_level==2,"magazine upgrades change actual primary and secondary capacity",failures)
 game.check(game.player.weapons[0].get_meta("silencer").visible,"purchased silencer appears on the actual weapon",failures)
 var calibers = []
 for i in range(5):
  calibers.append(game.arsenal.CALIBERS[profile.caliber])
  profile.workshop("caliber")
 game.check(3 in calibers and 10 in calibers and 20 in calibers and 100 in calibers and 1000 in calibers,"all five requested fictional millimeter ammunition specs are selectable",failures)
 var funds: int = profile.credits
 profile.credits = 0
 var before = profile.snapshot()
 game.check(not profile.workshop("chip") and profile.snapshot()==before,"unaffordable upgrades roll back all inventory mutations",failures)
 profile.credits = funds
 profile.workshop("horse")
 profile.workshop("feed")
 game.check(profile.horse_owned and profile.pet_xp==5,"horse adoption and feeding create permanent pet progression",failures)
 profile.eggs = [1,1,1,1,1,1]
 game.check(profile.workshop("eggs") and profile.pet_xp==26 and profile.eggs==[0,0,0,0,0,0],"opening supply eggs consumes them once and trains pets",failures)
 game.check(not profile.workshop("eggs"),"empty supply inventory cannot yield more rewards",failures)
 profile.save_profile()
 var restored = Career.new()
 restored.path = profile.path
 game.check(restored.load_profile() and restored.rate_level==3 and restored.mag_level==2 and restored.silencer and restored.horse_owned and restored.pet_xp==26,"weapon modifications and pet progression survive actual disk reload",failures)
 var old = Career.new()
 old.restore({"credits":123})
 game.check(old.pet_kind==0 and old.rate_level==0 and old.credits==123,"old saves receive a free dog without losing their existing balance",failures)
 var totals = [0,0,0,0,0,0]
 for sample in range(5000):
  var roll = game.companions.roll_eggs()
  for i in range(6): totals[i] += roll[i]
 var distribution = true
 for i in range(6):
  distribution = distribution and absf(totals[i]/5000.0-game.companions.CHANCES[i])<.04
 game.check(distribution and totals[5]==5000,"independent supply rolls match configured chances and always include a red egg",failures)
 game.active = true
 game.mode = "playing"
 var p = game.player
 p.set_physics_process(false)
 p.position = Vector3(10,.1,12)
 p.rotation = Vector3.ZERO
 p.camera.rotation = Vector3.ZERO
 p.shield = p.max_shield()
 p.hp = 100
 p.max_hp = 100
 p.hurt_cooldown = 0
 p.damage(999999)
 game.check(p.shield==0 and p.hp==100 and p.armor_broken,"player armor breaks with particles while core health survives the same hit",failures)
 game.check(game.effects.size()>=20,"armor break emits a bounded burst of physical fragments",failures)
 p.hurt_cooldown = 0
 p.damage(15)
 game.check(p.hp==85,"subsequent unarmored hit damages separate player health",failures)
 p.activate_overcharge()
 game.check(p.hp==999 and p.max_hp==999,"captain Q enables nine-hundred-ninety-nine real health",failures)
 profile.grenades = 0
 var infinite = true
 for i in range(4):
  p.grenade_cooldown = 0
  infinite = infinite and p.throw_player_grenade()
 game.check(infinite and profile.grenades==0,"infinite player grenades work even with zero stored grenades",failures)
 for shot in game.grenades:
  shot.node.queue_free()
  shot.ring.queue_free()
 game.grenades.clear()
 game.arsenal.rocket(Vector3(0,1,30*game.expedition.scale_factor),Vector3(0,1,40*game.expedition.scale_factor),true)
 game.check(game.grenades.back().rocket and game.grenades.back().velocity.length()>20,"rocket specialists launch actual fast projectiles",failures)
 game.step_grenades(.5)
 game.check(game.grenades.is_empty(),"rocket collision detonates and removes the projectile",failures)
 p.ammo = p.capacity.duplicate()
 p.cooldown = 0
 p.reload_left = 0
 var ammo: int = p.rounds_emitted
 Input.action_press("fire")
 p._physics_process(1.0/60)
 Input.action_release("fire")
 game.check(p.rounds_emitted-ammo>=15 and p.rounds_emitted-ammo<=32,"extreme firing emits multiple real rounds within one physics frame",failures)
 var enemy = game.spawn_enemy(Vector3(10,.1,5))
 enemy.set_physics_process(false)
 enemy.armor = 1
 enemy.hp = 100
 await game.get_tree().physics_frame
 enemy.take_hit(2000)
 game.check(enemy.armor==0 and enemy.hp==100,"enemy armor break also gates overkill instead of instantly deleting health",failures)
 enemy.hp = 100
 enemy.armor = 0
 for i in range(40): enemy.take_laser(99999)
 game.check(enemy.hp>=97 and enemy.hp<100,"even maximum-rate rainbow laser cannot delete core health in one frame",failures)
 enemy.armor = 1119
 enemy.hp = 100
 profile.pet_kind = 1
 game.companions.enabled = true
 game.companions.sync_pet()
 var horse = game.companions.pet
 game.companions.enabled = false
 horse.position = enemy.position+Vector3(1,0,0)
 await game.get_tree().physics_frame
 horse.step(.016)
 game.check(enemy.armor==0 and enemy.hp==100,"pet horse bite destroys enemy armor without requiring a player shot",failures)
 profile.pet_kind = 0
 game.companions.enabled = true
 game.companions.sync_pet()
 var dog = game.companions.pet
 game.companions.enabled = false
 dog.position = enemy.position+Vector3(1,0,0)
 await game.get_tree().physics_frame
 dog.step(.016)
 game.check(enemy.hp<100,"pet dog independently bites an opposing soldier",failures)
 enemy.position = Vector3(-13,.1,14)*game.expedition.scale_factor
 p.position = Vector3(-13,.1,8)*game.expedition.scale_factor
 enemy.armor = 1
 enemy.reload_left = 1
 enemy.brain.cover_timer = 0
 await game.get_tree().physics_frame
 var cover = enemy.brain.destination(enemy,p,p.position,.016)
 var cover_ray = PhysicsRayQueryParameters3D.create(p.position+Vector3.UP*1.4,cover+Vector3.UP*1.2,1)
 game.check(not game.get_world_3d().direct_space_state.intersect_ray(cover_ray).is_empty() and game.find_path(enemy.position,cover).size()>1,"ordinary soldiers also choose reachable cover while reloading",failures)
 enemy.armor = 0
 var face_found = false
 for part in enemy.model.get_children(): face_found = face_found or part.has_meta("human_face")
 game.check(face_found and enemy.brain!=null,"soldiers have human faces and independent tactical brains",failures)
 var boxes: int = game.expedition.chests.size()
 enemy.take_hit(999999)
 game.check(game.expedition.chests.size()==boxes+1 and game.expedition.chests.back().pet_eggs[5]==1,"defeated enemy's actual chest contains a guaranteed red pet egg",failures)
 var chest_index: int = game.expedition.chests.size()-1
 game.expedition.open_chest(chest_index)
 game.expedition.claim_chest()
 game.check(profile.eggs[5]==1,"claiming a battle chest persists its pet supply reward",failures)
 profile.credits = 100000
 game.mode = "playing"
 game.active = true
 game.companions.enabled = true
 game.command.recruit()
 var parent = game.allies[0]
 parent.set_physics_process(false)
 parent.position = game.command.castle.global_position
 game.companions.budget = 200
 game.check(game.companions.summon(parent),"a recruited soldier can summon a child soldier",failures)
 var child = game.allies.back()
 child.set_physics_process(false)
 game.check(child.generation==1 and game.companions.summon(child) and game.allies.back().generation==2,"summoned soldiers can themselves summon the next generation",failures)
 for i in range(40): game.companions.summon(parent)
 game.check(game.command.alive_count()==30 and not game.companions.summon(parent),"recursive friendly recruitment respects the thirty-soldier simultaneous cap",failures)
 var hostile = game.enemies[0]
 hostile.position = game.command.enemy_castle.global_position
 for i in range(60): game.companions.summon(hostile)
 var count := 0
 for unit in game.enemies:
  if is_instance_valid(unit) and unit.hp>0 and not unit.is_elite and not unit.is_boss: count += 1
 game.check(count==40 and not game.companions.summon(hostile),"opposing recursive summons also stop at their forty-soldier cap",failures)
 game.companions.budget = 0
 game.check(not game.companions.summon(parent),"global summon budget prevents a single-frame spawning storm",failures)
 game.companions.enabled = false
 game.arsenal.section = 0
 game.hud.show_page("workshop")
 profile.rate_level = 0
 game.hud.show_page("workshop")
 var chips: int = profile.chips
 var clicked = false
 for button in game.hud.buttons:
  if button.text.begins_with("购买射速芯片"):
   button.pressed.emit()
   clicked = true
   break
 game.check(clicked and profile.chips==chips+1,"actual workshop button purchases a chip through the UI callback",failures)
 if is_instance_valid(game.companions.pet): game.companions.pet.queue_free()
 game.companions.pet = null
 for ally in game.allies:
  if is_instance_valid(ally): ally.queue_free()
 game.allies.clear()
 game.career = original
 game.active = false
 for path in [profile.path,profile.path+".tmp"]:
  if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
