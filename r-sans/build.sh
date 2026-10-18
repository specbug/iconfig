#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# R Sans — A warm geometric reading font
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# Design philosophy:
#
#   "Less, but better."                        — Dieter Rams
#   "Circles and rectangles; heavy lines       — Andy Matuschak / Orbit
#    and negative space."
#   "The details are not the details.          — Charles Eames
#    They make the design."
#
# Aesthetic target:
#   Between Anthropic's Styrene B (rounded, warm, slightly squishy) and
#   Google Sans Text (geometric, clean, body-text optimized).
#
# Base font: DM Sans by Colophon Foundry (same team as Google Sans Text)
#   - Geometric DNA (no neo-grotesque fighting)
#   - Optical size axis (9–40) with auto double-storey a/g at text sizes
#   - Designed for body text from the ground up
#   - 1000 UPM, ~486 glyphs, SIL Open Font License
#
# ─── What Makes R Sans ≠ Stock DM Sans ─────────────────────────────────
#
# 1. TERMINAL SOFTENING — The core creative transformation.
#    DM Sans has clean geometric terminals with flat, sharp cuts.
#    R Sans softens 12 key glyphs (a, c, e, f, g, j, n, r, s, t, u, y)
#    tapering terminal tips and rounding junctions for the warm,
#    slightly organic feel of Styrene B — without losing geometric clarity.
#
# 2. DISAMBIGUATION SET
#    Serifed uppercase 'I' for I/l distinction.
#    Tailed lowercase 'l' for l/1/I clarity.
#    Dotted zero for 0/O distinction.
#    Applied to static instances; variable font retains DM Sans defaults.
#
# 3. READING-OPTIMIZED METRICS
#    DM Sans ships with ~1.30x default line-height — already in our
#    target range. We preserve this and ensure cross-platform consistency
#    by aligning hhea/OS2/Win metrics.
#
# 4. PROPER FONT METADATA
#    Clean RIBBI grouping, correct fsSelection/macStyle bits, unique
#    PostScript names. Every weight shows correctly in Font Book.
#
# 5. v2 PROPORTION RETUNE
#    Taller lowercase (x-height ×1.048, ascenders fixed), tighter round
#    sidebearings, and c/e/s terminals that open away from the counter.
#    Done per master on the variable fonts (gvar, composites, GPOS
#    anchors, MVAR), so every weight and optical size stays consistent.
#
# ─── Build Instructions ──────────────────────────────────────────────
#
#   Requirements: python3, curl
#   Usage: ./build.sh              (full build)
#          ./build.sh --inspect    (dump glyph coordinates for surgery targets)
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="/tmp/r-sans-build-$$"
INSPECT_MODE=false
[[ "${1:-}" == "--inspect" ]] && INSPECT_MODE=true

# ── Configuration ────────────────────────────────────────────────────
OPSZ=14.0              # Optical size for static instances (DM Sans range: 9–40)
                       # 14 = body text sweet spot, double-storey a/g retained
DMSANS_REPO="https://raw.githubusercontent.com/google/fonts/main/ofl/dmsans"

# ── v2: proportion and rhythm retune ────────────────────────────────
# Measured against Google Sans Text at wght 400 / opsz 17 (see DESIGN.md).
XHEIGHT_K=0.048        # lowercase x-height gain (501 → 525 at opsz 17)
ROUND_SB_TIGHTEN=0.12  # share of round-side sidebearing removed (o c e d q b p a g)
SPACING_REF_OPSZ=17    # body-text optical size the spacing is sized at
TERMINAL_TUCK=8        # c e s: outer terminal corner tucks in (v1: 13–16)
APERTURE_LIFT=9        # c e s: terminal cut moves away from the counter

# ── Frozen features ─────────────────────────────────────────────────
# These stylistic sets are baked into the default glyphs via pyftfeatfreeze.
#   ss01  Round quotes/commas    — warmth in punctuation
#   ss04  Alternate 'u'          — more geometric form
#   ss06  Alternate 'Q' (tail)   — distinctive, confident
#   ss07  Alternate digits       — geometric 1, 3, 4, 6, 9
FEATURES="ss01,ss04,ss06,ss07"

cleanup() {
  rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

echo "==> Setting up build environment..."
mkdir -p "$BUILD_DIR/output"
python3 -m venv "$BUILD_DIR/venv"
source "$BUILD_DIR/venv/bin/activate"
pip install -q fonttools brotli numpy opentype-feature-freezer

echo "==> Downloading DM Sans..."
curl -sL -o "$BUILD_DIR/DMSans.ttf" \
  "$DMSANS_REPO/DMSans%5Bopsz%2Cwght%5D.ttf"
curl -sL -o "$BUILD_DIR/DMSans-Italic.ttf" \
  "$DMSANS_REPO/DMSans-Italic%5Bopsz%2Cwght%5D.ttf"

# Verify downloads
python3 -c "
from fontTools.ttLib import TTFont
for f in ['$BUILD_DIR/DMSans.ttf', '$BUILD_DIR/DMSans-Italic.ttf']:
    font = TTFont(f)
    assert 'glyf' in font, f'{f}: not a TrueType font'
    assert 'fvar' in font, f'{f}: not a variable font'
    font.close()
print('  Downloads verified: 2 variable TrueType fonts')
"

# ── Step 1: Freeze features + Rename DM Sans → R Sans ───────────────

echo "==> Freezing features (${FEATURES}) and renaming..."
pyftfeatfreeze -f "$FEATURES" -R 'DM Sans/R Sans' \
  "$BUILD_DIR/DMSans.ttf" \
  "$BUILD_DIR/output/RSans-Variable.ttf"
pyftfeatfreeze -f "$FEATURES" -R 'DM Sans/R Sans' \
  "$BUILD_DIR/DMSans-Italic.ttf" \
  "$BUILD_DIR/output/RSans-Italic-Variable.ttf"

# Clean up name table: strip "9pt" opsz prefix that DM Sans bakes in
python3 - "$BUILD_DIR" << 'NAMECLEAN'
import os
import sys
import re
from fontTools.ttLib import TTFont

BUILD = sys.argv[1]

for var_file in ['RSans-Variable.ttf', 'RSans-Italic-Variable.ttf']:
    path = os.path.join(BUILD, 'output', var_file)
    font = TTFont(path)
    name = font['name']
    for record in name.names:
        try:
            text = record.toStr()
        except:
            continue
        changed = text
        changed = re.sub(r'R Sans \d+pt\b', 'R Sans', changed)
        changed = re.sub(r'RSans-\d+pt', 'RSans-', changed)
        changed = changed.replace('RSans--', 'RSans-')
        if changed != text:
            record.string = changed
    font.save(path)
    print(f"  {var_file}: names cleaned")

print("  Feature freeze + rename complete.")
NAMECLEAN

# ── Inspect mode: dump glyph data and exit ───────────────────────────

if $INSPECT_MODE; then
  echo "==> Inspection mode: dumping glyph coordinates..."
  python3 - "$BUILD_DIR" << 'INSPECT'
import os
import sys
from fontTools.ttLib import TTFont

BUILD = sys.argv[1]
font = TTFont(os.path.join(BUILD, 'output', 'RSans-Variable.ttf'))
glyf = font['glyf']

targets = ['a', 'c', 'e', 'f', 'g', 'j', 'r', 's', 't', 'n', 'u', 'y',
           'I', 'l', 'one', 'zero', 'O']

for gname in targets:
    g = glyf[gname]
    print(f"\n{'='*60}")
    print(f"GLYPH: '{gname}'  contours={g.numberOfContours}  "
          f"bounds=({g.xMin},{g.yMin},{g.xMax},{g.yMax})")
    if g.numberOfContours <= 0:
        print("  (composite glyph)")
        continue
    coords = list(g.coordinates)
    flags = list(g.flags)
    ends = list(g.endPtsOfContours)
    start = 0
    for ci, end in enumerate(ends):
        print(f"\n  Contour {ci} (points {start}-{end}):")
        for pi in range(start, end + 1):
            x, y = coords[pi]
            on = "ON " if flags[pi] & 1 else "OFF"
            print(f"    [{pi:3d}] {on} ({x:6d}, {y:6d})")
        start = end + 1

font.close()
INSPECT
  echo "==> Inspection complete."
  exit 0
fi

# ── Step 2: Terminal softening surgery ───────────────────────────────

echo "==> Performing terminal softening surgery..."
python3 - "$BUILD_DIR" "$TERMINAL_TUCK" "$APERTURE_LIFT" << 'SURGERY'
import os
import sys
from fontTools.ttLib import TTFont

BUILD = sys.argv[1]
TUCK = int(sys.argv[2])
LIFT = int(sys.argv[3])

# ── Terminal softening ──────────────────────────────────────────────
# Soften sharp/flat terminals on 12 key glyphs to create warmth.
# All adjustments are on the default master (opsz=9, wght=400).
# gvar deltas are preserved automatically since we only modify
# existing point coordinates, never add/remove points.
#
# Adjustments are intentionally subtle: 5–18 units on a 1000 UPM grid.
# The cumulative effect across all glyphs creates a warm, organic feel
# without any single change being jarring.

def soften(coords, adjustments):
    """Apply a list of (point_index, dx, dy) adjustments.
    Validates indices are in range before applying.
    """
    for pi, dx, dy in adjustments:
        if pi >= len(coords):
            return False
        x, y = coords[pi]
        coords[pi] = (x + dx, y + dy)
    return True

def verify_points(coords, checks, tolerance=50):
    """Verify that points at given indices are near expected positions.
    checks: list of (point_index, expected_x, expected_y)
    Returns True if all points match within tolerance.
    """
    for pi, ex, ey in checks:
        if pi >= len(coords):
            return False
        x, y = coords[pi]
        if abs(x - ex) > tolerance or abs(y - ey) > tolerance:
            return False
    return True

def open_terminal(coords, off_outer, outer, inner, off_inner, away, inward, share=1.0):
    """Soften a flat terminal cut while opening the aperture (v2).

    The outer corner tucks in (TUCK) so the stroke end tapers and reads
    soft; the whole cut moves AWAY from the counter (LIFT), the inner
    corner more than the outer, so the cut turns slightly outward.
      away    +1 = terminal opens upward (top of c, s), -1 = downward
      inward  direction the outer corner tucks along x (-1 = leftward)
      share   fraction of LIFT (a glyph that opens at both ends takes less)
    v1 pulled tips toward the counter, which closed c/e below stock DM Sans.
    """
    t, l = TUCK, LIFT * share
    soften(coords, [
        (off_outer, inward * round(t * 0.6), away * round(l * 0.25)),
        (outer,     inward * t,              away * round(l * 0.65)),
        (inner,    -inward * round(t * 0.35), away * round(l)),
        (off_inner, -inward * round(t * 0.25), away * round(l * 0.55)),
    ])

def surgery_c(glyf):
    """Soften both terminals of 'c' and open its aperture.

    DM Sans 'c' has flat horizontal cuts at both terminals.
    Upright: top cut pts 11-12, bottom cut pts 28-29.
    Italic: same topology shifted by one point (12-13, 29-30).
    """
    g = glyf['c']
    c = list(g.coordinates)
    for o, name in [(0, 'upright'), (1, 'italic')]:
        if verify_points(c, [(11 + o, 526 + 17 * o, 361), (12 + o, 440 + 17 * o, 361),
                             (28 + o, 440 - 17 * o, 165), (29 + o, 526 - 17 * o, 165)],
                         tolerance=12):
            # both ends open, so each takes a smaller share of the lift
            open_terminal(c, 10 + o, 11 + o, 12 + o, 13 + o, away=+1, inward=-1, share=0.4)
            open_terminal(c, 30 + o, 29 + o, 28 + o, 27 + o, away=-1, inward=-1, share=0.4)
            g.coordinates = type(g.coordinates)(c)
            g.recalcBounds(glyf)
            print(f"    'c': softened + opened both terminals ({name})")
            return
    print("    'c': skipped (unexpected topology)")

def surgery_e(glyf):
    """Soften the bottom-right terminal of 'e' and open its aperture.

    Upright cut pts 33-34; italic same topology shifted by two (35-36).
    The crossbar end is left alone (v1's adaptive italic rule caught it).
    """
    g = glyf['e']
    c = list(g.coordinates)
    for o, name in [(0, 'upright'), (2, 'italic')]:
        if verify_points(c, [(33 + o, 424 - 21 * (o // 2), 142), (34 + o, 507 - 21 * (o // 2), 142)],
                         tolerance=12):
            open_terminal(c, 35 + o, 34 + o, 33 + o, 32 + o, away=-1, inward=-1)
            g.coordinates = type(g.coordinates)(c)
            g.recalcBounds(glyf)
            print(f"    'e': softened + opened terminal ({name})")
            return
    print("    'e': skipped (unexpected topology)")

def surgery_s(glyf):
    """Soften both terminals of 's' and open its apertures.

    Upper cut pts 29-30 (outer, inner), lower cut pts 4-5; the italic has
    the same indices.
    """
    g = glyf['s']
    c = list(g.coordinates)
    for name, (ux, ix, lx, jx) in [('upright', (443, 360, 44, 130)),
                                   ('italic', (465, 382, 26, 112))]:
        if verify_points(c, [(29, ux, 388), (30, ix, 388), (4, lx, 159), (5, jx, 159)],
                         tolerance=12):
            open_terminal(c, 28, 29, 30, 31, away=+1, inward=-1)
            open_terminal(c, 3, 4, 5, 6, away=-1, inward=+1)
            g.coordinates = type(g.coordinates)(c)
            g.recalcBounds(glyf)
            print(f"    's': softened + opened both terminals ({name})")
            return
    print("    's': skipped (unexpected topology)")

def surgery_t(glyf):
    """Soften the bottom hook of 't'."""
    g = glyf['t']
    c = list(g.coordinates)
    if len(c) >= 21 and verify_points(c, [(16, 213, 105), (17, 251, 72)], tolerance=80):
        soften(c, [
            (16, 0, 5), (17, -5, 8), (19, -6, 5), (20, -5, 8),
        ])
        g.coordinates = type(g.coordinates)(c)
        g.recalcBounds(glyf)
        print("    't': softened bottom hook")
    else:
        print("    't': skipped (unexpected topology)")

def surgery_f(glyf):
    """Soften the top hook terminal of 'f'."""
    g = glyf['f']
    c = list(g.coordinates)
    if len(c) >= 13 and verify_points(c, [(6, 322, 720), (7, 322, 648)], tolerance=80):
        soften(c, [
            (6, -7, -3), (7, -7, 3),
        ])
        g.coordinates = type(g.coordinates)(c)
        g.recalcBounds(glyf)
        print("    'f': softened hook terminal")
    else:
        print("    'f': skipped (unexpected topology)")

def surgery_a(glyf):
    """Soften the stem-bowl junction of 'a'."""
    g = glyf['a']
    c = list(g.coordinates)
    if verify_points(c, [(30, 393, 69), (31, 362, 32), (32, 320, 4)]):
        soften(c, [
            (30, -3, -4), (31, -4, -3), (32, -3, -2),
        ])
        g.coordinates = type(g.coordinates)(c)
        g.recalcBounds(glyf)
        print("    'a': softened stem-bowl junction")
    else:
        print("    'a': skipped (italic topology differs)")

def surgery_r(glyf):
    """Soften the terminal of 'r' where the branch ends."""
    g = glyf['r']
    c = list(g.coordinates)
    if len(c) >= 12 and verify_points(c, [(9, 364, 450), (10, 312, 450)], tolerance=80):
        soften(c, [
            (9, -7, 5), (10, 5, 7), (11, 4, 4),
        ])
        g.coordinates = type(g.coordinates)(c)
        g.recalcBounds(glyf)
        print("    'r': softened branch terminal")
    else:
        print("    'r': skipped (unexpected topology)")

def surgery_n(glyf):
    """Round the arch shoulder of 'n' slightly."""
    g = glyf['n']
    c = list(g.coordinates)
    if len(c) >= 11 and verify_points(c, [(9, 462, 494), (10, 510, 404)], tolerance=80):
        soften(c, [
            (9, -4, 4), (10, -4, 4),
        ])
        g.coordinates = type(g.coordinates)(c)
        g.recalcBounds(glyf)
        print("    'n': rounded arch shoulder")
    else:
        print("    'n': skipped (unexpected topology)")

def surgery_u(glyf):
    """Round the bowl-to-stem junction of 'u'."""
    g = glyf['u']
    c = list(g.coordinates)
    if len(c) >= 4 and verify_points(c, [(2, 116, 32), (3, 68, 123)], tolerance=80):
        soften(c, [
            (2, 4, -4), (3, 4, -4),
        ])
        g.coordinates = type(g.coordinates)(c)
        g.recalcBounds(glyf)
        print("    'u': rounded bowl-stem junction")
    else:
        print("    'u': skipped (unexpected topology)")

def surgery_g(glyf):
    """Soften the ear of 'g'.

    The ear is the last contour (contour 3) with 4 ON points.
    Uses endPtsOfContours to find correct indices for both upright and italic.
    """
    g = glyf['g']
    c = list(g.coordinates)
    ends = list(g.endPtsOfContours)
    if len(ends) < 4:
        print("    'g': skipped (fewer than 4 contours)")
        return
    ear_start = ends[2] + 1
    ear_end = ends[3]
    if ear_end - ear_start + 1 != 4:
        print(f"    'g': skipped (ear has {ear_end - ear_start + 1} points, expected 4)")
        return
    # Right corners are at relative positions 2 and 3 within the ear
    soften(c, [
        (ear_start + 2, -7, -3),   # upper-right corner
        (ear_start + 3, -7,  3),   # lower-right corner
    ])
    g.coordinates = type(g.coordinates)(c)
    g.recalcBounds(glyf)
    print("    'g': softened ear corners")

def surgery_j(glyf):
    """Soften the bottom hook of 'j'."""
    g = glyf['j']
    c = list(g.coordinates)
    if len(c) >= 5:
        soften(c, [
            (0, 7, 5), (3, -4, 8), (4, -4, -4),
        ])
        g.coordinates = type(g.coordinates)(c)
        g.recalcBounds(glyf)
        print("    'j': softened hook")
    else:
        print("    'j': skipped (unexpected topology)")

def surgery_y(glyf):
    """Soften the descender terminal of 'y'."""
    g = glyf['y']
    c = list(g.coordinates)
    n = len(c)
    if n >= 10:
        # Taper the bottom two points (first and last in contour)
        soften(c, [
            (0, 6, 5),       # left descender corner
            (n - 1, -6, 5),  # right descender corner
        ])
        g.coordinates = type(g.coordinates)(c)
        g.recalcBounds(glyf)
        print("    'y': softened descender terminal")
    else:
        print("    'y': skipped (unexpected topology)")


# Apply surgery to both variable fonts
for var_file in ['RSans-Variable.ttf', 'RSans-Italic-Variable.ttf']:
    path = os.path.join(BUILD, 'output', var_file)
    font = TTFont(path)
    glyf = font['glyf']
    print(f"  {var_file}:")
    surgery_c(glyf)
    surgery_e(glyf)
    surgery_s(glyf)
    surgery_t(glyf)
    surgery_f(glyf)
    surgery_a(glyf)
    surgery_r(glyf)
    surgery_n(glyf)
    surgery_u(glyf)
    surgery_g(glyf)
    surgery_j(glyf)
    surgery_y(glyf)
    font.save(path)

print("  Terminal softening complete.")
SURGERY

# ── Step 2b: v2 proportion and rhythm retune ─────────────────────────

echo "==> Retuning proportions (x-height +${XHEIGHT_K}, round sides -${ROUND_SB_TIGHTEN})..."
python3 - "$BUILD_DIR" "$XHEIGHT_K" "$ROUND_SB_TIGHTEN" "$SPACING_REF_OPSZ" << 'RETUNE'
import os
import sys
import math
import unicodedata
import numpy as np
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables import otTables as ot
from fontTools.ttLib.tables.TupleVariation import TupleVariation
from fontTools.varLib.models import VariationModel, supportScalar, normalizeLocation
from fontTools.varLib.varStore import VarStoreInstancer
from fontTools.varLib.builder import buildVarData, buildVarRegion
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.transformPen import TransformPen

# ── v2: proportion and rhythm retune ────────────────────────────────
# G1  Taller x-height. Every lowercase outline goes through a vertical
#     piecewise-linear remap: below the overshoot band (OV = 1.03 × x-height)
#     y scales by 1 + K; between OV and the ascender it compresses so the
#     ascender (and anything above it) stays put; the baseline and
#     descenders never move. The remap is applied per master with that
#     master's own x-height and ascender (DM Sans's x-height shrinks with
#     opsz, and its ascender drops to 700 at opsz 40), and the deltas are
#     re-solved over the same master grid, so every master is exact.
# G3  Tighter round sides. o c e d q b p a g lose a constant share of their
#     round-side sidebearing (sized at the body-text instance).

BUILD = sys.argv[1]
K = float(sys.argv[2])                # XHEIGHT_K
T = float(sys.argv[3])                # ROUND_SB_TIGHTEN
REF_OPSZ = float(sys.argv[4])         # where G3 sidebearings are sized
OV_BAND = 1.03
TITTLES = {'i', 'j', 'fi', 'i.loclTRK'}
ROUNDS = {'o': 'LR', 'c': 'L', 'e': 'L', 'd': 'L', 'q': 'L', 'b': 'R', 'p': 'R',
          'a': 'L', 'g': 'L', 'a.ss02': 'L', 'g.ss03': 'L'}
VCARON = 'uni030C.alt'                 # ď ľ ť apostrophe-caron: rides the stem top


def remap_fn(xh, asc, k=K):
    ov = xh * OV_BAND
    new = ov * (1 + k)
    def f(y):
        if y <= 0:
            return y
        if y <= ov:
            return y * (1 + k)
        if y <= asc:
            return new + (y - ov) * (asc - new) / (asc - ov)
        return y                       # ascender overshoot stays put
    return f


def lowercase_set(font):
    """Simple (contour) glyphs that carry the lowercase x-height."""
    glyf = font['glyf']
    cmap = font.getBestCmap()
    names = set()
    for u, g in cmap.items():
        if unicodedata.category(chr(u)) == 'Ll':
            names.add(g)
    names |= {'dotlessi', 'uni0237', 'i.loclTRK', 'fi'}
    # Stylistic alternates of lowercase letters (a.ss02, g.ss03, y.ss05, ...)
    for g in font.getGlyphOrder():
        if '.' in g and g.split('.')[0] in names:
            names.add(g)
    return {g for g in names if g in glyf}


class Masters:
    """The master grid of a fontmake-built variable font."""

    def __init__(self, font):
        self.font = font
        self.axes = [a.axisTag for a in font['fvar'].axes]
        peaks = set()
        for tvs in font['gvar'].variations.values():
            for tv in tvs:
                peaks.add(tuple(sorted((a, v[1]) for a, v in tv.axes.items())))
        locs = [{}] + [dict(p) for p in sorted(peaks)]
        self.locs = locs
        self.model = VariationModel(locs, axisOrder=self.axes)
        supports = [tuple(sorted(s.items())) for s in self.model.supports]
        for tvs in font['gvar'].variations.values():
            for tv in tvs:
                key = tuple(sorted(tv.axes.items()))
                assert key in supports, f'tuple {key} is not on the master grid'

    def glyph_masters(self, name):
        """Absolute coordinates (incl. phantom points) at every master."""
        glyf = self.font['glyf']
        hm = self.font['hmtx'].metrics
        base, _ = glyf._getCoordinatesAndControls(name, hm)
        base = np.array(base, dtype=float)
        g = glyf[name]
        tvs = self.font['gvar'].variations.get(name, [])
        deltas = []
        for tv in tvs:
            tv = TupleVariation(tv.axes, list(tv.coordinates))
            if None in tv.coordinates:
                orig, _ = glyf._getCoordinatesAndControls(name, hm)
                ends = list(g.endPtsOfContours) if not g.isComposite() else []
                if g.isComposite():
                    tv.coordinates = [c if c is not None else (0, 0) for c in tv.coordinates]
                else:
                    tv.calcInferredDeltas(orig, ends)
            deltas.append((tv.axes, np.array(tv.coordinates, dtype=float)))
        out = []
        for loc in self.locs:
            v = base.copy()
            for axes, d in deltas:
                s = supportScalar(loc, axes)
                if s:
                    v += s * d
            out.append(v)
        return out

    def set_glyph_masters(self, name, masters, tolerance=0.5):
        glyf = self.font['glyf']
        hm = self.font['hmtx'].metrics
        masters = [np.round(m) for m in masters]
        deltas = self.model.getDeltas(masters)
        default = deltas[0]
        glyf._setCoordinates(name, [tuple(map(int, p)) for p in default], hm)
        g = glyf[name]
        new_coords, _ = glyf._getCoordinatesAndControls(name, hm)
        tvs = []
        for support, d in zip(self.model.supports[1:], deltas[1:]):
            d = np.round(d).astype(int)
            if not d.any():
                continue
            tv = TupleVariation(dict(support), [tuple(map(int, p)) for p in d])
            if not g.isComposite():
                tv.optimize(new_coords, list(g.endPtsOfContours), tolerance=tolerance)
            tvs.append(tv)
        if tvs:
            self.font['gvar'].variations[name] = tvs
        else:
            self.font['gvar'].variations.pop(name, None)


def metric_at_masters(M, name, fn):
    return [fn(m) for m in M.glyph_masters(name)]


def contours_of(g):
    s = 0
    for e in g.endPtsOfContours:
        yield s, e + 1
        s = e + 1


def apply_v2(path):
    font = TTFont(path)
    glyf = font['glyf']
    M = Masters(font)
    slant = math.tan(math.radians(-font['post'].italicAngle))
    lower = lowercase_set(font)
    simple_lower = {g for g in lower if not glyf[g].isComposite()}

    # Per-master metrics, measured on the untouched outlines.
    xh = metric_at_masters(M, 'x', lambda m: m[:-4, 1].max())
    asc = metric_at_masters(M, 'h', lambda m: m[:-4, 1].max())
    fns = [remap_fn(x, a) for x, a in zip(xh, asc)]
    rise = [x * K for x in xh]                    # x-height gain per master
    ov_default = xh[0] * OV_BAND
    print(f"    x-height per master: {sorted(set(round(x) for x in xh))} → ×{1 + K:.3f}")

    # Stem tops for the ď ľ ť caron, measured before the remap.
    base_ymax = {g: metric_at_masters(M, g, lambda m: m[:-4, 1].max())
                 for g in simple_lower if glyf[g].numberOfContours > 0}

    # ── G1a: lowercase outlines ─────────────────────────────────────
    for name in sorted(simple_lower):
        g = glyf[name]
        if g.numberOfContours <= 0:
            continue
        masters = M.glyph_masters(name)
        n = len(masters[0]) - 4
        base = masters[0]
        spans = list(contours_of(g))
        floating = [base[s:e, 1].min() > ov_default for s, e in spans]
        new = []
        for mi, m in enumerate(masters):
            m = m.copy()
            f = fns[mi]
            for (s, e), fl in zip(spans, floating):
                if fl:
                    # Tittles move with the x-height (like accents); other
                    # floating strokes (đ ħ bars, ð) ride the compression.
                    if name in TITTLES:
                        dy = rise[mi]
                    else:
                        cy = (m[s:e, 1].min() + m[s:e, 1].max()) / 2
                        dy = f(cy) - cy
                    m[s:e, 1] += dy
                    m[s:e, 0] += dy * slant
                else:
                    for i in range(s, e):
                        y = m[i, 1]
                        ny = f(y)
                        m[i, 0] += (ny - y) * slant
                        m[i, 1] = ny
            new.append(m)
        M.set_glyph_masters(name, new)

    # ── G1b: mark anchors on lowercase bases ────────────────────────
    gdef = font['GDEF'].table
    store = gdef.VarStore
    fvar_axes = font['fvar'].axes
    inst = [VarStoreInstancer(store, fvar_axes, loc) for loc in M.locs]
    regions = store.VarRegionList.Region
    axis_tags = M.axes

    def region_index(support):
        want = [support.get(t, (0, 0, 0)) for t in axis_tags]
        for ri, r in enumerate(regions):
            got = [(a.StartCoord, a.PeakCoord, a.EndCoord) for a in r.VarRegionAxis]
            if all(abs(a - b) < 1e-4 for p, q in zip(got, want) for a, b in zip(p, q)):
                return ri
        regions.append(buildVarRegion(support, axis_tags))
        store.VarRegionList.RegionCount = len(regions)
        return len(regions) - 1

    new_rows = []                     # (deltas per support)

    def dev_values(dev):
        if dev is None or dev.DeltaFormat != 0x8000:
            return [0.0] * len(M.locs)
        idx = (dev.StartSize << 16) + dev.EndSize
        return [i[idx] for i in inst]

    def make_dev(values):
        deltas = M.model.getDeltas([float(v) for v in values])
        default = int(round(deltas[0]))
        row = [int(round(d)) for d in deltas[1:]]
        if not any(row):
            return default, None
        new_rows.append(row)
        dev = ot.Device()
        dev.DeltaFormat = 0x8000
        dev.StartSize = -1            # patched once the VarData exists
        dev.EndSize = len(new_rows) - 1
        return default, dev

    def anchor_masters(a):
        ys = [a.YCoordinate + d for d in dev_values(getattr(a, 'YDeviceTable', None))]
        xs = [a.XCoordinate + d for d in dev_values(getattr(a, 'XDeviceTable', None))]
        return xs, ys

    def set_anchor(a, xs, ys):
        a.Format = 3
        a.XCoordinate, a.XDeviceTable = make_dev(xs)
        a.YCoordinate, a.YDeviceTable = make_dev(ys)

    base_anchor_y = {}                # (glyph, class) -> per-master y (pre-shift)
    mark_class = {}
    gpos = font['GPOS'].table
    m2b = []
    for lk in gpos.LookupList.Lookup:
        for st in lk.SubTable:
            if lk.LookupType == 9:
                st = st.ExtSubTable
            if getattr(st, 'LookupType', lk.LookupType) == 4:
                m2b.append(st)
    for st in m2b:
        for mi, mg in enumerate(st.MarkCoverage.glyphs):
            mark_class[mg] = st.MarkArray.MarkRecord[mi].Class
    vcaron_class = mark_class.get(VCARON)

    def anchor_shift(base, cls, ys, mi):
        if cls == vcaron_class and base in base_ymax:
            # ignore the anchor height: follow the stem top (d l stay, t rises)
            top = base_ymax[base][mi]
            return fns[mi](top) - top
        return fns[mi](ys[mi]) - ys[mi]

    for st in m2b:
        for bi, bg in enumerate(st.BaseCoverage.glyphs):
            if bg not in simple_lower:
                continue
            rec = st.BaseArray.BaseRecord[bi]
            for cls, a in enumerate(rec.BaseAnchor):
                if a is None:
                    continue
                xs, ys = anchor_masters(a)
                base_anchor_y[(bg, cls)] = ys
                sh = [anchor_shift(bg, cls, ys, mi) for mi in range(len(M.locs))]
                set_anchor(a, [x + s * slant for x, s in zip(xs, sh)],
                           [y + s for y, s in zip(ys, sh)])

    # ── G1c: composites built on lowercase bases ────────────────────
    moved = 0
    for name in font.getGlyphOrder():
        g = glyf[name]
        if not g.isComposite():
            continue
        comps = g.components
        if comps[0].glyphName not in lower:
            continue
        base = comps[0].glyphName
        masters = M.glyph_masters(name)
        new = [m.copy() for m in masters]
        changed = False
        for ci, c in enumerate(comps[1:], start=1):
            if c.glyphName in lower:
                continue
            cls = mark_class.get(c.glyphName)
            for mi in range(len(M.locs)):
                if cls is not None and (base, cls) in base_anchor_y:
                    s = anchor_shift(base, cls, base_anchor_y[(base, cls)], mi)
                else:
                    # unanchored component (e.g. ŀ's middle dot): its centre
                    # follows the remap
                    cm = M.glyph_masters(c.glyphName)[mi][:-4, 1]
                    cy = (cm.min() + cm.max()) / 2 + masters[mi][ci, 1]
                    s = fns[mi](cy) - cy
                new[mi][ci, 1] += s
                new[mi][ci, 0] += s * slant
                changed = changed or abs(s) > 0.5
        if changed:
            M.set_glyph_masters(name, new)
            moved += 1
    print(f"    remapped {len(simple_lower)} lowercase outlines, {moved} composites")

    # ── G1d: x-height metric (OS/2.sxHeight + MVAR xhgt) ────────────
    font['OS/2'].sxHeight = int(round(font['OS/2'].sxHeight * (1 + K)))
    if 'MVAR' in font:
        mvar = font['MVAR'].table
        for rec in mvar.ValueRecord:
            if rec.ValueTag == 'xhgt':
                outer, inner = rec.VarIdx >> 16, rec.VarIdx & 0xFFFF
                vd = mvar.VarStore.VarData[outer]
                vd.Item[inner] = [int(round(d * (1 + K))) for d in vd.Item[inner]]

    # ── G3: tighter round sidebearings ──────────────────────────────
    ref = instantiateVariableFont(TTFont(path), {'opsz': REF_OPSZ, 'wght': 400})
    # (sidebearings are unaffected by the vertical remap, so the saved file works)
    rgs = ref.getGlyphSet()
    _bp = BoundsPen(rgs); rgs['x'].draw(_bp); ref_xh = _bp.bounds[3]
    hmtx = font['hmtx']
    shift_x = {}
    for name, sides in ROUNDS.items():
        if name not in glyf:
            continue
        # measured on the de-slanted outline, so italic sidebearings are
        # read along the slant rather than off the descender tail
        bp = BoundsPen(rgs)
        rgs[name].draw(TransformPen(bp, (1, 0, -slant, 1, slant * ref_xh / 2, 0)))
        adv = ref['hmtx'][name][0]
        lsb, rsb = bp.bounds[0], adv - bp.bounds[2]
        dl = max(0, int(round(lsb * T))) if 'L' in sides else 0
        dr = max(0, int(round(rsb * T))) if 'R' in sides else 0
        shift_x[name] = (dl, dr)
    order = font.getGlyphOrder()
    simple_first = ([n for n in order if not glyf[n].isComposite()] +
                    [n for n in order if glyf[n].isComposite()])
    for name in simple_first:
        g = glyf[name]
        if name in shift_x:
            dl, dr = shift_x[name]
        elif g.isComposite() and g.components[0].glyphName in shift_x:
            dl, dr = shift_x[g.components[0].glyphName]
            shift_x[name] = (dl, dr)
        else:
            continue
        if g.isComposite():
            # the base component already moved with its own outline
            for c in g.components[1:]:
                c.x -= dl
        else:
            g.coordinates.translate((-dl, 0))
        g.recalcBounds(glyf)
        adv, _ = hmtx[name]
        hmtx[name] = (adv - dl - dr, g.xMin)
    for st in m2b:
        for bi, bg in enumerate(st.BaseCoverage.glyphs):
            if bg in shift_x:
                for a in st.BaseArray.BaseRecord[bi].BaseAnchor:
                    if a is not None:
                        a.XCoordinate -= shift_x[bg][0]
    print(f"    tightened round sides of {len(shift_x)} glyphs: " +
          ', '.join(f"{n} -{l}/-{r}" for n, (l, r) in shift_x.items() if '.' not in n and len(n) == 1))

    # ── Commit the new anchor variations into the GDEF VarStore ─────
    if new_rows:
        region_idx = [region_index(s) for s in M.model.supports[1:]]
        vd = buildVarData(region_idx, new_rows, optimize=False)
        store.VarData.append(vd)
        store.VarDataCount = len(store.VarData)
        outer = len(store.VarData) - 1
        for st in m2b:
            for rec in st.BaseArray.BaseRecord:
                for a in rec.BaseAnchor:
                    for dev in (getattr(a, 'XDeviceTable', None), getattr(a, 'YDeviceTable', None)):
                        if dev is not None and dev.StartSize == -1:
                            dev.StartSize = outer
        used = set()
        gdef.collect_device_varidxes(used)
        gpos.collect_device_varidxes(used)
        mapping = store.subset_varidxes(used)
        gdef.remap_device_varidxes(mapping)
        gpos.remap_device_varidxes(mapping)
        mapping = store.optimize()
        gdef.remap_device_varidxes(mapping)
        gpos.remap_device_varidxes(mapping)

    font.save(path)


for var_file in ['RSans-Variable.ttf', 'RSans-Italic-Variable.ttf']:
    print(f"  {var_file}:")
    apply_v2(os.path.join(BUILD, 'output', var_file))

print("  Proportion retune complete.")
RETUNE

# ── Step 3: Tune metrics ─────────────────────────────────────────────

echo "==> Tuning metrics..."
python3 - "$BUILD_DIR" << 'METRICS'
import os
import sys
from fontTools.ttLib import TTFont

BUILD = sys.argv[1]

# DM Sans ships with good metrics for reading:
#   sTypoAscender=992, sTypoDescender=-310, sTypoLineGap=0
#   → default line-height ≈ 1.302x (our target range)
#
# We ensure cross-platform consistency by aligning hhea with OS/2.
# The USE_TYPO_METRICS bit (fsSelection bit 7) is already set.

for var_file in ['RSans-Variable.ttf', 'RSans-Italic-Variable.ttf']:
    path = os.path.join(BUILD, 'output', var_file)
    font = TTFont(path)
    os2 = font['OS/2']
    hhea = font['hhea']

    # Ensure hhea matches usWin for cross-platform consistency
    hhea.ascent = os2.usWinAscent     # 1012
    hhea.descent = -os2.usWinDescent  # -310

    font.save(path)
    print(f"  {var_file}: hhea aligned (ascent={hhea.ascent}, descent={hhea.descent})")

print("  Metrics tuning complete.")
METRICS

# ── Step 4: Generate instances + disambiguation + metadata + WOFF2 ───

echo "==> Generating static instances..."
python3 - "$BUILD_DIR" "$OPSZ" << 'GENERATE'
import os
import sys
import array
import glob
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

BUILD = sys.argv[1]
OPSZ = float(sys.argv[2])

WEIGHTS = {
    'Thin': 100, 'ExtraLight': 200, 'Light': 300, 'Regular': 400,
    'Medium': 500, 'SemiBold': 600, 'Bold': 700, 'ExtraBold': 800,
}

# ── Disambiguation surgery ──────────────────────────────────────────
# Applied per-instance since adding points breaks gvar deltas.
# Each function adapts to the instance's actual glyph metrics.

def _stem_corners(coords):
    """Return (bl_x, tl_x, tr_x, br_x, y_top) for a stem glyph.

    Works for upright rectangles (slant 0) and italic parallelograms.
    Corners are taken from the points sitting on the baseline (y≈0) and
    the top edge (y≈y_top), so the stem's slant is preserved. All x/y are
    rounded to int to match fontTools integer bounding-box behavior.
    """
    y_top = int(round(max(y for x, y in coords)))
    top_pts = sorted((x, y) for x, y in coords if y >= y_top - 2)
    bot_pts = sorted((x, y) for x, y in coords if y <= 2)
    if len(top_pts) < 2 or len(bot_pts) < 2:
        return None
    return (int(round(bot_pts[0][0])), int(round(top_pts[0][0])),
            int(round(top_pts[-1][0])), int(round(bot_pts[-1][0])), y_top)

def disambiguate_I(font):
    """Add subtle serifs to uppercase 'I' for I/l distinction.

    Slant-aware: serifs follow the stem's actual slant, so the italic 'I'
    stays slanted instead of being rebuilt as an upright serifed bar.
    Serif dimensions scale with stem width. For upright instances this
    reproduces the previous plain-rectangle → serifed transform exactly.
    """
    glyf = font['glyf']
    g = glyf['I']
    if g.numberOfContours <= 0:
        return  # composite, skip

    corners = _stem_corners(list(g.coordinates))
    if corners is None:
        return  # unexpected topology, skip
    bl_x, tl_x, _tr_x, br_x, y_top = corners

    stem_w = br_x - bl_x
    slant = (tl_x - bl_x) / y_top if y_top else 0.0
    serif_ext = max(int(stem_w * 0.38), 20)   # ~30 units at Regular
    serif_h = max(int(stem_w * 0.22), 14)     # ~18 units at Regular

    def left_edge(y):
        return bl_x + slant * y

    def right_edge(y):
        return br_x + slant * y

    # New outline: serifed I (12 ON points, clockwise), each x offset by the
    # stem slant at its own height so the serifs ride the slanted stem.
    pts = [
        (left_edge(0) - serif_ext, 0),                              # bottom-left serif
        (left_edge(serif_h) - serif_ext, serif_h),
        (left_edge(serif_h), serif_h),
        (left_edge(y_top - serif_h), y_top - serif_h),              # top-left serif
        (left_edge(y_top - serif_h) - serif_ext, y_top - serif_h),
        (left_edge(y_top) - serif_ext, y_top),
        (right_edge(y_top) + serif_ext, y_top),                     # top-right serif
        (right_edge(y_top - serif_h) + serif_ext, y_top - serif_h),
        (right_edge(y_top - serif_h), y_top - serif_h),
        (right_edge(serif_h), serif_h),                             # bottom-right serif
        (right_edge(serif_h) + serif_ext, serif_h),
        (right_edge(0) + serif_ext, 0),
    ]
    new_coords = [(int(round(x)), int(round(y))) for x, y in pts]

    g.coordinates = type(g.coordinates)(new_coords)
    g.flags = array.array('B', [1] * 12)
    g.endPtsOfContours = [11]
    g.numberOfContours = 1
    g.recalcBounds(glyf)

    # Symmetric sidebearings around the serifed form.
    hmtx = font['hmtx']
    glyph_left = min(x for x, _ in new_coords)
    glyph_right = max(x for x, _ in new_coords)
    hmtx['I'] = (int(glyph_right + glyph_left), int(glyph_left))

def disambiguate_l(font):
    """Add a rightward tail to lowercase 'l' for l/1/I distinction.

    Slant-aware: reads the actual stem corners so the italic 'l' keeps its
    slanted parallelogram stem (instead of being rebuilt as an upright bar)
    and the tail curves off the slanted right edge. For upright instances
    this reproduces the previous tailed-l transform exactly.
    """
    glyf = font['glyf']
    g = glyf['l']
    if g.numberOfContours <= 0:
        return

    coords = list(g.coordinates)
    orig_xmin = int(round(min(x for x, _ in coords)))
    orig_xmax = int(round(max(x for x, _ in coords)))
    corners = _stem_corners(coords)
    if corners is None:
        return
    bl_x, tl_x, tr_x, br_x, y_top = corners

    stem_w = tr_x - tl_x                        # horizontal stem width (~84)
    slant = (tl_x - bl_x) / y_top if y_top else 0.0
    tail_len = max(int(stem_w * 0.65), 40)      # ~55 units at Regular
    curve_h = max(int(stem_w * 0.55), 35)       # height where curve starts

    def right_edge(y):
        return br_x + slant * y

    # New outline: l with tail (6 points: 5 ON + 1 OFF). The stem follows the
    # slant; the tail hooks rightward off the slanted right edge at the foot.
    pts = [
        (bl_x, 0),                                  # bottom-left
        (tl_x, y_top),                              # top-left
        (tr_x, y_top),                              # top-right
        (right_edge(curve_h), curve_h),             # down slanted right edge
        (br_x + tail_len // 3, curve_h // 4),       # OFF: curve control
        (br_x + tail_len, 0),                       # tail tip at baseline
    ]
    new_coords = [(int(round(x)), int(round(y))) for x, y in pts]
    new_flags = [1, 1, 1, 1, 0, 1]

    g.coordinates = type(g.coordinates)(new_coords)
    g.flags = array.array('B', new_flags)
    g.endPtsOfContours = [5]
    g.numberOfContours = 1
    g.recalcBounds(glyf)

    # Advance: grow only if the tail extends past the original right edge,
    # preserving the original right sidebearing.
    hmtx = font['hmtx']
    old_w, _ = hmtx['l']
    rsb = old_w - orig_xmax
    new_xmax = max(orig_xmax, br_x + tail_len)
    hmtx['l'] = (int(round(new_xmax + rsb)), orig_xmin)

def disambiguate_zero(font):
    """Add a center dot to zero for 0/O distinction.

    Adds a small circular contour inside the counter.
    """
    glyf = font['glyf']
    g = glyf['zero']
    if g.numberOfContours <= 0:
        return

    coords = list(g.coordinates)
    ends = list(g.endPtsOfContours)

    # Calculate center and dot size from glyph bounds
    cx = (g.xMin + g.xMax) // 2
    cy = (g.yMin + g.yMax) // 2
    glyph_w = g.xMax - g.xMin
    r = max(int(glyph_w * 0.065), 28)  # dot radius ~36 units

    # Dot contour: counter-clockwise (fills inside the clockwise counter)
    # 4 ON-curve cardinal points + 4 OFF-curve corner points
    dot_coords = [
        (cx, cy - r),       # bottom
        (cx - r, cy - r),   # OFF: bottom-left
        (cx - r, cy),       # left
        (cx - r, cy + r),   # OFF: top-left
        (cx, cy + r),       # top
        (cx + r, cy + r),   # OFF: top-right
        (cx + r, cy),       # right
        (cx + r, cy - r),   # OFF: bottom-right
    ]
    dot_flags = [1, 0, 1, 0, 1, 0, 1, 0]

    # Append dot contour
    all_coords = list(coords) + dot_coords
    all_flags = list(g.flags) + dot_flags
    new_ends = list(ends) + [ends[-1] + len(dot_coords)]

    g.coordinates = type(g.coordinates)(all_coords)
    g.flags = array.array('B', all_flags)
    g.endPtsOfContours = new_ends
    g.numberOfContours = len(new_ends)
    g.recalcBounds(glyf)


# ── Font metadata ───────────────────────────────────────────────────

def fix_metadata(font, weight_name, weight_val, is_italic):
    """Set correct name table entries, fsSelection, and macStyle.

    RIBBI grouping: Regular/Bold/Italic/BoldItalic use the base family name.
    Non-RIBBI weights get weight-specific family names in nameID 1/2,
    with nameID 16/17 providing the preferred (unified) family grouping.
    """
    name = font['name']
    os2 = font['OS/2']
    head = font['head']

    is_bold = weight_val >= 700
    is_ribbi = weight_name in ('Regular', 'Bold')

    # Determine RIBBI subfamily
    if is_bold and is_italic:
        ribbi_subfamily = 'Bold Italic'
    elif is_bold:
        ribbi_subfamily = 'Bold'
    elif is_italic:
        ribbi_subfamily = 'Italic'
    else:
        ribbi_subfamily = 'Regular'

    # Family name for RIBBI grouping
    if is_ribbi:
        ribbi_family = 'R Sans'
    else:
        ribbi_family = f'R Sans {weight_name}'

    # Preferred subfamily (nameID 17)
    if is_italic and weight_name != 'Regular':
        pref_subfamily = f'{weight_name} Italic'
    elif is_italic:
        pref_subfamily = 'Italic'
    else:
        pref_subfamily = weight_name

    # Full name and PostScript name
    if is_italic and weight_name == 'Regular':
        full_name = 'R Sans Italic'
        ps_name = 'RSans-Italic'
    elif is_italic:
        full_name = f'R Sans {weight_name} Italic'
        ps_name = f'RSans-{weight_name}Italic'
    else:
        full_name = f'R Sans {weight_name}'
        ps_name = f'RSans-{weight_name}'

    # Unique ID
    unique_id = f'RSans-{pref_subfamily.replace(" ", "")}'

    # Set name table entries for both platform 1 (Mac) and 3 (Windows)
    for plat_id, enc_id, lang_id in [(1, 0, 0), (3, 1, 0x0409)]:
        name.setName(ribbi_family, 1, plat_id, enc_id, lang_id)
        name.setName(ribbi_subfamily if is_ribbi else ('Italic' if is_italic else 'Regular'),
                     2, plat_id, enc_id, lang_id)
        name.setName(unique_id, 3, plat_id, enc_id, lang_id)
        name.setName(full_name, 4, plat_id, enc_id, lang_id)
        name.setName(ps_name, 6, plat_id, enc_id, lang_id)
        name.setName('R Sans', 16, plat_id, enc_id, lang_id)
        name.setName(pref_subfamily, 17, plat_id, enc_id, lang_id)

    # fsSelection
    fs = 0
    if is_italic:
        fs |= (1 << 0)    # bit 0: ITALIC
    if is_bold:
        fs |= (1 << 5)    # bit 5: BOLD
    if weight_name == 'Regular' and not is_italic:
        fs |= (1 << 6)    # bit 6: REGULAR
    fs |= (1 << 7)        # bit 7: USE_TYPO_METRICS (always set)
    os2.fsSelection = fs

    # macStyle
    mac = 0
    if is_bold:
        mac |= (1 << 0)   # bit 0: Bold
    if is_italic:
        mac |= (1 << 1)   # bit 1: Italic
    head.macStyle = mac

    # Weight class
    os2.usWeightClass = weight_val


# ── Generate instances ──────────────────────────────────────────────

print("  Generating 16 static instances...")

for var_file, is_italic in [('RSans-Variable.ttf', False),
                             ('RSans-Italic-Variable.ttf', True)]:
    var_path = os.path.join(BUILD, 'output', var_file)

    for wname, wval in WEIGHTS.items():
        font = TTFont(var_path)

        # Pin axes to create static instance
        instance = instantiateVariableFont(font, {'wght': wval, 'opsz': OPSZ})

        # Disambiguation surgery (on static instances only)
        disambiguate_I(instance)
        disambiguate_l(instance)
        disambiguate_zero(instance)

        # Fix metadata
        fix_metadata(instance, wname, wval, is_italic)

        # Output filename
        if is_italic:
            suffix = 'Italic' if wname == 'Regular' else f'{wname}Italic'
        else:
            suffix = wname
        out_path = os.path.join(BUILD, 'output', f'RSans-{suffix}.ttf')
        instance.save(out_path)
        print(f"    RSans-{suffix}.ttf")

# ── Convert to WOFF2 ───────────────────────────────────────────────

print("  Converting to WOFF2...")
for ttf_path in sorted(glob.glob(os.path.join(BUILD, 'output', 'RSans-*.ttf'))):
    basename = os.path.splitext(os.path.basename(ttf_path))[0]
    woff2_path = os.path.join(BUILD, 'output', f'{basename}.woff2')
    font = TTFont(ttf_path)
    font.flavor = 'woff2'
    font.save(woff2_path)
    print(f"    {basename}.woff2")

print("  All fonts generated.")
GENERATE

# ── Step 5: Copy to output directory ─────────────────────────────────

echo "==> Copying to output directory..."
mkdir -p "$SCRIPT_DIR/fonts" "$SCRIPT_DIR/web-fonts"

# Clean old files
rm -f "$SCRIPT_DIR/fonts/"RSans-*.ttf
rm -f "$SCRIPT_DIR/web-fonts/"RSans-*.woff2
rm -f "$SCRIPT_DIR/web-fonts/"RSans-*-Variable.ttf

# Static TTFs (exclude variable fonts)
for f in "$BUILD_DIR"/output/RSans-*.ttf; do
  basename="$(basename "$f")"
  case "$basename" in
    *Variable*) ;;
    *) cp "$f" "$SCRIPT_DIR/fonts/" ;;
  esac
done

# Web fonts: all WOFF2 + variable TTFs
cp "$BUILD_DIR"/output/RSans-*.woff2 "$SCRIPT_DIR/web-fonts/"
cp "$BUILD_DIR"/output/RSans-Variable.ttf "$SCRIPT_DIR/web-fonts/"
cp "$BUILD_DIR"/output/RSans-Italic-Variable.ttf "$SCRIPT_DIR/web-fonts/"

echo ""
echo "=== R Sans Build Complete ==="
echo "Static TTFs: $SCRIPT_DIR/fonts/"
echo "Web fonts:   $SCRIPT_DIR/web-fonts/"
echo ""
echo "Install system fonts: cp $SCRIPT_DIR/fonts/*.ttf ~/Library/Fonts/"
echo ""
echo "Design choices:"
echo "  Base:         DM Sans (by Colophon Foundry)"
echo "  Features:     ${FEATURES} (frozen into default glyphs)"
echo "  Surgery:      Terminal softening on 12 glyphs (c/e/s apertures opened)"
echo "  Retune (v2):  x-height x$(python3 -c "print(1 + $XHEIGHT_K)"), round sidebearings -${ROUND_SB_TIGHTEN}"
echo "  Disambig:     Serifed I, tailed l, dotted zero (static instances)"
echo "  Line height:  ~1.30x (DM Sans native, body text optimized)"
echo "  Optical size: ${OPSZ} (pinned for body text sweet spot)"
echo ""
echo "Preview: open $(dirname "$SCRIPT_DIR")/preview.html"
