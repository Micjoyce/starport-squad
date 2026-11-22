from pathlib import Path
s=Path('outputs/StarportSquad/scripts')
p=s/'hud.gd';t=p.read_text();start=t.index(' elif page == "command":');end=t.index(' elif page == "chest":',start);t=t[:start]+''' elif page == "command":
  button("返回战场 / K",Rect2(490,733,460,50),func(): game.close_backpack(),true)
  button("守卫我方城堡 / J",Rect2(490,395,225,46),func(): game.command.set_order("defend"); show_page("command"),game.command.order=="defend").add_theme_font_size_override("font_size",18)
  button("跟随进攻 / L",Rect2(725,395,225,46),func(): game.command.set_order("attack"); show_page("command"),game.command.order=="attack").add_theme_font_size_override("font_size",18)
  button("已达最高级 · 大彩" if game.career.castle_level==11 else "升级城堡 · "+str(game.career.castle_cost())+" 金币",Rect2(490,459,460,52),func(): game.command.upgrade(); show_page("command")).disabled = game.career.castle_level==11
  button("招募十名士兵 · 1000 金币",Rect2(490,523,460,52),func(): game.command.recruit(); show_page("command")).disabled = game.command.alive_count()>0 or game.career.credits<1000
  button("切换第一 / 第三人称",Rect2(490,587,460,48),func(): game.player.set_view(not game.player.third_person); show_page("command"))
 elif page == "defeat":
  button("重新部署",Rect2(490,500,460,60),func(): game.restart(),true)
  button("退出游戏",Rect2(490,580,460,55),func(): game.get_tree().quit())
'''+t[end:]
t=t.replace('txt("队友自动跟随、攻击；全队退场后可再招募。",Vector2(490,390),17,MUTED)','txt("当前指令："+("守卫我方城堡" if game.command.order=="defend" else "跟随头领进攻"),Vector2(490,375),18,CYAN)').replace('txt("胜利奖励 1,000,000 金币",Vector2(490,425),19,ORANGE)','txt("占领敌方核心 8 秒，赢取 1,000,000 金币",Vector2(490,672),18,ORANGE)\n   txt("附近有守军时无法占领；注意我方核心警报。",Vector2(490,704),16,MUTED)')
t=t.replace('  elif page == "paused":\n   txt("MISSION PAUSED"','  elif page == "defeat":\n   txt("CASTLE LOST",Vector2(490,201),19,ORANGE,true)\n   txt("我方城堡被占领",Vector2(490,286),36)\n   txt("下次按 J 让小队驻守核心。",Vector2(490,350),22,MUTED)\n   txt("已有金币、装备和城堡等级保留。",Vector2(490,405),18,CYAN)\n  elif page == "paused":\n   txt("MISSION PAUSED"')
t=t.replace('txt("能源已送达。小小守卫，任务完成！",Vector2(490,335),21,MUTED)','txt("敌方城堡已攻下！" if game.command.capture>=8 else "能源已送达，任务完成！",Vector2(490,335),21,MUTED)').replace('txt("能源回收",Vector2(490,531),20,MUTED)','txt("城堡占领" if game.command.capture>=8 else "能源回收",Vector2(490,531),20,MUTED)').replace('txt("3 / 3",Vector2(839,534),30,WHITE,true)','txt("100%" if game.command.capture>=8 else "3 / 3",Vector2(839,534),30,WHITE,true)')
start=t.index(' # Mission card.');end=t.index(' # Compass.',start);t=t[:start]+''' # Siege mission and current squad order.
 panel(Rect2(40,45,350,145),.84)
 draw_rect(Rect2(40,45,3,145),CYAN)
 txt(("星港 / " if game.expedition.sector==1 else "科技区 / ")+Gear.MODES[game.difficulty],Vector2(61,77),17,CYAN)
 txt("攻下敌方城堡",Vector2(61,114),26)
 txt("J 守城 / L 跟随进攻 / K 招兵",Vector2(61,148),17,MUTED)
 txt(("小队驻守" if game.command.order=="defend" else "小队跟随进攻")+"  ·  "+time_string(game.elapsed),Vector2(61,177),17,CYAN)
 panel(Rect2(500,92,440,92),.82)
 txt("守军争夺中" if game.command.contested else "敌方核心 · 占领 8 秒获胜",Vector2(520,120),19,ORANGE if game.command.contested else WHITE)
 draw_rect(Rect2(520,136,400,9),Color("355366"))
 draw_rect(Rect2(520,136,400*game.command.capture/8,9),ORANGE)
 txt("占领 %d%%" % int(game.command.capture/8*100),Vector2(520,170),17,ORANGE)
 txt("我方核心 %d%% 危险" % int(game.command.enemy_capture/20*100) if game.command.enemy_capture>0 else "我方城堡安全",Vector2(715,170),16,ORANGE if game.command.enemy_capture>0 else CYAN)
'''+t[end:]
t=t.replace(' marker(game.command.castle.global_position+Vector3.UP*5,"城堡 / K",CYAN)',' marker(game.command.castle.global_position+Vector3.UP*5,"我方城堡 / J",CYAN)\n marker(game.command.enemy_castle.global_position+Vector3.UP*5,"敌方城堡 / L",ORANGE)');t=t.replace(' |  K 城堡 / 招兵  |  V 人称  |  队友 ',' |  J 守城 / L 进攻  |  V 人称  |  队友 ');p.write_text(t)
p=s/'expedition.gd';t=p.read_text().replace(' game.command.battle_started = false',' game.command.battle_started = false\n for ally in game.allies:\n  if is_instance_valid(ally) and ally.hp>0 and game.command.order=="defend":\n   ally.position = game.command.rally_point(ally)\n   ally.path_timer = 0');p.write_text(t)
