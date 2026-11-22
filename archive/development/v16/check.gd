extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 assert(game.hud.page=="difficulty")
 game.test_mode=true
 game.career.path=""
 for i in range(5):
  game.choose_start_difficulty(i)
  assert(game.difficulty==i and game.hud.page=="menu")
  await physics_frame
 game.choose_start_difficulty(-1)
 assert(game.difficulty>=0 and game.difficulty<5)
 print("DIFFICULTY CHECKS PASSED")
 quit()
