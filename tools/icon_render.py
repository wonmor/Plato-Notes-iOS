# Plato app icon render (Blender 3.6, Eevee). A note dissolving into embers and ash.
# Usage: blender -b -P tools/icon_render.py -- <variant a|b|c> out.png [size]
import bpy, bmesh, math, random, sys
from mathutils import Vector, noise
argv = sys.argv[sys.argv.index('--') + 1:]
variant, out = argv[0], argv[1]
size = int(argv[2]) if len(argv) > 2 else 1024
random.seed({'a': 11, 'b': 23, 'c': 5}[variant])

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = 'BLENDER_EEVEE'
ee = sc.eevee
ee.taa_render_samples = 96
ee.use_bloom = True; ee.bloom_intensity = 0.12; ee.bloom_threshold = 0.85; ee.bloom_radius = 5.5; ee.bloom_color = (1.0, 0.75, 0.6)
ee.use_gtao = True; ee.gtao_distance = 0.4
ee.use_soft_shadows = True
ee.volumetric_start = 1; ee.volumetric_end = 30; ee.volumetric_tile_size = '4'
sc.render.resolution_x = sc.render.resolution_y = size
sc.render.film_transparent = False
sc.view_settings.view_transform = 'Filmic'; sc.view_settings.look = 'High Contrast'
sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGB'

# World: charcoal with a thin warm haze
w = bpy.data.worlds.new('W'); sc.world = w; w.use_nodes = True
nt = w.node_tree; bg = nt.nodes['Background']
bg.inputs[0].default_value = (0.0045, 0.0042, 0.004, 1); bg.inputs[1].default_value = 1
vol = nt.nodes.new('ShaderNodeVolumePrincipled'); vol.inputs['Density'].default_value = 0.012
vol.inputs['Color'].default_value = (1.0, 0.6, 0.45, 1)
nt.links.new(vol.outputs[0], nt.nodes['World Output'].inputs['Volume'])

def mat(name, base, emit=None, estr=0.0, rough=0.6, sss=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    p = m.node_tree.nodes['Principled BSDF']
    p.inputs['Base Color'].default_value = (*base, 1)
    p.inputs['Roughness'].default_value = rough
    p.inputs['Specular'].default_value = 0.3
    if sss:
        p.inputs['Subsurface'].default_value = sss
        p.inputs['Subsurface Color'].default_value = (1.0, 0.85, 0.7, 1)
        p.inputs['Subsurface Radius'].default_value = (0.02, 0.012, 0.008)
    if emit:
        p.inputs['Emission'].default_value = (*emit, 1); p.inputs['Emission Strength'].default_value = estr
    return m

PAPER = mat('paper', (0.86, 0.83, 0.77), rough=0.75, sss=0.25)
def rule_paper(m):
    # faint ruled lines and a vermilion margin rule, in object space, so the sheet reads as a note
    n = m.node_tree.nodes; L = m.node_tree.links
    p = n['Principled BSDF']
    tc = n.new('ShaderNodeTexCoord'); sx = n.new('ShaderNodeSeparateXYZ'); L.new(tc.outputs['Object'], sx.inputs[0])
    def math(op, a, b=None):
        k = n.new('ShaderNodeMath'); k.operation = op
        (L.new(a, k.inputs[0]) if not isinstance(a, float) else k.inputs[0].__setattr__('default_value', a))
        if b is not None:
            (L.new(b, k.inputs[1]) if not isinstance(b, float) else k.inputs[1].__setattr__('default_value', b))
        return k.outputs[0]
    # ruled lines parallel to the red header rule; the strip above the rule stays blank
    lines = math('LESS_THAN', math('FRACT', math('MULTIPLY', sx.outputs['X'], 14.0)), 0.07)
    lines = math('MULTIPLY', lines, math('GREATER_THAN', sx.outputs['X'], -0.29))
    margin = math('MULTIPLY', math('GREATER_THAN', sx.outputs['X'], -0.335), math('LESS_THAN', sx.outputs['X'], -0.318))
    m1 = n.new('ShaderNodeMixRGB'); m1.inputs[1].default_value = (0.86, 0.83, 0.77, 1); m1.inputs[2].default_value = (0.42, 0.46, 0.55, 1)
    L.new(math('MULTIPLY', lines, 0.55), m1.inputs[0])
    m2 = n.new('ShaderNodeMixRGB'); L.new(m1.outputs[0], m2.inputs[1]); m2.inputs[2].default_value = (0.85, 0.16, 0.06, 1)
    L.new(margin, m2.inputs[0]); L.new(m2.outputs[0], p.inputs['Base Color'])
rule_paper(PAPER)
CHAR = mat('char', (0.03, 0.025, 0.02), rough=0.9)
EMBER = mat('ember', (1.0, 0.3, 0.08), (1.0, 0.28, 0.06), 14.0)
EMBER_HOT = mat('emberhot', (1.0, 0.7, 0.3), (1.0, 0.62, 0.25), 30.0)
EMBER_DIM = mat('emberdim', (0.8, 0.15, 0.04), (1.0, 0.18, 0.04), 4.0)
ASH = mat('ash', (0.35, 0.33, 0.31), rough=0.9)
ASH_LIGHT = mat('ashlight', (0.7, 0.67, 0.62), rough=0.85, sss=0.1)

# ---- The note: a subdivided sheet, curled, dissolving along a noisy front ----
W_, H_ = 1.0, 1.32
nx, ny = 240, 316
bpy.ops.mesh.primitive_grid_add(x_subdivisions=nx, y_subdivisions=ny, size=1)
sheet = bpy.context.object
sheet.scale = (W_, H_, 1); bpy.ops.object.transform_apply(scale=True)
me = sheet.data
bm = bmesh.new(); bm.from_mesh(me)
bm.faces.ensure_lookup_table()

# dissolve direction: top-right corner goes first
front = {'a': 0.30, 'b': 0.18, 'c': 0.36}[variant]
band = 0.03
def field(p):
    # diagonal coordinate (0 lower-left .. ~1 upper-right) plus noise for a ragged edge
    d = (p.x / W_ + 0.5) * 0.55 + (p.y / H_ + 0.5) * 0.45
    n = noise.noise(Vector((p.x * 3.2, p.y * 3.2, 0.7))) * 0.10 + noise.noise(Vector((p.x * 11, p.y * 11, 2.1))) * 0.03
    return d + n

dissolve_pts = []
char_faces, ember_faces, ember_hot, kill = [], [], [], []
edge = 1.0 - front
for f in bm.faces:
    c = f.calc_center_median()
    t = field(c)
    if t > edge:
        kill.append(f)
        if random.random() < 0.025:
            dissolve_pts.append((c.copy(), t - edge))
    elif t > edge - band * 0.45:
        ember_hot.append(f) if random.random() < 0.5 else ember_faces.append(f)
    elif t > edge - band:
        ember_faces.append(f)
    elif t > edge - band * 4.0 - noise.noise(Vector((c.x * 9, c.y * 9, 5.0))) * 0.03:
        char_faces.append(f)

mats = [PAPER, CHAR, EMBER, EMBER_HOT]
for m in mats: me.materials.append(m)
for f in char_faces: f.material_index = 1
for f in ember_faces: f.material_index = 2
for f in ember_hot: f.material_index = 3
bmesh.ops.delete(bm, geom=kill, context='FACES')

# curl: the burning edge lifts and the sheet bows a little
curl = {'a': 0.22, 'b': 0.16, 'c': 0.42}[variant]
for v in bm.verts:
    t = (v.co.x / W_ + 0.5) * 0.55 + (v.co.y / H_ + 0.5) * 0.45     # smooth, so the curl has no lumps
    lift = max(0.0, t - (edge - 0.3)) / 0.3
    v.co.z += curl * lift ** 2 * 0.6 + 0.02 * math.sin(v.co.x * 2.4) + noise.noise(v.co * 2.5) * 0.003
bm.to_mesh(me); bm.free()
for p in me.polygons: p.use_smooth = True
sol = sheet.modifiers.new('thick', 'SOLIDIFY'); sol.thickness = 0.004

rot = {'a': (math.radians(-8), math.radians(4), math.radians(-24)),
       'b': (math.radians(-18), math.radians(6), math.radians(-30)),
       'c': (math.radians(-4), math.radians(-6), math.radians(-18))}[variant]
sheet.rotation_euler = rot
sheet.location = {'a': (-0.10, -0.06, 0), 'b': (-0.22, -0.20, 0), 'c': (-0.08, -0.10, 0)}[variant]
bpy.context.view_layer.update()
M = sheet.matrix_world.copy()

# ---- Particles: embers near the edge, ash further out, drifting up and to the right ----
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1)
ember_mesh = bpy.context.object.data; bpy.ops.object.shade_smooth(); bpy.data.objects.remove(bpy.context.object)
bpy.ops.mesh.primitive_plane_add(size=1)
flake_mesh = bpy.context.object.data; bpy.data.objects.remove(bpy.context.object)

def spawn(mesh, m, loc, s, rotz=None):
    o = bpy.data.objects.new('p', mesh); o.location = loc
    o.scale = s if isinstance(s, tuple) else (s, s, s)
    o.rotation_euler = (random.uniform(0, 6.3), random.uniform(0, 6.3), random.uniform(0, 6.3)) if rotz is None else rotz
    bpy.context.collection.objects.link(o)
    o.data.materials.clear() if False else None
    if not o.material_slots: mesh.materials.append(None)
    o.material_slots[0].link = 'OBJECT'; o.material_slots[0].material = m

drift = Vector({'a': (0.55, 0.85, 0.35), 'b': (0.6, 0.8, 0.45), 'c': (0.45, 0.9, 0.5)}[variant]).normalized()
count = {'a': 800, 'b': 650, 'c': 700}[variant]
ash_bias = {'a': 0.45, 'b': 0.35, 'c': 0.6}[variant]
for i in range(count):
    if not dissolve_pts: break
    c, depth = random.choice(dissolve_pts)
    travel = random.expovariate(3.2) * 0.9 + depth * 0.6
    jitter = Vector((random.gauss(0, 0.05), random.gauss(0, 0.05), random.gauss(0, 0.05))) * (1 + travel * 3)
    local = c + jitter
    world = M @ local + drift * travel + Vector((0, 0, travel * travel * 0.25))
    fade = min(1.0, travel / 0.8)
    if random.random() < ash_bias * (0.4 + fade):
        s = random.uniform(0.006, 0.018) * (1 - 0.5 * fade)
        spawn(flake_mesh, ASH_LIGHT if random.random() < 0.4 else ASH, world, (s * random.uniform(0.6, 1.4), s, s))
    else:
        s = random.uniform(0.0025, 0.009) * (1 - 0.55 * fade)
        r = random.random()
        m = EMBER_HOT if r < 0.18 and travel < 0.25 else (EMBER if r < 0.7 else EMBER_DIM)
        spawn(ember_mesh, m, world, s)

# ---- Lights ----
def light(name, kind, loc, energy, color, size=2, target=None):
    l = bpy.data.lights.new(name, kind); l.energy = energy; l.color = color
    if kind == 'AREA': l.size = size
    if kind == 'POINT': l.shadow_soft_size = size
    l.volume_factor = 0.3
    o = bpy.data.objects.new(name, l); o.location = loc; bpy.context.collection.objects.link(o)
    if target is not None:
        c = o.constraints.new('TRACK_TO'); c.target = target; c.track_axis = 'TRACK_NEGATIVE_Z'; c.up_axis = 'UP_Y'
    return o

# burning-edge centre in world space
edge_pts = [M @ c for c, d in dissolve_pts if d < 0.06] or [M @ Vector((0.3, 0.4, 0))]
ec = sum(edge_pts, Vector()) / len(edge_pts)
tgt = bpy.data.objects.new('tgt', None); tgt.location = (0, 0, 0); bpy.context.collection.objects.link(tgt)
light('key', 'AREA', (-1.8, -1.6, 2.6), 32, (0.85, 0.9, 1.0), 1.6, tgt)       # cool soft key from upper left
light('rim', 'AREA', (1.6, 2.2, 0.9), 90, (0.55, 0.65, 1.0), 1.2, tgt)        # cool rim behind
light('fire', 'POINT', ec + Vector((0.05, 0.05, 0.12)), 45, (1.0, 0.36, 0.1), 0.15)
light('fire2', 'POINT', ec + Vector((0.2, 0.25, 0.3)), 18, (1.0, 0.5, 0.15), 0.3)

# ---- Camera ----
cam_d = bpy.data.cameras.new('cam'); cam = bpy.data.objects.new('cam', cam_d)
bpy.context.collection.objects.link(cam); sc.camera = cam
look = bpy.data.objects.new('look', None); bpy.context.collection.objects.link(look)
c = cam.constraints.new('TRACK_TO'); c.target = look; c.track_axis = 'TRACK_NEGATIVE_Z'; c.up_axis = 'UP_Y'
focus = bpy.data.objects.new('focus', None); focus.location = ec; bpy.context.collection.objects.link(focus)
cam_d.dof.use_dof = True; cam_d.dof.focus_object = focus
if variant == 'a':
    cam.location = (0.3, -1.75, 2.7); look.location = (0.04, 0.10, 0.08); cam_d.lens = 44; cam_d.dof.aperture_fstop = 2.0
elif variant == 'b':
    cam.location = (0.8, -1.25, 1.35); look.location = (0.06, 0.08, 0.08); cam_d.lens = 54; cam_d.dof.aperture_fstop = 1.4
else:
    cam.location = (0.35, -2.1, 1.75); look.location = (0.04, 0.08, 0.14); cam_d.lens = 42; cam_d.dof.aperture_fstop = 1.8

sc.render.filepath = out
bpy.ops.render.render(write_still=True)
