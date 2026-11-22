extends RefCounted

static func mat(color: Color, glow: float = 0.0) -> StandardMaterial3D:
 var m = StandardMaterial3D.new()
 m.albedo_color = color.srgb_to_linear().lerp(color,0.3)
 m.roughness = 0.7
 m.metallic = 0.15
 if glow > 0.0:
  m.emission_enabled = true
  m.emission = color
  m.emission_energy_multiplier = glow
 return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, material: Material, solid: bool = false) -> MeshInstance3D:
 var mesh = MeshInstance3D.new()
 var b = BoxMesh.new()
 b.size = size
 mesh.mesh = b
 mesh.material_override = material
 parent.add_child(mesh)
 mesh.position = pos
 if solid:
  var body = StaticBody3D.new()
  var shape = CollisionShape3D.new()
  var s = BoxShape3D.new()
  s.size = size
  shape.shape = s
  body.add_child(shape)
  mesh.add_child(body)
 return mesh

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, material: Material, sides: int = 16) -> MeshInstance3D:
 var mesh = MeshInstance3D.new()
 var c = CylinderMesh.new()
 c.top_radius = radius
 c.bottom_radius = radius
 c.height = height
 c.radial_segments = sides
 mesh.mesh = c
 mesh.material_override = material
 parent.add_child(mesh)
 mesh.position = pos
 return mesh

static func sphere(parent: Node3D, pos: Vector3, radius: float, material: Material) -> MeshInstance3D:
 var mesh = MeshInstance3D.new()
 var s = SphereMesh.new()
 s.radius = radius
 s.height = radius * 2.0
 s.radial_segments = 12
 s.rings = 6
 mesh.mesh = s
 mesh.material_override = material
 parent.add_child(mesh)
 mesh.position = pos
 return mesh

static func text3d(parent: Node3D, value: String, pos: Vector3, size: int, color: Color = Color.WHITE) -> Label3D:
 var label = Label3D.new()
 label.text = value
 label.font_size = size
 label.pixel_size = 0.012
 label.modulate = color
 label.outline_size = 0
 parent.add_child(label)
 label.position = pos
 return label

static func batch_meshes(parent: Node3D) -> void:
 var groups := {}
 for child in parent.get_children():
  if child is MeshInstance3D and child.mesh and not child.has_meta("dynamic"):
   var material = child.material_override
   var key = material.get_instance_id()
   if not groups.has(key):
    groups[key] = {"surface":SurfaceTool.new(),"material":material,"meshes":[]}
    groups[key].surface.begin(Mesh.PRIMITIVE_TRIANGLES)
   groups[key].surface.append_from(child.mesh,0,child.transform)
   groups[key].meshes.append(child)
 for key in groups:
  var group = groups[key]
  var combined = MeshInstance3D.new()
  combined.mesh = group.surface.commit()
  combined.material_override = group.material
  parent.add_child(combined)
  for old in group.meshes:
   for nested in old.get_children():
    nested.reparent(parent,true)
   parent.remove_child(old)
   old.queue_free()
