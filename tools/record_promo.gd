extends SceneTree
# Native engine recording: scripted inputs/camera cuts, no fabricated game footage.
# Uses isolated in-memory profiles through --record-promo.
var game: Node3D
var creator: Node3D
var overview: Camera3D
var stop_frame := 1080

func _initialize() -> void:
 call_deferred("record")

func release_inputs() -> void:
 for action in ["forward","right","left","fire","aim","sprint"]:
  Input.action_release(action)

func aim_at(point: Vector3) -> void:
 var direction = point-game.player.camera.global_position
 game.player.rotation.y = atan2(-direction.x,-direction.z)
 game.player.camera.rotation.x = atan2(direction.y,Vector2(direction.x,direction.z).length())

func record() -> void:
 game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.rng.seed = 42031
 game.hud.hide()
 overview = Camera3D.new()
 game.add_child(overview)
 overview.current = true
 overview.fov = 68
 for frame in range(stop_frame):
  var seconds = frame/30.0
  if frame<90:
   overview.position = Vector3(24*cos(seconds*.16),13,23*sin(seconds*.16)+17)
   overview.look_at(Vector3(0,2,-4))
  if frame==90:
   game.hud.show()
   game.choose_start_difficulty(0)
   game.campaign.begin()
   game.player.position = Vector3(0,.15,21)
   game.player.rotation.y = 0
   game.player.camera.rotation.x = -.04
  if frame==135:
   Input.action_press("forward")
  if frame==195:
   Input.action_release("forward")
   game.campaign.set_phase(1,false)
  if frame>=210 and frame<370:
   if not game.campaign.foes.is_empty() and is_instance_valid(game.campaign.foes[0]):
    aim_at(game.campaign.foes[0].position+Vector3(0,1.2,0))
   if frame%30==0:
    game.player.shoot()
  if frame==390:
   release_inputs()
   game.campaign.set_phase(2,false)
   game.player.position = game.forts.top()+Vector3(0,0,-4.6)
   game.player.velocity = Vector3.ZERO
   game.player.switch_weapon(1)
   game.player.rotation.y = -.1
   game.player.camera.rotation.x = -.19
  if frame==450:
   Input.action_press("aim")
  if frame in [480,540,600]:
   game.player.shoot()
  if frame==660:
   release_inputs()
   game.player.position = Vector3(0,.15,21)
   game.player.velocity = Vector3.ZERO
   game.player.rotation.y = 0
   game.player.camera.rotation.x = -.07
   game.player.switch_weapon(0)
   game.player.set_view(true,false)
   game.command.set_order("attack")
   Input.action_press("forward")
  if frame==780:
   Input.action_release("forward")
  if frame==840:
   release_inputs()
   game.active = false
   game.hide()
   game.hud.hide()
   creator = load("res://creator.tscn").instantiate()
   root.add_child(creator)
   creator.rng.seed = 912
   creator.camera.position = Vector3(32,44,39)
   creator.camera.look_at(Vector3.ZERO)
   creator.camera.size = 70
   for team in range(2):
    for index in range(12):
     creator.spawn_unit(Vector3(-12+index*2,0,12 if team==0 else -12),team,index%3,3 if team==0 else 1)
    creator.spawn_unit(Vector3(-8,0,17 if team==0 else -17),team,3,3)
    creator.spawn_unit(Vector3(8,0,17 if team==0 else -17),team,4,2)
   creator.fighting = true
   creator.refresh()
  await RenderingServer.frame_post_draw
 release_inputs()
 print("PROMO RECORDING COMPLETE: 1080 frames / 36 seconds")
 quit()
