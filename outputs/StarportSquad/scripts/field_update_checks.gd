extends RefCounted

static func run(game: Node3D, failures: Array[String]) -> void:
 var profile = game.career
 var snapshot: Dictionary = profile.snapshot()
 profile.credits = 7000
 game.check(profile.equip_helmet(3) and profile.credits==500,"gold helmet purchase applies highest helmet tier",failures)
 game.player.sync_helmet_stats()
 game.check(game.player.helmet_health==110 and game.player.helmet_defense==255,"equipped gold helmet raises real life and shield capacity",failures)
 profile.equip_helmet(0)
 game.player.sync_helmet_stats()
 profile.add_item("armor",2)
 profile.add_item("armor",2)
 profile.equip("armor",2)
 profile.equip_helmet(3)
 var before: int = profile.items.armor[2]
 profile.lose_carried_gear()
 game.check(profile.items.armor[2]==before-1 and profile.equipped.armor==0 and not profile.helmet_owned[3],"defeat removes one carried item per slot, not storage",failures)
 profile.restore(snapshot)
 var player = game.player
 game.active = true
 game.mode = "playing"
 game.command.siege_enabled = false
 player.set_physics_process(true)
 player.position = Vector3(12,.2,25)
 player.velocity = Vector3.ZERO
 player.rotation = Vector3.ZERO
 player.camera.rotation = Vector3.ZERO
 player.set_prone(false)
 for i in range(22): await game.get_tree().physics_frame
 Input.action_press("right")
 var origin: Vector3 = player.position
 var started: bool = player.start_roll()
 Input.action_release("right")
 for i in range(28): await game.get_tree().physics_frame
 game.check(started and player.position.x>origin.x+2.0 and player.roll_left==0 and is_zero_approx(player.camera.rotation.z),"roll uses direction input and restores camera",failures)
 game.check(not player.start_roll(),"roll cooldown rejects immediate repeat",failures)
 var charge = game.pulse_charge
 # The solid southern boundary should screen a short blast across it.
 var wall_z: float = 32.0*game.expedition.scale_factor
 game.check(charge.damage_at(Vector3(0,1,wall_z-1),Vector3(0,1,wall_z+1))==0.0,"solid cover blocks charge splash",failures)
 player.position = Vector3(11,.2,25)
 player.rotation = Vector3.ZERO
 player.set_view(false,false)
 var dummy = game.spawn_enemy(Vector3(11,.1,23))
 dummy.set_physics_process(false)
 dummy.armor=0
 dummy.hp=200
 for i in range(2): await game.get_tree().physics_frame
 player.cooldown=0
 player.swing_sword()
 game.check(dummy.hp<200,"permanent sword hits a nearby visible opponent",failures)
 dummy.position.z=19
 player.set_weapon_models([11,1])
 player.switch_weapon(0)
 player.cooldown=0
 for i in range(2): await game.get_tree().physics_frame
 player.shoot()
 game.check(dummy.shock_time>0.0,"electric weapon stuns a hit enemy",failures)
 dummy.queue_free()
 profile.restore(snapshot)
 game.apply_career()
 player.position = Vector3(11,.2,25)
 player.rotation = Vector3.ZERO
 player.camera.rotation = Vector3.ZERO
 player.set_view(false,false)
 var target = game.spawn_enemy(Vector3(11,.1,20))
 target.set_physics_process(false)
 for i in range(2): await game.get_tree().physics_frame
 charge.request_launch()
 for i in range(18): await game.get_tree().physics_frame
 game.check(charge.spent and charge.target==target,"launched charge attaches to aimed character once",failures)
 target.position.x += 1.0
 for i in range(2): await game.get_tree().physics_frame
 if is_instance_valid(charge.device):
  game.check(absf(charge.device.position.x-target.position.x)<.05,"armed charge follows moving character",failures)
 else:
  game.check(false,"armed charge follows moving character",failures)
 var previous: float = charge.left
 game.active = false
 for i in range(3): await game.get_tree().physics_frame
 game.check(charge.left==previous,"pause freezes charge fuse",failures)
 # Move an actual ally and the thrower into the blast before expiry.
 var DroneScript = preload("res://scripts/drone.gd")
 var ally = CharacterBody3D.new()
 ally.set_script(DroneScript)
 ally.game = game
 ally.friendly = true
 game.add_child(ally)
 game.allies.append(ally)
 ally.set_physics_process(false)
 ally.position = target.position+Vector3(.65,0,0)
 ally.armor = 0.0
 ally.hp = 30.0
 player.position = target.position+Vector3(-.75,0,0)
 player.shield = 0.0
 player.hp = 30.0
 player.hurt_cooldown = 0.0
 var rescues: int = game.rescues
 game.active = true
 charge.tick(4.0)
 charge.request_launch()
 game.check(ally.hp<=0 and game.rescues==rescues+1 and not charge.queued,"same blast harms nearby ally and thrower, with no second charge",failures)
 game.expedition.scale_factor = 1.0
 game.world.scale = Vector3.ONE
 game.outer_port.enable()
 player.position = game.outer_port.INNER_LIFT+Vector3.UP*.15
 game.interact()
 game.check(game.outer_port.outside and game.outer_port.chunks.size()<=9 and game.outer_port.patrol.size()<=3,"outer lift streams capped chunks and patrol",failures)
 player.position = Vector3(224,.2,256)
 game.outer_port.tick()
 game.check(game.outer_port.sector==Vector2i(4,4) and game.outer_port.chunks.size()<=9 and game.outer_port.patrol.size()<=3,"remote sector streams without accumulating patrols",failures)
 player.position = game.outer_port.OUTER_LIFT+Vector3.UP*.17
 game.interact()
 game.check(not game.outer_port.outside and game.outer_port.chunks.is_empty(),"return lift unloads outer chunks",failures)
 game.outer_port.enabled = false
 game.outer_port.root.queue_free()
 game.active = false
 await game.get_tree().physics_frame
