extends RefCounted
const PRICES = [100,220,600,1045,5000,5000]
const RAINBOW_PRICE = 10555
const SKILLS = ["跃迁冲刺","护盾修复","引力震波"]
const SKILL_COSTS = [0,250,600]
const Gear = preload("res://scripts/gear.gd")
const PACK_NAMES = ["白色背包","蓝色背包","红色背包","绿色背包"]
const PACK_COLORS = [Color("e7ebdf"),Color("499fe5"),Color("ed6666"),Color("7bc77d")]
const PACK_SLOTS = [16,32,48,64]
const PACK_COSTS = [0,300,1200,4000]
const ARMOR_ROUTE = ["白","蓝","红","紫","金","赤红","深红","绿","浅绿","淡黄绿"]
const ARMOR_ROUTE_COLORS = [Color("e7e9df"),Color("4996d5"),Color("eb6363"),Color("b87ce0"),Color("dbc467"),Color("c53940"),Color("6d2132"),Color("357e44"),Color("88bb70"),Color("d4df8c")]
const ARMOR_ROUTE_HP = [100,150,220,300,420,600,850,1200,1600,2200]
var backpack_level := 0
var tutorial_seen := false
var armor_route_level := -1
var armor_route_equipped := false
var speed_stage := 1
var squad_role := 0
var silencer := false
var chips := 0
var rate_level := 0
var mag_level := 0
var caliber := 1
var pet_kind := 0
var horse_owned := false
var pet_xp := 0
var eggs := [0,0,0,0,0,0]
var path := "user://career.json"
var operator_coat := true
var third_person := false
var castle_level := 0
const HELMETS = ["轻型头盔","钢制头盔","复合头盔","黄金头盔"]
const HELMET_COST = [0,600,1800,6500]
const HELMET_DEFENSE = [0.0,77.0,140.0,255.0]
const HELMET_HEALTH = [0.0,70.0,90.0,110.0]
var helmet := 0
var helmet_owned := [true,false,false,false]
var credits := 0
var items := {"armor":[1,0,0,0,0,0],"ak":[1,0,0,0,0,0],"sg":[1,0,0,0,0,0],"pants":[1,0,0,0,0,0],"armor+":[0,0,0,0,0,0],"ak+":[0,0,0,0,0,0],"sg+":[0,0,0,0,0,0],"pants+":[0,0,0,0,0,0]}
var equipped := {"armor":0,"ak":0,"sg":0,"pants":0}
var sizes := {"armor":0,"ak":0,"sg":0,"pants":0}
var models := {"ak":0,"sg":1}
var owned_models := [0,1,8,9,10]
var pants_style := 0
var trophies := 0
var grenades := 3
var skills := [true,false,false]
var green_pants := true
var wins := 0
var load_error := false

func snapshot() -> Dictionary:
 return {"version":8,"helmet":helmet,"helmet_owned":helmet_owned.duplicate(),"backpack_level":backpack_level,"tutorial_seen":tutorial_seen,"armor_route_level":armor_route_level,"armor_route_equipped":armor_route_equipped,"speed_stage":speed_stage,"squad_role":squad_role,"silencer":silencer,"chips":chips,"rate_level":rate_level,"mag_level":mag_level,"caliber":caliber,"pet_kind":pet_kind,"horse_owned":horse_owned,"pet_xp":pet_xp,"eggs":eggs.duplicate(),"castle_level":castle_level,"credits":credits,"items":items.duplicate(true),"equipped":equipped.duplicate(true),"skills":skills.duplicate(),"green_pants":green_pants,"wins":wins,"operator_coat":operator_coat,"third_person":third_person,"sizes":sizes.duplicate(),"models":models.duplicate(),"owned_models":owned_models.duplicate(),"pants_style":pants_style,"trophies":trophies,"grenades":grenades}

func restore(data: Dictionary) -> void:
 backpack_level = maxi(0,int(data.get("backpack_level",0)))
 tutorial_seen = bool(data.get("tutorial_seen",false))
 armor_route_level = clampi(int(data.get("armor_route_level",-1)),-1,9)
 armor_route_equipped = bool(data.get("armor_route_equipped",false)) and armor_route_level>=0
 speed_stage = clampi(int(data.get("speed_stage",1)),1,8)
 squad_role = clampi(int(data.get("squad_role",0)),0,3)
 silencer = bool(data.get("silencer",false))
 chips = clampi(int(data.get("chips",0)),0,99999)
 rate_level = clampi(int(data.get("rate_level",0)),0,3)
 mag_level = clampi(int(data.get("mag_level",0)),0,2)
 caliber = clampi(int(data.get("caliber",1)),0,4)
 horse_owned = bool(data.get("horse_owned",false))
 pet_kind = clampi(int(data.get("pet_kind",0)),-1,1)
 if pet_kind==1 and not horse_owned:
  pet_kind = 0
 pet_xp = clampi(int(data.get("pet_xp",0)),0,1000000)
 eggs = [0,0,0,0,0,0]
 var egg_data = data.get("eggs",[])
 if egg_data is Array:
  for i in range(mini(6,egg_data.size())):
   eggs[i] = clampi(int(egg_data[i]),0,99999)
 castle_level = clampi(int(data.get("castle_level",0)),0,11)
 var unlocked_helmets = data.get("helmet_owned",[])
 helmet_owned = [true,false,false,false]
 if unlocked_helmets is Array:
  for i in range(1,mini(unlocked_helmets.size(),HELMETS.size())):
   helmet_owned[i] = bool(unlocked_helmets[i])
 helmet = clampi(int(data.get("helmet",0)),0,HELMETS.size()-1)
 if not helmet_owned[helmet]: helmet = 0
 credits = clampi(int(data.get("credits",0)),0,2000000000)
 for kind in items:
  items[kind] = [0,0,0,0,0,0]
  var values = data.get("items",{}).get(kind,[])
  if values is Array:
   for tier in range(mini(values.size(),6)):
    items[kind][tier] = clampi(int(values[tier]),0,99999)
 for kind in ["armor","ak","sg","pants"]:
  var tier = clampi(int(data.get("equipped",{}).get(kind,0)),0,5)
  var size = clampi(int(data.get("sizes",{}).get(kind,0)),0,1)
  var key = kind+("+" if size==1 else "")
  if items[key][tier]<=0:
   tier = 0
   size = 0
   items[kind][0] = maxi(1,items[kind][0])
  equipped[kind] = tier
  sizes[kind] = size
 var unlocked = data.get("skills",[true,false,false])
 if unlocked is Array and unlocked.size()==3:
  skills = [true,bool(unlocked[1]),bool(unlocked[2])]
 green_pants = bool(data.get("green_pants",true))
 operator_coat = bool(data.get("operator_coat",true))
 third_person = bool(data.get("third_person",false))
 wins = maxi(0,int(data.get("wins",0)))
 owned_models = [0,1,8,9,10]
 var owned = data.get("owned_models",[0,1])
 if owned is Array:
  for value in owned:
   var model = clampi(int(value),0,Gear.MODEL_NAMES.size()-1)
   if not model in owned_models:
    owned_models.append(model)
 for slot in ["ak","sg"]:
  var model = clampi(int(data.get("models",{}).get(slot,0 if slot=="ak" else 1)),0,Gear.MODEL_NAMES.size()-1)
  models[slot] = model if model in owned_models else (0 if slot=="ak" else 1)
 pants_style = clampi(int(data.get("pants_style",0)),0,2)
 trophies = maxi(0,int(data.get("trophies",0)))
 grenades = clampi(int(data.get("grenades",3)),0,99)

func load_profile() -> bool:
 if path.is_empty() or not FileAccess.file_exists(path):
  return true
 var file = FileAccess.open(path,FileAccess.READ)
 if file==null:
  load_error = true
  return false
 var parser = JSON.new()
 if parser.parse(file.get_as_text())!=OK:
  load_error = true
  return false
 var data = parser.data
 if not data is Dictionary or not data.get("items") is Dictionary or not data.get("equipped") is Dictionary:
  load_error = true
  return false
 restore(data)
 return true

func save_profile() -> bool:
 if path.is_empty():
  return true
 if load_error:
  return false
 var file = FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file==null:
  return false
 file.store_string(JSON.stringify(snapshot()))
 file.flush()
 var status = file.get_error()
 file.close()
 return status==OK and DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))==OK

func commit(before: Dictionary) -> bool:
 if save_profile():
  return true
 restore(before)
 return false

func add_item(kind: String, tier: int) -> bool:
 if not items.has(kind) or tier<0 or tier>5:
  return false
 var before = snapshot()
 if items[kind][tier]==0 and pack_used()>=pack_capacity(): return false
 items[kind][tier] += 1
 return commit(before)

func earn(amount: int) -> bool:
 if amount<=0:
  return false
 var before = snapshot()
 credits = mini(2000000000,credits+amount)
 return commit(before)

func equip(kind: String, tier: int) -> bool:
 if not items.has(kind) or tier<0 or tier>5 or items[kind][tier]<=0:
  return false
 var before = snapshot()
 var base = kind.trim_suffix("+")
 if base=="armor": armor_route_equipped = false
 equipped[base] = tier
 sizes[base] = 1 if kind.ends_with("+") else 0
 if base=="pants":
  pants_style = 1
 return commit(before)

func can_sell(kind: String, tier: int) -> bool:
 if not items.has(kind) or tier<0 or tier>5:
  return false
 var base = kind.trim_suffix("+")
 var worn = equipped[base]==tier and sizes[base]==(1 if kind.ends_with("+") else 0)
 return items[kind][tier]>(1 if worn else 0)

func buy(kind: String, tier: int) -> bool:
 if not items.has(kind) or tier<0 or tier>5 or credits<price(kind,tier):
  return false
 var before = snapshot()
 if items[kind][tier]==0 and pack_used()>=pack_capacity(): return false
 credits -= price(kind,tier)
 items[kind][tier] += 1
 return commit(before)

func sell(kind: String, tier: int) -> bool:
 if not can_sell(kind,tier):
  return false
 var before = snapshot()
 items[kind][tier] -= 1
 credits += resale(kind,tier)
 return commit(before)

func price(kind: String, tier: int) -> int:
 if tier<0 or tier>5:
  return -1
 var base = kind.trim_suffix("+")
 var value: int = RAINBOW_PRICE if base=="armor" and tier==5 else PRICES[tier]
 if base=="pants":
  value = maxi(1,value/2)
 return value*(2 if kind.ends_with("+") else 1)

func resale(kind: String, tier: int) -> int:
 return price(kind,tier)-(1 if kind.trim_suffix("+")=="armor" and tier==5 else 0)

func unlock(index: int) -> bool:
 if index<0 or index>2 or skills[index] or credits<SKILL_COSTS[index]:
  return false
 var before = snapshot()
 credits -= SKILL_COSTS[index]
 skills[index] = true
 return commit(before)

func set_pants(enabled: bool) -> bool:
 var before = snapshot()
 green_pants = enabled
 return commit(before)

func set_pants_style(style: int) -> bool:
 var before = snapshot()
 pants_style = clampi(style,0,2)
 return commit(before)

func set_coat(enabled: bool) -> bool:
 var before = snapshot()
 operator_coat = enabled
 return commit(before)

func set_view(enabled: bool) -> bool:
 var before = snapshot()
 third_person = enabled
 return commit(before)

func record_win(reward: int) -> bool:
 var before = snapshot()
 wins += 1
 credits = mini(2000000000,credits+reward)
 return commit(before)

func select_model(slot: String, model: int) -> bool:
 if not models.has(slot) or model<0 or model>=Gear.MODEL_NAMES.size():
  return false
 var before = snapshot()
 if not model in owned_models:
  if credits<Gear.MODEL_COSTS[model]:
   return false
  credits -= Gear.MODEL_COSTS[model]
  owned_models.append(model)
 models[slot] = model
 return commit(before)

func grant_loot(payload: Array, money: int, cups: int = 0, grenades_found: int = 0, pet_eggs: Array = []) -> bool:
 var before = snapshot()
 var pending := {}
 for item in payload:
  if items.has(item.kind) and item.tier>=0 and item.tier<6 and items[item.kind][item.tier]==0:
   pending[str(item.kind)+str(item.tier)] = true
 if pack_used()+pending.size()>pack_capacity(): return false
 for item in payload:
  if items.has(item.kind) and item.tier>=0 and item.tier<6:
   items[item.kind][item.tier] += 1
  var model = int(item.get("model",-1))
  if model>=0 and model<Gear.MODEL_NAMES.size() and not model in owned_models:
   owned_models.append(model)
 for i in range(mini(6,pet_eggs.size())):
  eggs[i] = mini(99999,eggs[i]+maxi(0,int(pet_eggs[i])))
 credits += maxi(0,money)
 trophies += maxi(0,cups)
 grenades = mini(99,grenades+grenades_found)
 return commit(before)

func sell_trophy() -> bool:
 if trophies<=0 or wins<=0:
  return false
 var before = snapshot()
 trophies -= 1
 credits += 5000
 return commit(before)

func castle_cost() -> int:
 return 0 if castle_level>=11 else (castle_level+1)*1000

func upgrade_castle() -> bool:
 if castle_level>=11 or credits<castle_cost():
  return false
 var before = snapshot()
 credits -= castle_cost()
 castle_level += 1
 return commit(before)

func workshop(action: String) -> bool:
 var before = snapshot()
 var cost := 0
 match action:
  "speed_max": speed_stage = 8
  "speed_stage":
   if speed_stage>=8: return false
   speed_stage += 1
  "role": squad_role = (squad_role+1)%4
  "silencer":
   if silencer: return false
   cost = 500
   silencer = true
  "chip":
   cost = 300
   chips += 1
  "fuse":
   var needed = 1 if rate_level==0 else 2
   if rate_level>=3 or chips<needed: return false
   chips -= needed
   rate_level += 1
  "magazine":
   if mag_level>=2: return false
   cost = 400
   mag_level += 1
  "caliber": caliber = (caliber+1)%5
  "horse":
   if horse_owned: return false
   cost = 1000
   horse_owned = true
  "feed":
   cost = 50
   pet_xp = mini(1000000,pet_xp+5)
  "pet":
   pet_kind = (pet_kind+2)%3-1 if horse_owned else (-1 if pet_kind==0 else 0)
  "eggs":
   var total := 0
   for i in range(6):
    total += eggs[i]*(i+1)
    eggs[i] = 0
   if total==0: return false
   pet_xp = mini(1000000,pet_xp+total)
  _: return false
 if credits<cost:
  restore(before)
  return false
 credits -= cost
 return commit(before)

func pack_used() -> int:
 return pack_entries().size()

func pack_capacity() -> int:
 return 16*(backpack_level+1)

func pack_entries() -> Array:
 var result := []
 for kind in items:
  for tier in range(6):
   if items[kind][tier]>0:
    result.append({"kind":kind,"tier":tier,"count":items[kind][tier]})
 return result

func upgrade_pack() -> bool:
 if credits<pack_upgrade_cost(): return false
 var before = snapshot()
 credits -= pack_upgrade_cost()
 backpack_level += 1
 return commit(before)

func upgrade_armor_route() -> bool:
 if armor_route_level>=9: return false
 var cost = (armor_route_level+2)*200
 if credits<cost: return false
 var before = snapshot()
 credits -= cost
 armor_route_level += 1
 armor_route_equipped = true
 return commit(before)

func complete_tutorial() -> bool:
 var before = snapshot()
 tutorial_seen = true
 return commit(before)

func equip_helmet(index: int) -> bool:
 if index<0 or index>=HELMETS.size():
  return false
 var cost: int = 0 if helmet_owned[index] else HELMET_COST[index]
 if credits<cost:
  return false
 var before = snapshot()
 credits -= cost
 helmet_owned[index] = true
 helmet = index
 return commit(before)

func lose_carried_gear() -> bool:
 var before = snapshot()
 for slot in ["armor","ak","sg","pants"]:
  if slot=="armor" and armor_route_equipped:
   armor_route_level = -1
   equipped[slot] = 0
   sizes[slot] = 0
   continue
  var tier: int = equipped[slot]
  var key: String = slot+("+" if sizes[slot]==1 else "")
  items[key][tier] = maxi(0,items[key][tier]-1)
  items[slot][0] = maxi(1,items[slot][0])
  equipped[slot] = 0
  sizes[slot] = 0
 if helmet>0: helmet_owned[helmet] = false
 helmet = 0
 armor_route_equipped = false
 models = {"ak":0,"sg":1}
 return commit(before)

func pack_upgrade_cost() -> int:
 return PACK_COSTS[backpack_level+1] if backpack_level<3 else 4000

func sell_spares() -> bool:
 var before = snapshot()
 var total := 0
 for kind in items:
  var base = kind.trim_suffix("+")
  for tier in range(6):
   var keep = 1 if equipped[base]==tier and sizes[base]==int(kind.ends_with("+")) else 0
   var count = maxi(0,items[kind][tier]-keep)
   total += count*resale(kind,tier)
   items[kind][tier]-=count
 credits = mini(2000000000,credits+total)
 return commit(before)
