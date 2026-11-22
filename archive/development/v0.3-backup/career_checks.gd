extends RefCounted
const Career = preload("res://scripts/career.gd")

static func run(game: Node3D, failures: Array[String]) -> void:
 var file_path = game.report_path("career-roundtrip-test.json")
 if FileAccess.file_exists(file_path):
  DirAccess.remove_absolute(file_path)
 var profile = Career.new()
 profile.path = file_path
 game.check(profile.load_profile() and profile.credits==0 and profile.skills[0],"new career grants starter gear and unlimited dash",failures)
 var initial = profile.snapshot()
 game.check(not profile.buy("armor",0) and profile.snapshot()==initial,"insufficient funds cannot buy or alter inventory",failures)
 game.check(profile.earn(300) and profile.buy("armor",0) and profile.credits==200 and profile.items.armor[0]==2,"buy item deducts correct credits and adds ownership",failures)
 game.check(profile.sell("armor",0) and profile.credits==300 and profile.items.armor[0]==1,"sell earned duplicate returns credits",failures)
 game.check(not profile.sell("armor",0),"cannot sell last equipped starter armor",failures)
 game.check(not profile.buy("armor",4) and not profile.sell("armor",4),"ambiguous red armor pricing cannot transact",failures)
 game.check(profile.add_item("armor",4) and profile.equip("armor",4),"red armor remains owned even while price is pending",failures)
 profile.add_item("ak",1)
 profile.equip("ak",1)
 profile.add_item("sg",3)
 profile.equip("sg",3)
 game.check(profile.unlock(1) and profile.credits==50,"unlock repair deducts one-time cost",failures)
 var balance: int = profile.credits
 game.check(not profile.unlock(1) and profile.credits==balance,"unlocked skill cannot charge twice",failures)
 game.check(not profile.unlock(2),"insufficient funds cannot unlock advanced skill",failures)
 profile.earn(600)
 game.check(profile.unlock(2) and profile.skills==[true,true,true],"all three skills can be permanently unlocked",failures)
 profile.set_pants(false)
 profile.set_pants(true)
 profile.record_win(100)
 var expected = profile.snapshot()
 var reloaded = Career.new()
 reloaded.path = file_path
 game.check(reloaded.load_profile() and reloaded.snapshot()==expected,"disk save reload preserves wallet inventory skills clothing and wins",failures)
 game.check(not FileAccess.file_exists(file_path+".tmp"),"atomic save leaves no unfinished temp file",failures)
 var corrupted = file_path+".bad"
 FileAccess.open(corrupted,FileAccess.WRITE).store_string("broken-save")
 var invalid = Career.new()
 invalid.path = corrupted
 game.check(not invalid.load_profile() and not invalid.earn(10) and FileAccess.get_file_as_string(corrupted)=="broken-save","invalid save is protected from overwrite",failures)
 var original = game.career
 game.career = reloaded
 game.apply_career()
 game.check(game.player.armor_tier==4 and game.player.weapon_tiers==[1,3] and game.player.pants.visible,"new-session equipment and green pants apply to real player",failures)
 game.mode = "playing"
 game.active = true
 game.extracting = false
 var resources_before: int = game.resources.size()
 game.drop_resources(Vector3(0,0,23),40)
 var credits_before: int = reloaded.credits
 game.collect_resource(resources_before)
 game.collect_resource(resources_before)
 game.check(reloaded.credits==credits_before+40 and game.resources[resources_before].taken,"resource pickup pays once and persists",failures)
 reloaded.skills[1] = false
 game.check(not game.player.use_skill(1),"locked ability cannot be used",failures)
 reloaded.skills[1] = true
 balance = reloaded.credits
 var repairs_ok = true
 for i in range(8):
  game.player.shield = 1
  repairs_ok = repairs_ok and game.player.use_skill(1) and game.player.shield==game.player.max_shield()
 game.check(repairs_ok and reloaded.credits==balance,"repair can repeat without cooldown charges or currency cost",failures)
 game.player.position = Vector3(0,.1,29)
 game.player.rotation.y = PI
 await game.get_tree().physics_frame
 game.player.use_skill(0)
 game.check(game.player.position.z<=31.3 and game.player.position.z>30,"unlimited dash still collides with bulkhead",failures)
 game.player.position = Vector3(0,.1,29)
 game.player.rotation = Vector3.ZERO
 var victim = game.spawn_enemy(Vector3(0,.1,24))
 victim.set_physics_process(false)
 victim.armor_tier = 0
 victim.armor = 100
 await game.get_tree().physics_frame
 for i in range(5):
  game.player.use_skill(2)
 game.check(victim.hp<=0,"unlimited shockwave actually defeats nearby robot",failures)
 reloaded.save_profile()
 var final_reload = Career.new()
 final_reload.path = file_path
 game.check(final_reload.load_profile() and final_reload.credits==reloaded.credits and final_reload.equipped.armor==4,"earned progress survives another reload after gameplay",failures)
 game.mode = "playing"
 var wins_before: int = game.career.wins
 game.win()
 game.win()
 game.check(game.career.wins==wins_before+1,"mission reward cannot be duplicated by repeated completion",failures)
 game.career = original
 game.active = false
 game.mode = "win"
 for path in [file_path,file_path+".bad",file_path+".tmp"]:
  if FileAccess.file_exists(path):
   DirAccess.remove_absolute(path)
