extends RefCounted
const Career = preload("res://scripts/career.gd")
const Gear = preload("res://scripts/gear.gd")

static func run(game: Node3D, failures: Array[String]) -> void:
 var original = game.career
 var profile = Career.new()
 profile.path = game.report_path("expedition-save-test.json")
 profile.credits = 40000
 game.career = profile
 game.mode = "playing"
 game.active = true
 game.extracting = false
 profile.add_item("armor",5)
 profile.equip("armor",5)
 game.apply_career()
 var p = game.player
 game.check(p.max_shield()==1119,"rainbow armor base health is exactly 1119",failures)
 game.check(p.activate_overcharge() and p.max_shield()==9999 and p.shield==9999,"Q raises rainbow health to exactly 9999",failures)
 p.shield = 12
 p.coat_heal()
 game.check(p.shield==9999,"coat healing respects the 9999 maximum",failures)
 p.equip_armor(0)
 game.check(p.activate_overcharge() and p.max_shield()==100 and p.hp==999,"non-rainbow captain gains 999 health without rainbow shield",failures)
 game.check(profile.price("armor",5)-profile.resale("armor",5)==1 and profile.resale("armor",5)==10554,"rainbow resale is purchase price minus one",failures)
 game.check(profile.add_item("armor+",4) and profile.equip("armor+",4),"large red armor is a separate owned item",failures)
 game.apply_career()
 game.check(p.armor_big and p.max_shield()==450,"large armor has its own real capacity bonus",failures)
 profile.add_item("ak+",5)
 profile.equip("ak+",5)
 game.check(profile.select_model("ak",6),"rainbow gun can be unlocked and selected",failures)
 game.apply_career()
 game.check(p.weapon_models[0]==6 and p.weapons[0].get_meta("kind")==6,"rainbow gun has a real equipped model",failures)
 game.check(profile.select_model("ak",7),"AK47M1LW can be unlocked and selected",failures)
 game.apply_career()
 game.check(p.weapon_models[0]==7 and p.capacity[0]==40,"AK47M1LW changes actual player weapon and magazine",failures)
 var lower = game.equipment.size()
 game.add_equipment(Vector3(0,0,20),"gun",0,3)
 game.take_equipment(lower)
 game.check(3 in profile.owned_models and profile.models.ak==7,"lower-quality loot unlocks its gun model without replacing the stronger equipped gun",failures)
 var small = game.equipment.size()
 game.add_equipment(Vector3(0,0,20),"gun",5,2,false)
 game.take_equipment(small)
 game.check(profile.sizes.ak==1 and p.weapon_big[0],"small gun loot cannot downgrade the same-color large gun",failures)
 profile.add_item("armor",4)
 profile.equip("armor",4)
 game.apply_career()
 var small_capacity: float = p.max_shield()
 profile.equip("armor+",4)
 game.apply_career()
 game.check(small_capacity==375 and p.max_shield()==450 and p.shield==450,"switching armor size at the same tier updates and fills capacity",failures)
 var strongest = true
 for model in range(7):
  strongest = strongest and Gear.damage(7,0,5)>Gear.damage(model,5,5)
 game.check(strongest,"AK47M1LW ranks first even against other maximum-level guns",failures)
 game.check(Gear.damage(6,5,5)<100,"rainbow laser is balanced for sustained damage rather than single-hit kills",failures)
 profile.add_item("pants",5)
 profile.equip("pants",5)
 profile.set_pants_style(1)
 p.update_pants_equipment()
 var colored = false
 for part in p.pants.get_children():
  if part.has_meta("trousers") and part.material_override is ShaderMaterial:
   colored = true
 game.check(colored,"rainbow pants use the real animated rainbow shader",failures)
 profile.set_pants_style(2)
 p.update_pants_equipment()
 game.check(p.total_reduction()>Gear.REDUCTION[p.armor_tier],"protective shorts add real damage mitigation",failures)
 # Every initial item must be reachable and both sizes must exist at each gun color.
 var all_rarities = true
 for tier in range(6):
  for big in [false,true]:
   var found = false
   for item in game.equipment:
    if item.kind=="gun" and item.tier==tier and item.big==big:
     found = true
   all_rarities = all_rarities and found
 game.check(all_rarities,"random field contains small and large weapons of every color",failures)
 var first: Vector3 = game.expedition.random_point()
 var second: Vector3 = game.expedition.random_point()
 game.check(first!=second and game.find_path(Vector3(0,0,23),first).size()>1,"random spawn positions vary and are navigable",failures)
 # Real player grenade launch and blast against a physical enemy.
 for enemy in game.enemies:
  if is_instance_valid(enemy):
   enemy.set_physics_process(false)
   enemy.collision_layer = 0
   enemy.hp = 0
 p.position = Vector3(0,.1,23)
 p.rotation = Vector3.ZERO
 p.camera.rotation = Vector3.ZERO
 p.set_view(false,false)
 var victim = game.spawn_enemy(Vector3(0,.1,17))
 victim.set_physics_process(false)
 victim.armor_tier = 0
 victim.armor = 100
 await game.get_tree().physics_frame
 await game.get_tree().physics_frame
 var grenades_before: int = profile.grenades
 game.check(p.throw_player_grenade() and profile.grenades==grenades_before and game.grenades.back().friendly,"infinite player grenade preserves inventory and creates a friendly projectile",failures)
 var hp_before: float = victim.hp+victim.armor
 game.explode_grenade(victim.position+Vector3.UP*.5,200,true)
 game.check(victim.hp+victim.armor<hp_before,"player grenade explosion actually damages an enemy",failures)
 var boxes = game.expedition.chests.size()
 victim.take_hit(999999)
 victim.take_hit(999999)
 game.check(game.expedition.chests.size()==boxes+1,"defeated soldier creates a physical loot chest",failures)
 game.expedition.open_chest(boxes)
 game.check(not game.active and game.hud.page=="chest","opening a loot chest shows contents and pauses combat",failures)
 var balance: int = profile.credits
 var money: int = game.expedition.chests[boxes].money
 game.check(game.expedition.claim_chest() and profile.credits==balance+money,"claiming a chest grants and saves its resource reward",failures)
 balance = profile.credits
 game.check(not game.expedition.claim_chest() and profile.credits==balance,"the same chest cannot be claimed twice",failures)
 # Highest mode has twenty red soldiers plus exactly one rainbow leader.
 game.mode = "menu"
 game.active = false
 game.select_difficulty(3)
 await game.get_tree().physics_frame
 await game.get_tree().physics_frame
 var red := 0
 var bosses := 0
 var boss: Node3D = null
 for enemy in game.enemies:
  enemy.set_physics_process(false)
  if enemy.is_boss:
   bosses += 1
   boss = enemy
  elif enemy.armor_tier==game.player.armor_tier and enemy.armor_big==game.player.armor_big:
   red += 1
 game.check(red==20 and bosses==1 and game.enemies.size()==21,"super nightmare has 20 soldiers matching player armor plus one leader",failures)
 game.check(boss.armor_tier==5 and boss.weapon_tier==5 and boss.hp==999 and boss.armor==1119,"leader wears rainbow armor and maximum gun with 999 core health",failures)
 game.mode = "playing"
 game.active = true
 game.cells = 0
 await game.expedition.travel()
 game.check(game.expedition.sector==1,"portal remains locked before three energy cells",failures)
 game.cells = 3
 await game.expedition.travel()
 game.check(game.expedition.sector==1,"super-nightmare leader must be defeated before portal opens",failures)
 boss.take_hit(999999)
 boss.take_hit(999999)
 var boss_box = game.expedition.chests.size()-1
 game.expedition.open_chest(boss_box)
 var cups_before: int = profile.trophies
 game.check(game.expedition.claim_chest() and profile.trophies==cups_before+1 and 7 in profile.owned_models,"leader chest grants a World Cup trophy and AK47M1LW",failures)
 var saved_armor: int = profile.equipped.armor
 var saved_gun: int = profile.models.ak
 await game.expedition.travel()
 await game.get_tree().physics_frame
 await game.get_tree().physics_frame
 game.check(game.expedition.sector==2 and is_equal_approx(game.expedition.scale_factor*game.expedition.scale_factor,2.0),"portal loads a second technology region with exactly twice the ground area",failures)
 game.check(game.cells==0 and game.pickups.size()==3 and game.equipment.size()>=30,"second region repopulates objectives and random loot",failures)
 game.check(profile.equipped.armor==saved_armor and profile.models.ak==saved_gun,"portal preserves player equipment and weapon selection",failures)
 var q = PhysicsRayQueryParameters3D.create(Vector3(35,5,0),Vector3(35,-2,0),1)
 game.check(not game.get_world_3d().direct_space_state.intersect_ray(q).is_empty(),"expanded second-region floor has real collision beyond the first-region boundary",failures)
 var path = game.find_path(game.extraction_position,game.pickups[0].pos)
 game.check(path.size()>1 and path[path.size()-1].distance_to(Vector2(game.pickups[0].pos.x,game.pickups[0].pos.z))<2,"second-region navigation matches scaled physical coordinates",failures)
 var z_before: float = p.position.z
 Input.action_press("forward")
 for frame in range(25):
  await game.get_tree().physics_frame
 Input.action_release("forward")
 game.check(p.position.z<z_before-1 and p.is_on_floor(),"player can physically move on the second-region floor",failures)
 for enemy in game.enemies:
  enemy.set_physics_process(false)
  if enemy.is_boss:
   enemy.take_hit(999999)
   enemy.take_hit(999999)
 game.cells = 3
 await game.expedition.travel()
 game.check(game.mode=="win" and profile.wins>0,"second region completes successfully after objectives and leader",failures)
 var before_sale: int = profile.credits
 game.check(profile.sell_trophy() and profile.credits==before_sale+5000,"World Cup treasure can be sold after success",failures)
 var won: int = profile.wins
 game.resume_looting()
 game.win()
 game.check(profile.wins==won,"returning to loot after victory cannot duplicate the mission reward",failures)
 profile.save_profile()
 var restored = Career.new()
 restored.path = profile.path
 game.check(restored.load_profile() and restored.models.ak==7 and restored.items["ak+"][5]>0 and restored.equipped.pants==5,"new guns large quality and rainbow pants survive disk reload",failures)
 game.career = original
 game.active = false
 game.mode = "win"
 if FileAccess.file_exists(profile.path):
  DirAccess.remove_absolute(profile.path)
