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
