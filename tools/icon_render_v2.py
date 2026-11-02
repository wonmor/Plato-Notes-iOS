# Plato app icon v2 (Blender 3.6, Eevee). Plato's own metaphor from the Theaetetus:
# memory as a wax tablet. Abstract incised writing smooths away toward one edge.
# Usage: blender -b -P tools/icon_render_v2.py -- <variant a|b|c> out.png [size]
#   a  wax tablet (tabula cerata) with a bronze stylus, on a warm honey-lit ground (shipped)
#   b  the same tablet on charcoal, candle-lit
#   c  open parchment codex, ink lines lifting off as fine mist
import bpy, math, random, sys
import numpy as np
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index('--') + 1:]
variant, out = argv[0], argv[1]
size = int(argv[2]) if len(argv) > 2 else 1024
random.seed({'a': 3, 'b': 3, 'c': 8}[variant]); np.random.seed(4)

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = 'BLENDER_EEVEE'
ee = sc.eevee
ee.taa_render_samples = 128
ee.use_bloom = True; ee.bloom_intensity = 0.03; ee.bloom_threshold = 1.2; ee.bloom_radius = 5
ee.use_gtao = True; ee.gtao_distance = 0.15; ee.gtao_factor = 1.2
ee.use_ssr = True
ee.use_soft_shadows = True
ee.shadow_cube_size = '2048'; ee.shadow_cascade_size = '2048'
ee.volumetric_start = 0.5; ee.volumetric_end = 12; ee.volumetric_tile_size = '2'
sc.render.resolution_x = sc.render.resolution_y = size
sc.render.film_transparent = False
sc.view_settings.view_transform = 'Filmic'; sc.view_settings.look = 'Medium High Contrast'
sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGB'

w = bpy.data.worlds.new('W'); sc.world = w; w.use_nodes = True
wn = w.node_tree; bg = wn.nodes['Background']
bg.inputs[0].default_value = (0.0035, 0.0032, 0.003, 1); bg.inputs[1].default_value = 1
vol = wn.nodes.new('ShaderNodeVolumePrincipled'); vol.inputs['Density'].default_value = 0.035
vol.inputs['Color'].default_value = (1.0, 0.85, 0.7, 1)
wn.links.new(vol.outputs[0], wn.nodes['World Output'].inputs['Volume'])

# ---------- helpers ----------
def principled(name, base, rough=0.5, metal=0.0, sss=0.0, sss_col=None, spec=0.4):
    m = bpy.data.materials.new(name); m.use_nodes = True
    p = m.node_tree.nodes['Principled BSDF']
    p.inputs['Base Color'].default_value = (*base, 1)
    p.inputs['Roughness'].default_value = rough
    p.inputs['Metallic'].default_value = metal
    p.inputs['Specular'].default_value = spec
    if sss:
        p.inputs['Subsurface'].default_value = sss
        p.inputs['Subsurface Color'].default_value = (*(sss_col or base), 1)
        p.inputs['Subsurface Radius'].default_value = (0.012, 0.006, 0.003)
    return m

def nodes(m):
    return m.node_tree.nodes, m.node_tree.links, m.node_tree.nodes['Principled BSDF']

def link_obj(o):
    bpy.context.collection.objects.link(o); return o

def set_mat(o, m):
    o.data.materials.clear(); o.data.materials.append(m)

def strokes_map(W, H, rows, fade_from, fade_to, x0=0.08, x1=0.92, y0=0.14, y1=0.86, width=2.2, seed=1, blur_grow=3.0):
    """Abstract looped 'writing' (no letters) rasterised as two maps: groove depth and a raised lip.
    Strength and sharpness fall off between u = fade_from and u = fade_to (u in 0..1 across the width)."""
    rng = random.Random(seed)
    groove = np.zeros((H, W), np.float32); lip = np.zeros((H, W), np.float32)
    def fade(u):
        t = min(1, max(0, (u - fade_from) / max(1e-6, fade_to - fade_from)))
        return 1 - t * t * (3 - 2 * t)
    def stamp(px, py, wpx, a):
        r = int(wpx * 3.2) + 2
        xa, xb = max(0, int(px) - r), min(W, int(px) + r + 1)
        ya, yb = max(0, int(py) - r), min(H, int(py) + r + 1)
        if xa >= xb or ya >= yb: return
        xs = np.arange(xa, xb)[None, :] - px; ys = np.arange(ya, yb)[:, None] - py
        d2 = xs * xs + ys * ys
        g = a * np.exp(-d2 / (wpx * wpx)); l = a * np.exp(-d2 / ((wpx * 2.4) ** 2))
        np.maximum(groove[ya:yb, xa:xb], g, out=groove[ya:yb, xa:xb])
        np.maximum(lip[ya:yb, xa:xb], l, out=lip[ya:yb, xa:xb])
    dy = (y1 - y0) / rows
    for r in range(rows):
        base = y0 + (r + 0.6) * dy
        x = x0 + rng.uniform(0, 0.03)
        end = x1 - rng.uniform(0, 0.18) if r < rows - 1 else x0 + rng.uniform(0.3, 0.5)
        while x < end:
            L = rng.uniform(0.05, 0.16)
            L = min(L, end - x)
            if L < 0.02: break
            loops = max(2, int(L / rng.uniform(0.013, 0.02)))
            amp = dy * rng.uniform(0.16, 0.26)
            n = int(L * W * 1.6) + 8
            ph = rng.uniform(0, 6.28)
            for i in range(n):
                t = i / (n - 1)
                om = loops * 2 * math.pi * t
                u = x + L * t + 0.12 * (L / loops) * math.cos(om + ph)
                v = base - amp * (0.55 * math.sin(om + ph) + 0.45 * math.sin(0.5 * om + 1.3 * ph))
                f = fade(u)
                if f <= 0.01: continue
                wpx = width * (1 + blur_grow * (1 - f))
                stamp(u * W, v * H, wpx, f ** 1.6)
            x += L + rng.uniform(0.02, 0.04)
    return groove, lip

def to_image(name, arr):
    H, W = arr.shape
    img = bpy.data.images.new(name, W, H, float_buffer=True, alpha=False)
    rgba = np.ones((H, W, 4), np.float32)
    a = arr[::-1, :]   # image rows go bottom-up in Blender
    rgba[..., 0] = a; rgba[..., 1] = a; rgba[..., 2] = a
    img.pixels.foreach_set(rgba.ravel())
    img.pack()
    return img

def img_node(m, img):
    n, L, p = nodes(m)
    t = n.new('ShaderNodeTexImage'); t.image = img; t.interpolation = 'Cubic'
    t.image.colorspace_settings.name = 'Non-Color'
    return t

def light(name, kind, loc, energy, color, size=0.3, target=None, spot=None, vol=1.0):
    l = bpy.data.lights.new(name, kind); l.energy = energy; l.color = color
    if kind == 'AREA': l.size = size
    else: l.shadow_soft_size = size
    if spot: l.spot_size = math.radians(spot); l.spot_blend = 0.6
    l.volume_factor = vol
    o = link_obj(bpy.data.objects.new(name, l)); o.location = loc
    if target is not None:
        c = o.constraints.new('TRACK_TO'); c.target = target; c.track_axis = 'TRACK_NEGATIVE_Z'; c.up_axis = 'UP_Y'
    return o

def empty(name, loc):
    o = link_obj(bpy.data.objects.new(name, None)); o.location = loc; return o

def camera(loc, look, lens, fstop, focus):
    cd = bpy.data.cameras.new('cam'); cam = link_obj(bpy.data.objects.new('cam', cd)); sc.camera = cam
    cam.location = loc
    c = cam.constraints.new('TRACK_TO'); c.target = empty('look', look); c.track_axis = 'TRACK_NEGATIVE_Z'; c.up_axis = 'UP_Y'
    cd.lens = lens; cd.dof.use_dof = True; cd.dof.aperture_fstop = fstop; cd.dof.focus_object = empty('focus', focus)
    cd.clip_start = 0.01
    return cam

def dust(n, centre, spread, mat_, rmin=0.0012, rmax=0.003):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1)
    me = bpy.context.object.data; bpy.data.objects.remove(bpy.context.object)
    me.materials.append(mat_)
    for i in range(n):
        o = link_obj(bpy.data.objects.new('dust', me))
        o.location = Vector(centre) + Vector((random.uniform(-1, 1) * spread[0], random.uniform(-1, 1) * spread[1], random.uniform(0, 1) * spread[2]))
        s = random.uniform(rmin, rmax); o.scale = (s, s, s)

def wood_material(name, dark=0.35):
    m = principled(name, (0.16, 0.085, 0.04), rough=0.55, spec=0.35)
    n, L, p = nodes(m)
    tc = n.new('ShaderNodeTexCoord')
    mp = n.new('ShaderNodeMapping'); mp.inputs['Scale'].default_value = (1.0, 10, 1.0)
    L.new(tc.outputs['Object'], mp.inputs[0])
    nz = n.new('ShaderNodeTexNoise'); nz.inputs['Scale'].default_value = 4; nz.inputs['Detail'].default_value = 10; nz.inputs['Distortion'].default_value = 0.6
    L.new(mp.outputs[0], nz.inputs[0])
    nz2 = n.new('ShaderNodeTexNoise'); nz2.inputs['Scale'].default_value = 1.5; nz2.inputs['Detail'].default_value = 3
    L.new(tc.outputs['Object'], nz2.inputs[0])
    mix = n.new('ShaderNodeMixRGB'); mix.blend_type = 'MULTIPLY'; mix.inputs[0].default_value = 0.6
    L.new(nz.outputs['Fac'], mix.inputs[1]); L.new(nz2.outputs['Fac'], mix.inputs[2])
    ramp = n.new('ShaderNodeValToRGB'); ramp.name = 'Color Ramp'
    ramp.color_ramp.elements[0].color = (0.035, 0.016, 0.008, 1)
    ramp.color_ramp.elements[1].color = (0.30, 0.16, 0.075, 1)
    L.new(mix.outputs[0], ramp.inputs[0]); L.new(ramp.outputs[0], p.inputs['Base Color'])
    bump = n.new('ShaderNodeBump'); bump.inputs['Strength'].default_value = 0.25
    L.new(mix.outputs[0], bump.inputs['Height']); L.new(bump.outputs[0], p.inputs['Normal'])
    return m

BRONZE = principled('bronze', (0.62, 0.40, 0.18), rough=0.32, metal=1.0)
VERMILION = principled('vermilion', (0.80, 0.10, 0.03), rough=0.45, spec=0.5)
DUSTM = principled('dust', (0.9, 0.8, 0.65), rough=0.8)
_n, _l, _p = nodes(DUSTM); _p.inputs['Emission'].default_value = (1.0, 0.8, 0.55, 1); _p.inputs['Emission Strength'].default_value = 0.6

def stylus(start, end, radius=0.009, band=True):
    """Bronze stylus: a pointed end and a flat spatula for smoothing the wax."""
    d = Vector(end) - Vector(start); Lh = d.length
    parts = []
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=radius, depth=Lh * 0.72)
    shaft = bpy.context.object; parts.append((shaft, 0.5))
    bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=radius, radius2=0.0006, depth=Lh * 0.16)
    tip = bpy.context.object; parts.append((tip, 0.0))
    bpy.ops.mesh.primitive_cube_add(size=1)
    spat = bpy.context.object; spat.scale = (radius * 3.0, radius * 0.45, Lh * 0.12); parts.append((spat, 1.0))
    out = []
    rot = d.to_track_quat('Z', 'Y')
    for o, pos in parts:
        bpy.ops.object.shade_smooth()
        set_mat(o, BRONZE)
        out.append(o)
    # place along the axis: tip at start, spatula at end
    shaft.rotation_mode = tip.rotation_mode = spat.rotation_mode = 'QUATERNION'
    axis = d.normalized()
    shaft.location = Vector(start) + axis * (Lh * 0.16 + Lh * 0.36); shaft.rotation_quaternion = rot
    tip.location = Vector(start) + axis * (Lh * 0.08); tip.rotation_quaternion = (rot @ Vector((0, 0, -1)).to_track_quat('Z', 'Y')) if False else rot
    # cone points along +Z: flip so the point is at the start
    tip.rotation_quaternion = (-axis).to_track_quat('Z', 'Y')
    spat.location = Vector(start) + axis * (Lh * 0.88 + Lh * 0.06); spat.rotation_quaternion = rot
    for o in (shaft, spat):
        bv = o.modifiers.new('bv', 'BEVEL'); bv.width = radius * 0.3; bv.segments = 3
    if band:
        bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=radius * 1.12, depth=Lh * 0.05)
        b = bpy.context.object; bpy.ops.object.shade_smooth(); set_mat(b, VERMILION)
        b.rotation_mode = 'QUATERNION'; b.rotation_quaternion = rot
        b.location = Vector(start) + axis * (Lh * 0.80)
    return out

# ---------- scenes ----------
def ground(mat_):
    bpy.ops.mesh.primitive_plane_add(size=8, location=(0, 0, 0)); g = bpy.context.object; set_mat(g, mat_); return g

if variant in ('a', 'b'):
    LIGHT_BG = variant == 'a'
    if LIGHT_BG:
        # warm honey-lit linen ground and a brighter, paler world
        LINEN = principled('linen', (0.80, 0.62, 0.40), rough=0.9, sss=0.05)
        n, L, p = nodes(LINEN)
        tcl = n.new('ShaderNodeTexCoord'); nzl = n.new('ShaderNodeTexNoise'); nzl.inputs['Scale'].default_value = 3; nzl.inputs['Detail'].default_value = 6
        L.new(tcl.outputs['Object'], nzl.inputs[0])
        rpl = n.new('ShaderNodeValToRGB'); rpl.color_ramp.elements[0].color = (0.45, 0.28, 0.13, 1); rpl.color_ramp.elements[1].color = (0.66, 0.46, 0.25, 1)
        L.new(nzl.outputs['Fac'], rpl.inputs[0]); L.new(rpl.outputs[0], p.inputs['Base Color'])
        ground(LINEN)
        bg.inputs[0].default_value = (0.12, 0.075, 0.04, 1); vol.inputs['Density'].default_value = 0.004
    else:
        table = wood_material('table'); n, L, p = nodes(table)
        n['Color Ramp'].color_ramp.elements[1].color = (0.06, 0.035, 0.02, 1)
        ground(table)
    TW, TH, FR, DEP = 0.80, 1.04, 0.075, 0.045
    frame = wood_material('frame')
    # frame: four bevelled bars
    for (cx, cy, sx, sy) in [(0, (TH - FR) / 2, TW, FR), (0, -(TH - FR) / 2, TW, FR),
                             ((TW - FR) / 2, 0, FR, TH - 2 * FR), (-(TW - FR) / 2, 0, FR, TH - 2 * FR)]:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(cx, cy, DEP / 2))
        b = bpy.context.object; b.scale = (sx, sy, DEP); bpy.ops.object.transform_apply(scale=True)
        bv = b.modifiers.new('bv', 'BEVEL'); bv.width = 0.008; bv.segments = 4
        set_mat(b, frame)
    # back board
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.006)); bb = bpy.context.object
    bb.scale = (TW - 0.01, TH - 0.01, 0.012); set_mat(bb, frame)
    # wax
    WW, WH = TW - 2 * FR, TH - 2 * FR
    groove, lip = strokes_map(900, int(900 * WH / WW), rows=9, fade_from=0.36, fade_to=0.80, width=1.45, seed=7, blur_grow=1.2)
    h = 0.35 * lip - groove * 1.0
    h = (h - h.min()) / (h.max() - h.min())
    himg = to_image('wax_h', h)
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=520, y_subdivisions=int(520 * WH / WW), size=1, location=(0, 0, DEP * 0.55))
    wax = bpy.context.object; wax.scale = (WW, WH, 1); bpy.ops.object.transform_apply(scale=True)
    tex = bpy.data.textures.new('wax_t', 'IMAGE'); tex.image = himg; tex.extension = 'EXTEND'
    dm = wax.modifiers.new('disp', 'DISPLACE'); dm.texture = tex; dm.texture_coords = 'UV'; dm.strength = 0.0045; dm.mid_level = h.mean()
    for pl in wax.data.polygons: pl.use_smooth = True
    WAX = principled('wax', (0.40, 0.18, 0.025), rough=0.3, sss=0.5, sss_col=(0.9, 0.42, 0.08), spec=0.55)
    n, L, p = nodes(WAX)
    # the re-melted side is a little glossier and lighter
    tc = n.new('ShaderNodeTexCoord'); sx = n.new('ShaderNodeSeparateXYZ'); L.new(tc.outputs['UV'], sx.inputs[0])
    mr = n.new('ShaderNodeMapRange'); mr.inputs['From Min'].default_value = 0.45; mr.inputs['From Max'].default_value = 0.95
    mr.inputs['To Min'].default_value = 0.34; mr.inputs['To Max'].default_value = 0.12
    L.new(sx.outputs['X'], mr.inputs['Value']); L.new(mr.outputs[0], p.inputs['Roughness'])
    it = img_node(WAX, himg); L.new(tc.outputs['UV'], it.inputs[0])
    # grooves read darker (wax is thinner over the dark board)
    cr = n.new('ShaderNodeMixRGB'); cr.inputs[1].default_value = (0.09, 0.035, 0.01, 1); cr.inputs[2].default_value = (0.46, 0.22, 0.035, 1)
    sm = n.new('ShaderNodeMapRange'); sm.inputs['From Min'].default_value = 0.0; sm.inputs['From Max'].default_value = float(np.percentile(h, 50))
    L.new(it.outputs['Color'], sm.inputs['Value']); L.new(sm.outputs[0], cr.inputs[0]); L.new(cr.outputs[0], p.inputs['Base Color'])
    bump = n.new('ShaderNodeBump'); bump.inputs['Strength'].default_value = 0.35; bump.inputs['Distance'].default_value = 0.002
    L.new(it.outputs['Color'], bump.inputs['Height']); L.new(bump.outputs[0], p.inputs['Normal'])
    set_mat(wax, WAX)
    # stylus resting across the lower right corner, on the frame
    stylus((0.05, -0.50, DEP + 0.012), (0.47, 0.06, DEP + 0.012), radius=0.0095)
    root = empty('root', (0, 0, 0))
    for o in bpy.data.objects:
        if o.type == 'MESH' and o.parent is None and o.name != 'Plane': o.parent = root
    root.rotation_euler = (0, 0, math.radians(-14)); root.location = (0.0, 0.0, 0)
    tgt = empty('tgt', (0, 0, 0.03))
    light('candle', 'AREA', (-1.25, 0.55, 0.42), 55 if not LIGHT_BG else 70, (1.0, 0.62, 0.30), 0.18, tgt, vol=1.4)   # low warm grazing key
    light('fill', 'AREA', (0.6, -1.6, 1.6), 3.5 if not LIGHT_BG else 10, (0.55, 0.62, 0.85) if not LIGHT_BG else (1.0, 0.85, 0.65), 1.5, tgt, vol=0)
    light('rim', 'AREA', (0.9, 1.6, 0.6), 9, (1.0, 0.75, 0.45), 0.8, tgt, vol=0.3)
    if LIGHT_BG:
        light('sky', 'AREA', (0, 0, 3), 28, (1.0, 0.82, 0.6), 4, tgt, vol=0)
    dust(60 if LIGHT_BG else 120, (-0.4, 0.0, 0.08), (0.9, 0.8, 0.7), DUSTM, 0.0008, 0.002)
    camera((0.30, -0.82, 1.42), (0.02, -0.03, 0.0), 39, 2.4, (0.10, 0.05, 0.04))

elif variant == 'c':
    table = wood_material('table'); n, L, p = nodes(table)
    n['Color Ramp'].color_ramp.elements[1].color = (0.05, 0.03, 0.018, 1)
    ground(table)
    PARCH = principled('parch', (0.78, 0.66, 0.46), rough=0.7, sss=0.2, sss_col=(0.95, 0.8, 0.55))
    PW, PH = 0.5, 0.7
    groove_l, _ = strokes_map(500, 700, rows=11, fade_from=2, fade_to=3, width=1.4, seed=2, blur_grow=0)
    groove_r, _ = strokes_map(500, 700, rows=11, fade_from=0.25, fade_to=0.8, width=1.4, seed=5, blur_grow=2.5)
    mist_src = []
    for side, gmap in ((-1, groove_l), (1, groove_r)):
        img = to_image(f'ink{side}', gmap)
        bpy.ops.mesh.primitive_grid_add(x_subdivisions=80, y_subdivisions=60, size=1)
        pg = bpy.context.object; pg.scale = (PW, PH, 1); bpy.ops.object.transform_apply(scale=True)
        for v in pg.data.vertices:
            u = (v.co.x / PW + 0.5)      # 0..1 across the page
            g = u if side > 0 else 1 - u  # distance from the spine
            v.co.z = 0.05 + 0.10 * math.sin(min(1, g * 1.4) * math.pi * 0.5) * (1 - 0.35 * g) - 0.05 * (g ** 2)
            v.co.x += side * PW / 2
        for pl in pg.data.polygons: pl.use_smooth = True
        m = PARCH.copy(); n2, L2, p2 = nodes(m)
        tc = n2.new('ShaderNodeTexCoord'); it = n2.new('ShaderNodeTexImage'); it.image = img; it.image.colorspace_settings.name = 'Non-Color'
        L2.new(tc.outputs['UV'], it.inputs[0])
        mx = n2.new('ShaderNodeMixRGB'); mx.inputs[1].default_value = (0.78, 0.66, 0.46, 1); mx.inputs[2].default_value = (0.05, 0.035, 0.03, 1)
        L2.new(it.outputs['Color'], mx.inputs[0]); L2.new(mx.outputs[0], p2.inputs['Base Color'])
        set_mat(pg, m)
        if side > 0:
            ys, xs = np.nonzero(groove_r > 0.15)
            for k in np.random.choice(len(xs), min(700, len(xs)), replace=False):
                u, vv = xs[k] / 500, 1 - ys[k] / 700
                mist_src.append((u, vv))
            right_page = pg
    # cover boards
    COVER = principled('cover', (0.12, 0.03, 0.02), rough=0.6)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.012)); cv = bpy.context.object
    cv.scale = (PW * 2 + 0.06, PH + 0.05, 0.02); set_mat(cv, COVER)
    # ink mist: fine motes lifting off the fading lines on the right page
    INKM = principled('inkmist', (0.18, 0.15, 0.14), rough=0.9)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1); me = bpy.context.object.data; bpy.data.objects.remove(bpy.context.object)
    me.materials.append(INKM)
    for (u, vv) in mist_src:
        lift = max(0, (u - 0.25)) ** 1.3 * random.uniform(0.0, 0.5)
        x = u * PW + random.gauss(0, 0.004) + lift * 0.25; y = (vv - 0.5) * PH + random.gauss(0, 0.004) + lift * 0.15
        g = u
        z = 0.05 + 0.10 * math.sin(min(1, g * 1.4) * math.pi * 0.5) * (1 - 0.35 * g) - 0.05 * g * g + 0.002 + lift
        o = link_obj(bpy.data.objects.new('m', me)); o.location = (x, y, z)
        s = random.uniform(0.0012, 0.003) * (1 - 0.5 * min(1, lift * 3)); o.scale = (s, s, s)
    stylus((-0.42, -0.42, 0.05), (-0.05, -0.10, 0.11), radius=0.007)   # a reed pen stand-in, bronze, with the vermilion band
    root = empty('root', (0, 0, 0))
    for o in bpy.data.objects:
        if o.type == 'MESH' and o.parent is None and o.name != 'Plane': o.parent = root
    root.rotation_euler = (0, 0, math.radians(-10))
    tgt = empty('tgt', (0.05, 0, 0.05))
    light('candle', 'AREA', (-1.1, 0.7, 0.75), 45, (1.0, 0.63, 0.32), 0.2, tgt, vol=1.4)
    light('fill', 'AREA', (0.8, -1.5, 1.5), 3, (0.55, 0.62, 0.85), 1.5, tgt, vol=0)
    light('rim', 'AREA', (1.2, 1.3, 0.7), 10, (1.0, 0.78, 0.5), 0.8, tgt, vol=0.3)
    dust(140, (0.0, 0.0, 0.1), (0.8, 0.7, 0.6), DUSTM)
    camera((0.25, -1.25, 1.35), (0.06, 0.02, 0.05), 46, 2.0, (0.25, 0.0, 0.12))


sc.render.filepath = out
bpy.ops.render.render(write_still=True)
