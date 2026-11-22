extends RefCounted
# Explicit checks remain active in release exports, unlike assert().
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
 if not ok:
  failures.append(label)
  push_error("PLATFORM CHECK FAILED: "+label)

func run(game: Node3D) -> void:
 var tree = game.get_tree()
 check(game.hud.page=="menu","isolated startup")
 game.hud.show_page("difficulty")
 check(game.hud.page=="difficulty","difficulty tablet")
 for index in range(5):
  game.choose_start_difficulty(index)
  check(game.difficulty==index and game.hud.page=="menu","difficulty %d" % index)
  await tree.process_frame
 game.choose_start_difficulty(-1)
 check(game.difficulty>=0 and game.difficulty<5,"random difficulty")
 for action in ["forward","back","fire","aim","jump","reload","inventory","view_toggle"]:
  check(InputMap.has_action(action),"input "+action)
 check(load("res://assets/NotoSansSC.ttf") is Font,"bundled Chinese font")
 check(load("res://assets/orbital_drift.wav") is AudioStream,"bundled music")
 check(load("res://assets/ak.wav") is AudioStream,"bundled gun audio")
 game.start_game()
 check(game.mode=="playing" and game.active,"enter battle")
 game.player.set_view(true,false)
 check(game.player.third_person,"third person")
 game.player.set_view(false,false)
 check(not game.player.third_person,"first person")
 game.player.switch_weapon(1)
 game.player.switch_weapon(0)
 for frame in range(30):
  await tree.physics_frame
 check(is_instance_valid(game.player) and game.player.position.is_finite(),"battle simulation")
 game.pause_game()
 # Unique temporary saves exercise Windows write/rename/read without touching player saves.
 var profile = game.career.get_script().new()
 profile.path = "user://platform-check-%d.json" % Time.get_ticks_usec()
 profile.credits = 1234
 check(profile.save_profile(),"profile save/atomic rename")
 var loaded = game.career.get_script().new()
 loaded.path = profile.path
 check(loaded.load_profile() and loaded.credits==1234,"profile round trip")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(profile.path))
 var creator = load("res://creator.tscn").instantiate()
 tree.root.add_child(creator)
 var friendly = creator.spawn_unit(Vector3.ZERO,0,3,3)
 var enemy = creator.spawn_unit(Vector3(0,0,-3),1,0,0)
 creator.strike(friendly,enemy,3)
 check(enemy.armor<100,"creator combat")
 creator.selected = friendly
 creator.upgrade_selected()
 check(friendly.level==2,"creator upgrade")
 creator.forge_team()
 check(creator.forge[0]==1,"creator forge")
 creator.save_name.text = "platform-check-%d" % Time.get_ticks_usec()
 var save_path = creator.file_path()
 creator.save_world()
 check(FileAccess.file_exists(save_path),"creator save")
 creator.load_world()
 check(creator.units.size()==2 and creator.units[0].level==2,"creator load")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
 creator.queue_free()
 print("PLATFORM CHECKS PASSED" if failures.is_empty() else "PLATFORM CHECKS FAILED: %d" % failures.size())
 var exit_code = 0 if failures.is_empty() else 1
 game.queue_free()
 await tree.process_frame
 tree.quit(exit_code)
