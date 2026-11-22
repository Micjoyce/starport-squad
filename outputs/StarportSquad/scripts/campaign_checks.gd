extends RefCounted

static func run(g: Node3D, failures: Array[String]) -> void:
 var Campaign = preload("res://scripts/campaign.gd")
 var save_file: String = g.report_path("campaign-test-save.cfg")
 var progress = Campaign.new()
 progress.save_path = save_file
 progress.checkpoint = 2
 g.check(progress.persist(),"campaign checkpoint writes to disk",failures)
 var restored = Campaign.new()
 restored.save_path = save_file
 restored.load_progress()
 g.check(restored.checkpoint==2,"new campaign instance restores the checkpoint",failures)
 DirAccess.remove_absolute(save_file)
 # Exercise the same campaign button entry and real stage transitions.
 g.active = false
 g.mode = "menu"
 g.vehicles.enabled = true
 g.expedition.scale_factor = 1.0
 g.world.scale = Vector3.ONE
 g.command.pending_recruits = 0
 g.campaign.checkpoint = 0
 g.player.set_physics_process(true)
 g.forts.climbs.clear()
 g.player.slide_left=0
 g.campaign.begin()
 for i in range(5): await g.get_tree().physics_frame
 g.check(g.campaign.enabled and g.campaign.phase==0 and g.allies.size()==3,"campaign starts with a squad and embedded tutorial",failures)
 g.check(g.arsenal.speed_multiplier()==1 and g.vehicles.fleet.size()==1,"campaign isolates sandbox multipliers and garage",failures)
 g.player.rotation.y = atan2(2.3,6.7)
 Input.action_press("forward")
 for i in range(75): await g.get_tree().physics_frame
 Input.action_release("forward")
 Input.action_press("aim")
 for i in range(3): await g.get_tree().physics_frame
 Input.action_release("aim")
 g.check(g.campaign.lesson==2,"arrival and aim advance tutorial",failures)
 g.campaign.receive_order("defend")
 g.check(g.campaign.phase==1 and g.campaign.remaining()==8 and g.campaign.deployed_count()==4,"defend order starts patrol encounter",failures)
 for unit in g.allies+g.enemies:
  if is_instance_valid(unit): unit.set_physics_process(false)
 var plated = g.spawn_enemy(Vector3(13,.1,20),false,false,3)
 plated.set_physics_process(false)
 g.check(plated.helmet_guard==255 and plated.max_hp==210 and plated.shell.visible,"gold defender starts with exact defense and life bonus",failures)
 plated.break_armor()
 g.check(plated.field_helmet==1 and plated.helmet_guard==77 and not plated.shell.visible and plated.inner_uniform.visible,"breaking armor reveals clothes and downgrades gold to steel",failures)
 var health: float = plated.hp
 plated.take_hit(90.0)
 g.check(plated.helmet_guard==0 and plated.hp==health-13.0,"remaining steel guard absorbs exactly 77 damage",failures)
 g.enemies.erase(plated)
 plated.queue_free()
 g.player.cooldown=0
 var before: int = g.player.ammo[0]
 g.player.shoot()
 g.check(g.player.ammo[0]==before-1,"campaign shots consume ammunition",failures)
 g.player.ammo[0]=0
 g.player.reload_weapon()
 for i in range(110): await g.get_tree().physics_frame
 g.check(g.player.ammo[0]==30,"campaign reload completes in live physics",failures)
 var transport: Node3D = g.campaign.transport
 g.player.position = transport.position+Vector3(3,.2,0)
 g.interact()
 var seated: bool = g.vehicles.current==transport
 await g.get_tree().physics_frame
 g.interact()
 g.check(seated and g.vehicles.current==null,"campaign transport supports real boarding and dismount",failures)
 for enemy in g.campaign.foes:
  if is_instance_valid(enemy): enemy.hp = 0
 g.campaign.tick(.1)
 g.check(g.campaign.deployed_count()==4 and g.campaign.phase==1,"landing reinforcements arrive before the objective clears",failures)
 clear_encounter(g)
 g.campaign.tick(.1)
 g.check(g.campaign.phase==2 and g.command.order=="attack","clearing patrol unlocks advance",failures)
 g.player.position=Vector3(10,.2,-13)
 g.campaign.tick(.1)
 g.check(g.campaign.phase==2,"outer ring cannot be skipped while patrol remains",failures)
 clear_encounter(g)
 g.campaign.tick(.1)
 g.check(g.campaign.phase==3 and g.campaign.remaining()==7,"crossing outer ring activates final encounter",failures)
 g.player.position=g.command.enemy_core.global_position
 g.campaign.tick(8)
 g.check(g.campaign.capture==0,"core cannot be captured with active defenders",failures)
 clear_encounter(g)
 g.campaign.tick(8)
 g.check(g.campaign.completed and g.hud.page=="campaign_result","core capture completes campaign and opens debrief",failures)
 g.campaign.choose_reward("armor")
 g.campaign.choose_reward("squad")
 g.check(g.campaign.reward=="armor" and g.player.max_shield()==140,"debrief commits one reward",failures)
 g.active = true
 for i in range(4): g.command.recruit()
 g.check(g.command.alive_count()==30 and g.command.pending_recruits==13,"repeat recruit orders retain overflow instead of dropping units",failures)
 g.allies.back().hp=0
 g.command.deploy_reserves(1.0)
 g.check(g.command.alive_count()==30 and g.command.pending_recruits==12,"a free battlefield slot automatically deploys a queued soldier",failures)
 g.active = false
 await g.get_tree().process_frame


static func clear_encounter(g: Node3D) -> void:
 for batch in range(3):
  for enemy in g.campaign.foes:
   if is_instance_valid(enemy): enemy.hp=0
  if not g.campaign.reserves.is_empty(): g.campaign.tick(0.0)
