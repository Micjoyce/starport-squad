extends SceneTree
func _initialize():
 var f = load("res://assets/NotoSansSC.ttf")
 print(f.get_supported_variation_list())
 var v = FontVariation.new()
 v.base_font = f
 v.variation_opentype = {"wght":550.0}
 print(v.variation_opentype)
 quit()
