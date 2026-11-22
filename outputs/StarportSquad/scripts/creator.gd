extends Node3D
const F = preload("res://scripts/factory.gd")
const Gear = preload("res://scripts/gear.gd")
const COUNTS = [10,16,27,20,39]
const KINDS = ["步枪兵 · AK47","火箭兵 · 火箭发射器","冲锋兵 · MP5","机甲 · 喷火 / 战刃","自动炮台"]
const COLORS = [Color("8798a8"),Color("558ac8"),Color("d29b60"),Color("36885c")]
var units: Array = []
var effects: Array = []
var placement := {}
var pending := 0
var fighting := false
var side := 0
var kind := 0
var batch := 1
var energy := [100,100]
var forge := [0,0]
var stage := 0
var paint := 3
var selected: Dictionary = {}
var camera: Camera3D
var status: Label
var info: Label
var kind_menu: OptionButton
var side_menu: OptionButton
var number: SpinBox
var difficulty: OptionButton
var save_name: LineEdit
var chat: LineEdit
var log_text := "离线 AI 对战已就绪。在线匹配服务器尚未连接。"
var accumulator := 0.0
var rng := RandomNumberGenerator.new()
var canvas: CanvasLayer
var panel: VBoxContainer
var world: Node3D

func _ready() -> void:
 rng.randomize()
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 world = Node3D.new()
 add_child(world)
 var env = WorldEnvironment.new()
 env.environment = Environment.new()
 env.environment.background_mode = Environment.BG_COLOR
 env.environment.background_color = Color("111f30")
 env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color = Color("bdcfe0")
 env.environment.ambient_light_energy = .8
 add_child(env)
 var sun = DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-55,-35,0)
 sun.light_energy = 1.2
 sun.shadow_enabled = true
 add_child(sun)
 camera = Camera3D.new()
 add_child(camera)
 camera.position = Vector3(57,77,70)
 camera.look_at(Vector3.ZERO)
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.size = 123
 camera.current = true
 terrain()
 build_ui()
 if "--creator-check" in OS.get_cmdline_user_args():
  call_deferred("verify")

func terrain() -> void:
 for child in world.get_children(): child.queue_free()
 var floor_material = ShaderMaterial.new()
 floor_material.shader = preload("res://scripts/deck.gdshader")
 F.box(world,Vector3(0,-.3,0),Vector3(100,.6,100),floor_material)
 var gray = F.mat(Color("3c5262"))
 var glow = F.mat(Color("eeb77e"),.4)
 for x in [-50,50]: F.box(world,Vector3(x,1.1,0),Vector3(.45,2.2,100),gray)
 for z in [-50,50]: F.box(world,Vector3(0,1.1,z),Vector3(100,2.2,.45),gray)
 for x in [-40,40]:
  for z in [-32,-15,15,32]:
   F.box(world,Vector3(x,2.1,z),Vector3(9,4.2,8),gray)
   F.box(world,Vector3(x,4.3,z),Vector3(9.5,.3,8.5),glow)
 for x in [-28,28]:
  F.text3d(world,"训练营" if x<0 else "锻造室",Vector3(x,1,38),44,Color("c9ddd9"))
  F.box(world,Vector3(x,.025,38),Vector3(15,.04,10),gray)
 if stage>0:
  for z in [-24,-8,8,24]:
   for x in [-14,14]:
    F.box(world,Vector3(x,1.8,z),Vector3(8,3.6,5),gray)
    F.box(world,Vector3(x,3.65,z),Vector3(8,.1,5),glow)

func build_ui() -> void:
 canvas = CanvasLayer.new()
 add_child(canvas)
 var top = HBoxContainer.new()
 top.position = Vector2(22,18)
 canvas.add_child(top)
 button(top,"开战 / 暂停",func(): fighting=not fighting)
 button(top,"下一境界",func(): stage+=1; fighting=false; terrain(); refresh())
 button(top,"返回主菜单",func(): get_tree().change_scene_to_file("res://main.tscn"))
 panel = VBoxContainer.new()
 panel.position = Vector2(20,76)
 panel.add_theme_constant_override("separation",9)
 canvas.add_child(panel)
 info = Label.new()
 panel.add_child(info)
 info.add_theme_font_size_override("font_size",18)
 var pick = HBoxContainer.new()
 panel.add_child(pick)
 side_menu = OptionButton.new()
 side_menu.add_item("我方")
 side_menu.add_item("敌方")
 pick.add_child(side_menu)
 kind_menu = OptionButton.new()
 for title in KINDS: kind_menu.add_item(title)
 panel.add_child(kind_menu)
 number = SpinBox.new()
 number.min_value=1
 number.max_value=1000000000
 number.allow_greater=true
 number.step=1
 number.value=1
 panel.add_child(number)
 var color = OptionButton.new()
 for name in ["灰漆","蓝漆","沙漆","绿色 · 最高级"]: color.add_item(name)
 color.selected=3
 color.item_selected.connect(func(index): paint=index)
 panel.add_child(color)
 button(panel,"士兵生成 · 选择后点击地面",func(): kind=kind_menu.selected; side=side_menu.selected; batch=int(number.value); log_text="在地面点击选择部署位置"; refresh())
 button(panel,"升级选中单位 · 10 能源",upgrade_selected)
 button(panel,"训练本方部队 · 10 能源",train_team)
 button(panel,"锻造 / 熔炼本方护甲 · 20 能源",forge_team)
 button(panel,"随机武器箱",random_weapon)
 difficulty=OptionButton.new()
 for label in ["简单 10 人","困难 16 人","噩梦 27 人","超级噩梦 20 人","超级困难 39 人"]: difficulty.add_item(label)
 panel.add_child(difficulty)
 button(panel,"AI 对手补齐难度人数",populate_enemy)
 save_name=LineEdit.new()
 save_name.placeholder_text="存档名"
 save_name.text="我的军事基地"
 panel.add_child(save_name)
 button(panel,"保存创造存档",save_world)
 button(panel,"读取创造存档",load_world)
 chat=LineEdit.new()
 chat.placeholder_text="输入情报后按回车"
 chat.text_submitted.connect(func(message): log_text=("我方" if side_menu.selected==0 else "敌方")+"情报："+message.left(100); chat.clear(); refresh())
 panel.add_child(chat)
 status=Label.new()
 status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 status.custom_minimum_size=Vector2(315,100)
 panel.add_child(status)
 button(panel,"F · 查看规则",rules)
 refresh()

func button(parent: Control, caption: String, action: Callable) -> void:
 var b=Button.new()
 b.text=caption
 b.custom_minimum_size=Vector2(0,35)
 b.pressed.connect(action)
 parent.add_child(b)

func refresh() -> void:
 if not is_instance_valid(info): return
 info.text="创造模式 · 100×100 米\n能源 %d / %d · 境界 %d\n单位 %d · 待部署 %d" % [energy[0],energy[1],stage+1,units.size(),pending]
 status.text=log_text

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_F: rules()
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  var from=camera.project_ray_origin(event.position)
  var direction=camera.project_ray_normal(event.position)
  if absf(direction.y)<.001: return
  var point=from+direction*(-from.y/direction.y)
  if absf(point.x)>48 or absf(point.z)>48: return
  selected={}
  for unit in units:
   if unit.node.position.distance_to(point)<3: selected=unit; break
  if selected.is_empty():
   pending+=batch
   placement={"position":point,"side":side,"kind":kind,"paint":paint}
  refresh()

func spawn_unit(point: Vector3, team: int, role: int, color_index: int) -> Dictionary:
 var root=Node3D.new()
 add_child(root)
 root.position=point
 var finish=F.mat(COLORS[color_index])
 var dark=F.mat(Color("1c2d39"))
 var mech=role==3
 var height=6.0 if mech else 1.7
 if role==4:
  F.cylinder(root,Vector3(0,.3,0),1.0,.6,dark)
  F.box(root,Vector3(0,1.3,0),Vector3(1.4,1.0,1.7),finish)
  F.box(root,Vector3(0,1.4,-1),Vector3(.25,.25,2),dark)
 else:
  var body=F.sphere(root,Vector3(0,height*.58,0),height*.22,finish)
  body.scale.z=.60
  F.sphere(root,Vector3(0,height*.9,0),height*.13,finish)
  for sign_value in [-1,1]:
   F.box(root,Vector3(sign_value*height*.12,height*.21,0),Vector3(height*.15,height*.4,height*.19),dark)
   F.sphere(root,Vector3(sign_value*height*.26,height*.63,0),height*.11,finish)
  if mech:
   F.box(root,Vector3(height*.33,height*.5,-.7),Vector3(.18,.14,3.8),F.mat(Color("8be6d8"),.7))
   F.cylinder(root,Vector3(-1.8,height*.5,-.25),.34,1.5,dark)
  else:
   var weapon=Gear.make_weapon(root,[0,5,4][mini(role,2)],0)
   weapon.position=Vector3(.45,1.1,-.4)
 var marker=F.cylinder(root,Vector3(0,.04,0),1.25 if mech else .55,.035,F.mat(Color("69d6d3") if team==0 else Color("ee8765"),.5))
 var health=(1600.0 if mech else 130.0)+(250 if color_index==3 and mech else 0)+forge[team]*50
 var data={"node":root,"side":team,"kind":role,"paint":color_index,"hp":health,"max_hp":health,"armor":100.0+forge[team]*40,"level":1,"cooldown":rng.randf(),"weapon":[0,5,4,0,0][role]}
 units.append(data)
 return data

func _process(dt: float) -> void:
 accumulator+=dt
 if accumulator<.1: return
 var step=accumulator
 accumulator=0
 if pending>0 and units.size()<120 and placement.has("position"):
  for i in range(mini(3,mini(pending,120-units.size()))):
   spawn_unit(placement.position+Vector3(rng.randf_range(-2,2),0,rng.randf_range(-2,2)),placement.side,placement.kind,placement.paint)
   pending-=1
 for effect in effects.duplicate():
  effect.life-=step
  if effect.life<=0:
   effect.node.queue_free()
   effects.erase(effect)
 if fighting:
  for unit in units:
   if unit.hp<=0: continue
   unit.cooldown-=step
   var target={}
   var closest=INF
   for other in units:
    if other.side==unit.side or other.hp<=0: continue
    var distance=unit.node.position.distance_to(other.node.position)
    if distance<closest: closest=distance; target=other
   if target.is_empty(): continue
   var reach=18.0 if unit.kind==3 else 30.0
   if closest>reach and unit.kind!=4:
    var motion=(target.node.position-unit.node.position).normalized()*step*(2.5 if unit.kind==3 else 4)
    var proposed=unit.node.position+motion
    if stage>0 and absf(proposed.x)>9 and absf(proposed.x)<19:
     proposed.x=move_toward(unit.node.position.x,0,step*4)
    unit.node.position=proposed
   elif unit.cooldown<=0:
    unit.cooldown=.7 if unit.kind==3 else .48
    strike(unit,target,closest)
  for unit in units.duplicate():
   if unit.hp<=0:
    energy[1-unit.side]+=5
    unit.node.queue_free()
    units.erase(unit)
 refresh()

func strike(attacker: Dictionary, target: Dictionary, distance: float) -> void:
 var start: Vector3=attacker.node.position+Vector3.UP*(3.2 if attacker.kind==3 else 1.2)
 var end: Vector3=target.node.position+Vector3.UP
 var flame=attacker.kind==3 and distance>4
 var material=F.mat(Color("ff944c") if flame else Color("8de8ed"),1.0)
 var beam=F.box(self,(start+end)*.5,Vector3(.34 if flame else .06,.20 if flame else .06,start.distance_to(end)),material)
 if start.distance_to(end)>.01: beam.look_at(end)
 effects.append({"node":beam,"life":.2})
 var base=Gear.damage(attacker.weapon,0,distance) if attacker.kind<3 else (130.0 if attacker.kind==3 else 55.0)
 var power=base*attacker.level
 var absorbed=minf(target.armor,power)
 target.armor-=absorbed
 target.hp-=power-absorbed

func upgrade_selected() -> void:
 if not selected.has("node"): log_text="先点击一个单位"; refresh(); return
 var team: int=selected.side
 if energy[team]<10: return
 energy[team]-=10
 selected.level+=1
 selected.max_hp+=50
 selected.hp+=50
 selected.armor+=30
 refresh()

func train_team() -> void:
 var team=side_menu.selected
 if energy[team]<10: return
 energy[team]-=10
 for unit in units:
  if unit.side==team: unit.level+=1
 log_text="训练完成，本方单位伤害等级提升"
 refresh()

func forge_team() -> void:
 var team=side_menu.selected
 if energy[team]<20: return
 energy[team]-=20
 forge[team]+=1
 for unit in units:
  if unit.side==team: unit.armor+=40
 log_text="护甲已熔炼强化"
 refresh()

func random_weapon() -> void:
 if not selected.has("node") or selected.kind>2: return
 selected.weapon=rng.randi_range(0,Gear.MODEL_NAMES.size()-1)
 log_text="获得武器："+Gear.MODEL_NAMES[selected.weapon]
 var old=selected.node.get_node_or_null("DrawnWeapon")
 if old!=null: old.queue_free()
 var weapon=Gear.make_weapon(selected.node,selected.weapon,0)
 weapon.name="DrawnWeapon"
 weapon.position=Vector3(-.4,1,-.4)
 refresh()

func populate_enemy() -> void:
 side=1
 kind=0
 paint=mini(3,difficulty.selected)
 batch=COUNTS[difficulty.selected]
 placement={"position":Vector3(0,0,-26),"side":1,"kind":0,"paint":paint}
 pending+=batch
 spawn_unit(Vector3(0,0,-32),1,3,3)
 spawn_unit(Vector3(0,0,30),0,3,3)
 log_text="已安排 AI 敌人和双方机甲"
 refresh()

func rules() -> void:
 log_text="点击地面部署，点击单位选中。开战后自动交战。机甲近战挥砍、远处喷火。训练与锻造消耗本方能源，击败单位获得能源。F 查看规则。画面最多 120 个单位，其余排队。在线服务器未连接，当前为离线 AI。"
 refresh()

func file_path() -> String:
 return "user://creator_"+save_name.text.validate_filename().left(40)+".json"

func save_world() -> void:
 var records=[]
 for unit in units:
  records.append({"x":unit.node.position.x,"z":unit.node.position.z,"side":unit.side,"kind":unit.kind,"paint":unit.paint,"hp":unit.hp,"max_hp":unit.max_hp,"armor":unit.armor,"level":unit.level,"weapon":unit.weapon})
 var data={"version":1,"units":records,"energy":energy,"forge":forge,"stage":stage}
 var file=FileAccess.open(file_path()+".tmp",FileAccess.WRITE)
 if file==null: log_text="保存失败"; refresh(); return
 file.store_string(JSON.stringify(data))
 file.close()
 var ok=DirAccess.rename_absolute(ProjectSettings.globalize_path(file_path()+".tmp"),ProjectSettings.globalize_path(file_path()))==OK
 log_text="存档已保存" if ok else "保存失败"
 refresh()

func load_world() -> void:
 if not FileAccess.file_exists(file_path()): log_text="未找到存档"; refresh(); return
 var data=JSON.parse_string(FileAccess.get_file_as_string(file_path()))
 if not data is Dictionary or not data.get("units") is Array: return
 if data.units.size()>120: return
 for record in data.units:
  if not record is Dictionary or not record.has_all(["x","z","side","kind","paint","hp","max_hp","armor","level","weapon"]): return
 fighting=false
 pending=0
 selected={}
 for unit in units: unit.node.queue_free()
 units.clear()
 stage=maxi(0,int(data.get("stage",0)))
 energy=[100,100]
 forge=[0,0]
 if data.get("energy") is Array and data.energy.size()==2: energy=data.energy
 if data.get("forge") is Array and data.forge.size()==2: forge=data.forge
 terrain()
 for record in data.units:
  var unit=spawn_unit(Vector3(clampf(record.x,-48,48),0,clampf(record.z,-48,48)),clampi(record.side,0,1),clampi(record.kind,0,4),clampi(record.paint,0,3))
  for key in ["hp","max_hp","armor","level","weapon"]: unit[key]=record[key]
 log_text="存档已读取"
 refresh()

func verify() -> void:
 var a=spawn_unit(Vector3(0,0,0),0,3,3)
 var b=spawn_unit(Vector3(0,0,-3),1,0,0)
 strike(a,b,3)
 assert(b.armor<100)
 selected=a
 upgrade_selected()
 assert(a.level==2)
 forge_team()
 assert(forge[0]==1)
 save_name.text="自动检查"
 save_world()
 var count=units.size()
 load_world()
 assert(units.size()==count)
 DirAccess.remove_absolute(file_path())
 print("CREATOR CHECKS PASSED")
 get_tree().quit()
