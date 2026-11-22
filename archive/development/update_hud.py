from pathlib import Path
p=Path('outputs/StarportSquad/scripts/hud.gd');s=p.read_text().replace('extends Control','extends Control\nconst Gear = preload("res://scripts/gear.gd")',1)
s=s.replace('Rect2(68,557,460,64)','Rect2(68,602,460,64)').replace('Rect2(68,457,225,56)','Rect2(68,509,225,56)').replace('Rect2(303,457,225,56)','Rect2(303,509,225,56)').replace('Rect2(68,637,222,52)','Rect2(68,680,222,52)').replace('Rect2(306,637,222,52)','Rect2(306,680,222,52)')
needle='  button("退出游戏",Rect2(306,680,222,52),func(): game.get_tree().quit())'
s=s.replace(needle,needle+'\n  for i in range(3):\n   var index = i\n   var choice = button(Gear.MODES[i],Rect2(68+i*157,405,146,44),func(): game.select_difficulty(index))\n   choice.add_theme_font_size_override("font_size",19)')
s=s.replace('Vector2(63,238),79','Vector2(63,216),75').replace('Vector2(68,313),72','Vector2(68,287),66').replace('Vector2(71,356),30','Vector2(71,327),28').replace('Vector2(68,402),20','Vector2(68,366),18').replace('txt("选择你的出发装备",Vector2(68,441),17,CYAN)','txt("选择难度",Vector2(68,393),16,CYAN)\n draw_rect(Rect2(68+game.difficulty*157,453,146,3),Gear.COLORS[4] if game.difficulty==2 else ORANGE)\n txt(Gear.DESCRIPTIONS[game.difficulty],Vector2(68,481),15,MUTED)\n txt("选择出发武器 · 白色等级",Vector2(68,500),16,CYAN)')
s=s.replace('else 303,521,225,3)','else 303,573,225,3)')
s=s.replace('txt("单人任务  /  机器人对战  /  友好难度",Vector2(68,734),18,MUTED)','txt("初始白甲 · 搜集装备 · 战胜机器人",Vector2(68,770),18,MUTED)')
s=s.replace('Vector2(68,769),20','Vector2(68,805),19').replace('PLAYABLE PROTOTYPE  /  01','GEAR & DIFFICULTY UPDATE  /  02')
s=s.replace('txt("三处能源站 · 一条回家的路",Vector2(1034,820),17,MUTED)','txt("白 → 蓝 → 紫 → 黄 → 红",Vector2(1034,820),17,MUTED)\n for i in range(5):\n  draw_rect(Rect2(1034+i*61,692,47,5),Gear.COLORS[i])')
s=s.replace('txt("OPERATION / 星港重启",Vector2(61,77),17,CYAN)','txt("星港重启 / "+Gear.MODES[game.difficulty],Vector2(61,77),17,Gear.COLORS[4] if game.difficulty==2 else CYAN)')
s=s.replace('draw_circle(radar_origin+Vector2(enemy.position.x,enemy.position.z)*rscale,2.5,ORANGE)','draw_circle(radar_origin+Vector2(enemy.position.x,enemy.position.z)*rscale,2.5,Gear.COLORS[enemy.armor_tier])')
s=s.replace(' var pp = radar_origin+',' for loot in game.equipment:\n  if not loot.taken:\n   var dot = radar_origin+Vector2(loot.pos.x,loot.pos.z)*rscale\n   draw_rect(Rect2(dot-Vector2(1.5,1.5),Vector2(3,3)),Gear.COLORS[loot.tier])\n var pp = radar_origin+')
s=s.replace('txt("护盾 / SHIELD",Vector2(60,791),16,CYAN)','txt(Gear.SHORT[p.armor_tier]+" / 盔甲",Vector2(60,791),16,Gear.COLORS[p.armor_tier])')
s=s.replace('txt("%03d" % int(p.shield),Vector2(257,794),25,WHITE,true)','txt("%d / %d" % [int(p.shield),int(p.max_shield())],Vector2(218,791),17,WHITE,true)')
s=s.replace('272*maxf(0,p.shield)/100,12),CYAN if p.shield>30 else ORANGE','272*maxf(0,p.shield)/p.max_shield(),12),Gear.COLORS[p.armor_tier]')
s=s.replace('txt("脱离攻击后自动恢复",Vector2(60,845),13,MUTED)','txt("减伤 %d%% · 脱战自动恢复" % int(Gear.REDUCTION[p.armor_tier]*100),Vector2(60,845),13,MUTED)')
s=s.replace('txt("AK47 / 轨道改装型" if p.weapon==0 else "霰弹枪 / 彗星",Vector2(1120,791),18,ORANGE)','txt(("AK47 / " if p.weapon==0 else "霰弹枪 / ")+Gear.NAMES[p.weapon_tiers[p.weapon]],Vector2(1120,791),17,Gear.COLORS[p.weapon_tiers[p.weapon]])')
s=s.replace(' elif game.cells==3 and p.position.distance_to(game.extraction_position)<4.3 and not game.extracting:', ' elif game.nearby_equipment()>=0:\n  var loot = game.equipment[game.nearby_equipment()]\n  var noun = "盔甲" if loot.kind=="armor" else "枪械"\n  var current_tier: int = p.armor_tier if loot.kind=="armor" else p.weapon_tiers[p.weapon if loot.weapon_kind<0 else loot.weapon_kind]\n  prompt("已有更高等级"+noun if loot.tier<current_tier else "E   拾取"+Gear.NAMES[loot.tier].split(" · ")[0]+noun)\n elif game.cells==3 and p.position.distance_to(game.extraction_position)<4.3 and not game.extracting:')
needle=' if game.hurt_flash>0:'
s=s.replace(needle,''' if not game.grenades.is_empty():
  var closest = null
  var closest_distance := 999.0
  for g in game.grenades:
   var distance = p.position.distance_to(g.node.position)
   if distance<closest_distance:
    closest = g
    closest_distance = distance
  if closest_distance<15:
   center("手榴弹！%.1f 秒 · 伤害 ×10 · 离开橙色圈或躲到掩体后" % closest.fuse,596,20,ORANGE)
   marker(closest.node.position+Vector3.UP*.6,"!",ORANGE)
'''+needle)
p.write_text(s)
