extends RefCounted
const Gear = preload("res://scripts/gear.gd")

static func run(game: Node3D, failures: Array[String]) -> void:
 var p = game.player
 game.extracting = false
 game.extraction = 0
 game.elapsed = 0
 game.mode = "playing"
 game.active = true
 for enemy in game.enemies:
  if is_instance_valid(enemy):
   enemy.set_physics_process(false)
 # Tier changes must affect actual defense, damage, and model materials.
 for tier in range(5):
  p.equip_armor(tier)
  game.check(p.max_shield()==Gear.SHIELD[tier] and p.shield==Gear.SHIELD[tier],"armor capacity tier "+str(tier+1),failures)
  p.hurt_cooldown = 0
  p.damage(20)
  game.check(is_equal_approx(p.shield,Gear.SHIELD[tier]-20*(1-Gear.REDUCTION[tier])),"armor mitigation tier "+str(tier+1),failures)
  p.switch_weapon(0)
  p.upgrade_weapon(tier)
  game.check(p.weapon_tiers[0]==tier and p.weapons[0].get_meta("paint").albedo_color.is_equal_approx(p.armor_material.albedo_color),"visible gun and armor color tier "+str(tier+1),failures)
 game.check(Gear.damage(0,4,10)>Gear.damage(0,3,10) and Gear.damage(1,4,3)>Gear.damage(1,3,3),"red guns remain stronger than gold for both types",failures)
 game.check(Gear.interval(0,4)<Gear.interval(0,0),"red gun fires faster",failures)
 p.switch_weapon(1)
 game.check(p.weapon_tiers[1]==0,"gun tiers stored independently",failures)
 p.upgrade_weapon(4)
 game.check(p.weapon_tiers==[4,4],"both weapons can reach maximum",failures)
 for item in game.equipment:
  game.check(game.find_path(Vector3(0,0,23),item.pos).size()>1,"reachable "+item.kind+" loot tier "+str(item.tier+1),failures)
 p.equip_armor(0)
 p.weapon_tiers = [0,0]
 for kind in ["armor","gun"]:
  for tier in range(1,5):
   for i in range(game.equipment.size()):
    var item = game.equipment[i]
    if item.kind==kind and item.tier==tier:
     p.position = item.pos+Vector3.UP*.1
     game.interact()
     game.check(item.taken and (p.armor_tier==tier if kind=="armor" else p.weapon_tiers[p.weapon]==tier),"E picks up "+kind+" tier "+str(tier+1),failures)
     break
 var before = game.equipment.size()
 game.drop_equipment(Vector3(0,0,20),2,4,0)
 game.check(game.equipment.size()==before+2,"robot drops armor AND its actual gun",failures)
 p.position = Vector3(-.65,.1,20)
 game.take_equipment(before)
 game.check(p.armor_tier==4 and game.equipment[before].taken,"lower armor is stored without downgrading red armor",failures)
 game.take_equipment(before+1)
 game.check(p.weapon==0 and p.weapon_tiers[0]==4 and game.equipment[before+1].taken,"pickup robot gun preserves gun type and tier",failures)
 var victim = game.spawn_enemy(Vector3(22,.1,24))
 victim.set_physics_process(false)
 var loot_count = game.expedition.chests.size()
 victim.take_hit(10000)
 game.check(game.expedition.chests.size()==loot_count+1 and victim.hp<=0,"actual soldier defeat generates a closed loot chest",failures)
 victim.take_hit(10000)
 game.check(game.expedition.chests.size()==loot_count+1,"defeated soldier cannot duplicate chest",failures)
 # Start each difficulty through the real menu configuration method.
 for level in range(3):
  game.mode = "menu"
  game.active = false
  game.select_difficulty(level)
  await game.get_tree().physics_frame
  await game.get_tree().physics_frame
  game.check(game.enemies.size()==Gear.BOT_COUNTS[level],"enemy count in "+Gear.MODES[level],failures)
  var shared_models = true
  var red_guns = true
  for enemy in game.enemies:
   enemy.set_physics_process(false)
   shared_models = shared_models and enemy.gun.get_meta("kind")==enemy.weapon_kind
   red_guns = red_guns and enemy.weapon_tier==4
  game.check(shared_models,"robots use shared AK47 / shotgun models in "+Gear.MODES[level],failures)
  if level==2:
   game.check(red_guns,"ALL nightmare robots have red max-level guns",failures)
   var extra = game.spawn_enemy(Vector3(0,.1,12))
   extra.set_physics_process(false)
   game.check(extra.weapon_tier==4,"nightmare reinforcements also have max guns",failures)
  game.active = true
  game.mode = "playing"
  p.position = Vector3(0,.1,23)
  p.equip_armor(0)
  p.hurt_cooldown = 0
  var bot = game.spawn_enemy(Vector3(0,.1,17))
  bot.set_physics_process(false)
  await game.get_tree().physics_frame
  await game.get_tree().physics_frame
  bot.look_at(Vector3(0,.1,23))
  bot.planned_aim = p.position+Vector3.UP*.9
  bot.fire_timer = 10
  bot.grenade_timer = 0
  bot._physics_process(.016)
  if level==0:
   game.check(game.grenades.is_empty(),"simple robots do NOT throw grenades",failures)
  else:
   game.check(not game.grenades.is_empty(),"AI throws real grenade in "+Gear.MODES[level],failures)
   # Force a direct, unobstructed shot and check applied damage rather than only config.
   p.hurt_cooldown = 0
   p.shield = 100
   bot.planned_aim = p.position+Vector3.UP*.9
   bot.weapon_kind = 0
   bot.ammo = 2
   bot.fire_weapon()
   game.check(p.shield<100 and bot.ammo==1,"robot AK47 hits player and consumes ammo in "+Gear.MODES[level],failures)
   p.hurt_cooldown = 0
   p.equip_armor(4)
   bot.weapon_kind = 1
   bot.ammo = 2
   bot.fire_weapon()
   game.check(p.shield<p.max_shield() and bot.ammo==1,"robot shotgun pellets hit player in "+Gear.MODES[level],failures)
  # Clear hazards between difficulty cases.
  for g in game.grenades:
   g.node.queue_free()
   g.ring.queue_free()
  game.grenades.clear()
 # Blast behavior: real radius, cover ray, fuse, pause, and applied damage.
 p.position = Vector3(0,.1,23)
 p.equip_armor(4)
 p.hurt_cooldown = 0
 game.throw_grenade(Vector3(0,.5,21),p.position)
 var grenade = game.grenades[0]
 game.check(grenade.damage==200,"grenade damage is base 20 times 10",failures)
 var fuse_before: float = grenade.fuse
 game.active = false
 game._physics_process(.5)
 game.check(grenade.fuse==fuse_before,"pause freezes grenade fuse and flight",failures)
 game.active = true
 game.step_grenades(.1)
 game.check(grenade.fuse<fuse_before,"grenade fuse advances in gameplay",failures)
 game.check(game.grenade_damage_at(Vector3(0,.4,23),200)>150,"nearby grenade has high blast damage",failures)
 game.check(game.grenade_damage_at(Vector3(10,.4,23),200)==0,"outside blast radius is safe",failures)
 p.position = Vector3(6,.1,12)
 game.check(game.grenade_damage_at(Vector3(6,.6,6.5),200)==0,"cargo cover blocks explosion",failures)
 p.position = Vector3(0,.1,23)
 p.hurt_cooldown = 0
 var shield_before: float = p.shield
 game.explode_grenade(Vector3(0,.4,23),200)
 game.check(p.shield<shield_before and p.shield>0,"red armor survives actual grenade blast",failures)
 grenade.fuse = .01
 game.step_grenades(.02)
 game.check(game.grenades.is_empty(),"fuse expiration detonates and removes grenade",failures)
 game.active = false
 game.mode = "win"
