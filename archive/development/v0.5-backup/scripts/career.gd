extends RefCounted
const PRICES = [100,220,600,1045,5000,5000]
const RAINBOW_PRICE = 10555
const SKILLS = ["跃迁冲刺","护盾修复","引力震波"]
const SKILL_COSTS = [0,250,600]
const Gear = preload("res://scripts/gear.gd")
var path := "user://career.json"
var operator_coat := true
var third_person := false
var credits := 0
var items := {"armor":[1,0,0,0,0,0],"ak":[1,0,0,0,0,0],"sg":[1,0,0,0,0,0],"pants":[1,0,0,0,0,0],"armor+":[0,0,0,0,0,0],"ak+":[0,0,0,0,0,0],"sg+":[0,0,0,0,0,0],"pants+":[0,0,0,0,0,0]}
var equipped := {"armor":0,"ak":0,"sg":0,"pants":0}
var sizes := {"armor":0,"ak":0,"sg":0,"pants":0}
var models := {"ak":0,"sg":1}
var owned_models := [0,1]
var pants_style := 0
var trophies := 0
var grenades := 3
var skills := [true,false,false]
var green_pants := true
var wins := 0
var load_error := false

func snapshot() -> Dictionary:
 return {"version":3,"credits":credits,"items":items.duplicate(true),"equipped":equipped.duplicate(true),"skills":skills.duplicate(),"green_pants":green_pants,"wins":wins,"operator_coat":operator_coat,"third_person":third_person,"sizes":sizes.duplicate(),"models":models.duplicate(),"owned_models":owned_models.duplicate(),"pants_style":pants_style,"trophies":trophies,"grenades":grenades}

func restore(data: Dictionary) -> void:
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
 owned_models = [0,1]
 var owned = data.get("owned_models",[0,1])
 if owned is Array:
  for value in owned:
   var model = clampi(int(value),0,7)
   if not model in owned_models:
    owned_models.append(model)
 for slot in ["ak","sg"]:
  var model = clampi(int(data.get("models",{}).get(slot,0 if slot=="ak" else 1)),0,7)
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
 credits += reward
 return commit(before)

func select_model(slot: String, model: int) -> bool:
 if not models.has(slot) or model<0 or model>7:
  return false
 var before = snapshot()
 if not model in owned_models:
  if credits<Gear.MODEL_COSTS[model]:
   return false
  credits -= Gear.MODEL_COSTS[model]
  owned_models.append(model)
 models[slot] = model
 return commit(before)

func grant_loot(payload: Array, money: int, cups: int = 0, grenades_found: int = 0) -> bool:
 var before = snapshot()
 for item in payload:
  if items.has(item.kind) and item.tier>=0 and item.tier<6:
   items[item.kind][item.tier] += 1
  var model = int(item.get("model",-1))
  if model>=0 and model<8 and not model in owned_models:
   owned_models.append(model)
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
