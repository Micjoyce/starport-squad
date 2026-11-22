extends RefCounted
const Career = preload("res://scripts/career.gd")
const Gear = preload("res://scripts/gear.gd")

static func run(game: Node3D, failures: Array[String]) -> void:
 var path = game.report_path("operative-save-test.json")
 var profile = Career.new()
 profile.path = path
 var old = {"version":1,"credits":1234,"items":{"armor":[1,0,0,0,1],"ak":[1,1,0,0,0],"sg":[1,0,0,1,0]},"equipped":{"armor":4,"ak":1,"sg":3},"skills":[true,true,true],"green_pants":true,"wins":7}
 profile.restore(old)
 game.check(profile.credits==1234 and profile.items.armor.size()==6 and profile.equipped.armor==4 and profile.wins==7,"v0.3 save migrates without losing credits equipment or wins",failures)
 game.check(profile.operator_coat and not profile.third_person,"old save receives free healing coat and first-person default",failures)
 profile.credits = 20000
 game.check(profile.price("armor",5)==10555 and profile.buy("armor",5) and profile.credits==9445,"rainbow armor costs exactly 10555",failures)
 profile.equip("armor",0)
 game.check(profile.sell("armor",5) and profile.credits==19999,"rainbow armor resale is exactly 10554",failures)
 profile.buy("armor",5)
 profile.equip("armor",5)
 game.check(Gear.SHIELD[5]>Gear.SHIELD[4] and Gear.armor_rank(5)>Gear.armor_rank(4),"rainbow armor is strongest above red",failures)
 var original = game.career
 game.career = profile
 game.apply_career()
 game.check(game.player.armor_tier==5 and game.player.max_shield()==1119 and game.player.body_model.get_meta("armor_parts")[0].material_override is ShaderMaterial,"rainbow armor applies real stats and animated material",failures)
 game.mode = "playing"
 game.active = true
 game.extracting = false
 var balance = profile.credits
 var unlimited = true
 for i in range(20):
  game.player.shield = 1
  unlimited = unlimited and game.player.coat_heal() and game.player.shield==game.player.max_shield()
 game.check(unlimited and profile.credits==balance,"coat heals 20 consecutive times with no cooldown or resource cost",failures)
 profile.set_coat(false)
 game.player.refresh_body()
 game.player.shield = 12
 game.check(not game.player.coat_heal() and game.player.shield==12,"unequipped coat cannot grant healing",failures)
 profile.set_coat(true)
 game.player.refresh_body()
 game.check(game.player.body_model.get_meta("coat").visible,"equipped operator coat is visible on character",failures)
 for enemy in game.enemies:
  if is_instance_valid(enemy):
   enemy.set_physics_process(false)
   enemy.collision_layer = 0
 var p = game.player
 p.position = Vector3(0,.1,23)
 p.rotation = Vector3.ZERO
 p.camera.rotation = Vector3.ZERO
 p.set_view(true)
 game.check(p.third_person and p.body_model.visible and not p.gun.visible and p.camera.position.z>2,"third-person uses full character and shoulder camera",failures)
 var bot = game.spawn_enemy(Vector3(0,.1,17))
 bot.set_physics_process(false)
 bot.armor_tier = 0
 bot.armor = 100
 await game.get_tree().physics_frame
 await game.get_tree().physics_frame
 var hp_before: float = bot.hp+bot.armor
 p.switch_weapon(0)
 p.camera.rotation = Vector3.ZERO
 p.cooldown = 0
 p.reload_left = 0
 p.ammo[0] = 30
 p.shoot()
 game.check(bot.hp+bot.armor<hp_before,"third-person crosshair and muzzle ray actually hit robot",failures)
 p.position = Vector3(0,.1,29)
 p.camera.rotation = Vector3.ZERO
 await game.get_tree().physics_frame
 p.update_view()
 game.check(p.camera.global_position.z<31.31,"third-person camera sphere stops before bulkhead",failures)
 p.set_view(false)
 game.check(not p.third_person and not p.body_model.visible and p.gun.visible and p.camera.position.is_equal_approx(Vector3(0,1.58,0)),"switching back restores first-person gun and eye position",failures)
 p.equip_armor(4)
 var index = game.equipment.size()
 game.add_equipment(Vector3(0,0,20),"armor",5)
 game.take_equipment(index)
 game.check(p.armor_tier==5 and game.equipment[index].taken,"rainbow loot upgrades previously worn red armor",failures)
 p.set_view(true)
 profile.set_coat(false)
 var reload_profile = Career.new()
 reload_profile.path = path
 game.check(reload_profile.load_profile() and reload_profile.third_person and not reload_profile.operator_coat and reload_profile.items.armor[5]>0,"view coat and rainbow ownership survive disk reload",failures)
 p.set_view(false,false)
 game.career = original
 game.active = false
 game.mode = "win"
 if FileAccess.file_exists(path):
  DirAccess.remove_absolute(path)
