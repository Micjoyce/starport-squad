extends RefCounted
const PRICES = [100,220,-1,1045,-1]
const SKILLS = ["跃迁冲刺","护盾修复","引力震波"]
const SKILL_COSTS = [0,250,600]
var path := "user://career.json"
var credits := 0
var items := {"armor":[1,0,0,0,0],"ak":[1,0,0,0,0],"sg":[1,0,0,0,0]}
var equipped := {"armor":0,"ak":0,"sg":0}
var skills := [true,false,false]
var green_pants := true
var wins := 0
var load_error := false

func snapshot() -> Dictionary:
 return {"version":1,"credits":credits,"items":items.duplicate(true),"equipped":equipped.duplicate(true),"skills":skills.duplicate(),"green_pants":green_pants,"wins":wins}

func restore(data: Dictionary) -> void:
 credits = clampi(int(data.get("credits",0)),0,2000000000)
 for kind in ["armor","ak","sg"]:
  var values = data.get("items",{}).get(kind,[1,0,0,0,0])
  if values is Array and values.size()==5:
   for tier in range(5):
    items[kind][tier] = clampi(int(values[tier]),0,99999)
  var tier = clampi(int(data.get("equipped",{}).get(kind,0)),0,4)
  if items[kind][tier]<=0:
   tier = 0
   items[kind][0] = maxi(1,items[kind][0])
  equipped[kind] = tier
 var unlocked = data.get("skills",[true,false,false])
 if unlocked is Array and unlocked.size()==3:
  skills = [true,bool(unlocked[1]),bool(unlocked[2])]
 green_pants = bool(data.get("green_pants",true))
 wins = maxi(0,int(data.get("wins",0)))

func load_profile() -> bool:
 if path.is_empty() or not FileAccess.file_exists(path):
  return true
 var file = FileAccess.open(path,FileAccess.READ)
 if file == null:
  load_error = true
  return false
 var parser = JSON.new()
 if parser.parse(file.get_as_text()) != OK:
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
 if file == null:
  return false
 file.store_string(JSON.stringify(snapshot()))
 file.flush()
 var status = file.get_error()
 file.close()
 if status != OK:
  return false
 return DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path)) == OK

func commit(before: Dictionary) -> bool:
 if save_profile():
  return true
 restore(before)
 return false

func add_item(kind: String, tier: int) -> bool:
 if not items.has(kind) or tier<0 or tier>4:
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
 if not items.has(kind) or tier<0 or tier>4 or items[kind][tier]<=0:
  return false
 var before = snapshot()
 equipped[kind] = tier
 return commit(before)

func can_sell(kind: String, tier: int) -> bool:
 return items.has(kind) and tier>=0 and tier<5 and PRICES[tier]>=0 and items[kind][tier]>(1 if equipped[kind]==tier else 0)

func buy(kind: String, tier: int) -> bool:
 if not items.has(kind) or tier<0 or tier>4 or PRICES[tier]<0 or credits<PRICES[tier]:
  return false
 var before = snapshot()
 credits -= PRICES[tier]
 items[kind][tier] += 1
 return commit(before)

func sell(kind: String, tier: int) -> bool:
 if not can_sell(kind,tier):
  return false
 var before = snapshot()
 items[kind][tier] -= 1
 credits += PRICES[tier]
 return commit(before)

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

func record_win(reward: int) -> bool:
 var before = snapshot()
 wins += 1
 credits += reward
 return commit(before)
