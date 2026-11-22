extends RefCounted
var game: Node3D
var last_key := ""

func outfit(unit: Node3D = null) -> Dictionary:
 if game.campaign.enabled:
  return {"route":-1,"armor":0,"large":false,"pants":0,"pants_large":false,"style":1,"green":false,"coat":false}
 var forced = game.difficulty==4 or (unit!=null and (unit.is_boss or unit.is_elite))
 var ally = unit!=null and unit.friendly and not forced
 return {"route":game.career.armor_route_level if game.career.armor_route_equipped and not forced and not ally else -1,"armor":5 if forced else (game.career.castle_level%6 if ally else game.player.armor_tier),"large":forced or (not ally and game.player.armor_big),"pants":5 if forced else (game.career.castle_level%6 if ally else game.career.equipped.pants),"pants_large":forced or (not ally and game.career.sizes.pants==1),"style":1 if forced or ally else game.career.pants_style,"green":not ally and game.career.green_pants,"coat":not ally and game.career.operator_coat}

func configure(unit: Node3D) -> void:
 var look = outfit(unit)
 unit.set_meta("armor_route",look.route)
 unit.armor_tier = look.armor
 unit.armor_big = look.large
 unit.pants_tier = look.pants
 unit.pants_big = look.pants_large
 unit.pants_style = look.style
 unit.green_pants = look.green
 unit.coat_enabled = look.coat
 unit.costume_key = JSON.stringify(look)

func apply_unit(unit: Node3D) -> void:
 if not is_instance_valid(unit) or unit.hp<=0:
  return
 if unit.costume_key==JSON.stringify(outfit(unit)):
  return
 var remaining: float = clampf(unit.armor/unit.max_armor(),0,1)
 configure(unit)
 unit.armor = unit.max_armor()*remaining
 unit.rebuild_model()

func sync() -> void:
 if not is_instance_valid(game.player) or not is_instance_valid(game.player.body_model):
  return
 if game.difficulty==4 and (game.player.armor_tier!=5 or not game.player.armor_big):
  game.player.armor_big = true
  game.player.equip_armor(5)
 var key = str(game.difficulty)+JSON.stringify(outfit())+str(game.career.castle_level)
 if key==last_key:
  return
 last_key = key
 game.player.update_pants_equipment()
 for units in [game.enemies,game.allies]:
  for unit in units:
   if is_instance_valid(unit): apply_unit(unit)
