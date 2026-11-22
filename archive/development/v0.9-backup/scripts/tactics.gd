extends RefCounted
var game: Node3D
var cover_timer := 0.0
var cover_goal := Vector3.ZERO
var state := "观察战场"
func destination(bot: Node3D, target: Node3D, fallback: Vector3, dt: float) -> Vector3:
 cover_timer = maxf(0,cover_timer-dt)
 if target==null: return fallback
 var visible = game.clear_line(bot.position+Vector3.UP*1.4,target.position+Vector3.UP*1.2,target)
 if not visible: return fallback
 if bot.reload_left>0 or bot.armor<bot.max_armor()*.3:
  if cover_timer==0:
   cover_timer = 1.2
   cover_goal = game.rival.find_cover(bot,target)
   if bot.friendly and game.command.order=="defend" and cover_goal.distance_to(game.command.castle.global_position)>9:
    cover_goal = fallback
  state = "掩体换弹"
  return cover_goal
 var delta = target.position-bot.position
 delta.y = 0
 if delta.length()>4 and delta.length()<18:
  var side = Vector3(delta.z,0,-delta.x).normalized()
  var point = bot.position+side*(2.5 if int(game.elapsed/2+bot.slot)%2==0 else -2.5)
  if game.find_path(bot.position,point).size()>1:
   state = "侧移交火"
   return point
 return fallback
