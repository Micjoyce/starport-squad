extends RefCounted

static func run(g: Node3D, failures: Array[String]) -> void:
 # Exercise the same campaign button entry and real stage transitions.
 g.active = false
 g.mode = "menu"
 g.vehicles.enabled = true
 g.campaign.checkpoint = 0
 g.campaign.begin()
 g.check(g.campaign.enabled and g.campaign.phase==0 and g.allies.size()==3,"campaign starts with a squad and embedded tutorial",failures)
 g.check(g.arsenal.speed_multiplier()==1 and g.vehicles.fleet.size()==1,"campaign isolates sandbox multipliers and garage",failures)
 g.player.position = g.campaign.RALLY
 g.player.ads = true
 g.campaign.tick(.1)
 g.check(g.campaign.lesson==2,"arrival and aim advance tutorial",failures)
 g.campaign.receive_order("defend")
 g.check(g.campaign.phase==1 and g.campaign.remaining()==4,"defend order starts patrol encounter",failures)
 g.player.cooldown=0
 var before: int = g.player.ammo[0]
 g.player.shoot()
 g.check(g.player.ammo[0]==before-1,"campaign shots consume ammunition",failures)
 for enemy in g.campaign.foes:
  enemy.hp = 0
 g.campaign.tick(.1)
 g.check(g.campaign.phase==2 and g.command.order=="attack","clearing patrol unlocks advance",failures)
 g.player.position=Vector3(10,.2,-13)
 g.campaign.tick(.1)
 g.check(g.campaign.phase==3 and g.campaign.remaining()==3,"crossing outer ring activates final encounter",failures)
 g.player.position=g.command.enemy_core.global_position
 g.campaign.tick(8)
 g.check(g.campaign.capture==0,"core cannot be captured with active defenders",failures)
 for enemy in g.campaign.foes:
  enemy.hp=0
 g.campaign.tick(8)
 g.check(g.campaign.completed and g.hud.page=="campaign_result","core capture completes campaign and opens debrief",failures)
 g.campaign.choose_reward("armor")
 g.campaign.choose_reward("squad")
 g.check(g.campaign.reward=="armor" and g.player.max_shield()==140,"debrief commits one reward",failures)
 await g.get_tree().process_frame
