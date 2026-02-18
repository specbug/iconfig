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
#    pulling terminal tips inward and rounding junctions for the warm,
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
DMSANS_REPO="https://github.com/google/fonts/raw/main/ofl/dmsans"

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
pip install -q fonttools brotli opentype-feature-freezer

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
python3 - "$BUILD_DIR" << 'SURGERY'
import os
import sys
from fontTools.ttLib import TTFont

BUILD = sys.argv[1]

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

def surgery_c(glyf):
    """Soften both terminal bars of 'c'.

    DM Sans 'c' has flat horizontal bars at the terminals.
    Upright: top bar pts 11-12, bottom bar pts 28-29.
    Italic has different topology — verify before applying.
    """
    g = glyf['c']
    c = list(g.coordinates)
    # Verify upright topology (32 points, bars at specific positions)
    if verify_points(c, [(11, 526, 361), (12, 440, 361), (28, 440, 165), (29, 526, 165)]):
        soften(c, [
            (10, -8, -4), (11, -16, -7), (12, 6, -3), (13, 4, -3),
            (27, 4, 3), (28, 6, 3), (29, -16, 7), (30, -8, 4),
        ])
        g.coordinates = type(g.coordinates)(c)
        g.recalcBounds(glyf)
        print("    'c': softened top + bottom terminals")
    else:
        # Italic or different topology: find terminal bars by searching
        # for horizontal ON-ON pairs near the right side of the glyph
        x_mid = (g.xMin + g.xMax) / 2
        y_mid = (g.yMin + g.yMax) / 2
        n = len(c)
        modified = False
        for i in range(n):
            x, y = c[i]
            if x > x_mid + (g.xMax - x_mid) * 0.6:
                # Point near right edge — potential terminal tip
                c[i] = (x - 12, y + (6 if y < y_mid else -6))
                modified = True
        if modified:
            g.coordinates = type(g.coordinates)(c)
            g.recalcBounds(glyf)
            print("    'c': softened terminals (adaptive)")
        else:
            print("    'c': skipped (unexpected topology)")

def surgery_e(glyf):
    """Soften the bottom-right terminal of 'e'."""
    g = glyf['e']
    c = list(g.coordinates)
    if verify_points(c, [(33, 424, 142), (34, 507, 142)]):
        soften(c, [
            (32, 4, 3), (33, 6, 4), (34, -15, 8), (35, -10, 5),
        ])
        g.coordinates = type(g.coordinates)(c)
        g.recalcBounds(glyf)
        print("    'e': softened terminal")
    else:
        # Adaptive: find the terminal bar (rightmost ON-ON horizontal pair
        # in the lower half of the glyph)
        y_mid = (g.yMin + g.yMax) / 2
        x_mid = (g.xMin + g.xMax) / 2
        n = len(c)
        modified = False
        for i in range(n):
            x, y = c[i]
            if y < y_mid and x > x_mid + (g.xMax - x_mid) * 0.5:
                c[i] = (x - 10, y + 5)
                modified = True
        if modified:
            g.coordinates = type(g.coordinates)(c)
            g.recalcBounds(glyf)
            print("    'e': softened terminal (adaptive)")
        else:
            print("    'e': skipped (unexpected topology)")

def surgery_s(glyf):
    """Soften both terminal bars of 's'."""
    g = glyf['s']
    c = list(g.coordinates)
    if verify_points(c, [(29, 443, 388), (30, 360, 388), (4, 44, 159), (5, 130, 159)]):
        soften(c, [
            (28, -6, -3), (29, -13, -5), (30, 5, -2), (31, 3, -2),
            (3, 6, 3), (4, 13, 5), (5, -5, 2), (6, -3, 2),
        ])
        g.coordinates = type(g.coordinates)(c)
        g.recalcBounds(glyf)
        print("    's': softened upper + lower terminals")
    else:
        print("    's': skipped (italic topology differs)")

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

def disambiguate_I(font):
    """Add subtle serifs to uppercase 'I' for I/l distinction.

    Transforms the plain rectangle into a serifed form.
    Serif dimensions scale with stem width.
    """
    glyf = font['glyf']
    g = glyf['I']
    if g.numberOfContours <= 0:
        return  # composite, skip

    coords = list(g.coordinates)
    # Current: rectangle (xMin,0) → (xMin,yMax) → (xMax,yMax) → (xMax,0)
    x_min, x_max = g.xMin, g.xMax
    y_min, y_max = 0, coords[1][1]  # baseline to cap height

    stem_w = x_max - x_min
    center = (x_min + x_max) // 2
    serif_ext = max(int(stem_w * 0.38), 20)   # ~30 units at Regular
    serif_h = max(int(stem_w * 0.22), 14)     # ~18 units at Regular

    sl = center - stem_w // 2 - serif_ext  # serif left edge
    sr = center + stem_w // 2 + serif_ext  # serif right edge

    # New outline: serifed I (12 ON points, clockwise)
    new_coords = [
        (sl, y_min), (sl, serif_h), (x_min, serif_h),       # bottom-left serif
        (x_min, y_max - serif_h), (sl, y_max - serif_h), (sl, y_max),  # top-left serif
        (sr, y_max), (sr, y_max - serif_h), (x_max, y_max - serif_h),  # top-right serif
        (x_max, serif_h), (sr, serif_h), (sr, y_min),       # bottom-right serif
    ]

    g.coordinates = type(g.coordinates)(new_coords)
    g.flags = array.array('B', [1] * 12)
    g.endPtsOfContours = [11]
    g.numberOfContours = 1
    g.recalcBounds(glyf)

    # Update advance width to accommodate serifs
    hmtx = font['hmtx']
    old_w, _ = hmtx['I']
    new_w = sr - sl + (sl - g.xMin) + (old_w - x_max)
    # Keep sidebearings symmetric
    new_lsb = sl
    hmtx['I'] = (max(old_w, sr - sl + abs(sl) + abs(sl)), new_lsb)

def disambiguate_l(font):
    """Add a rightward tail to lowercase 'l' for l/1/I distinction.

    Extends the bottom-right of the stem into a gentle curve.
    """
    glyf = font['glyf']
    g = glyf['l']
    if g.numberOfContours <= 0:
        return

    coords = list(g.coordinates)
    x_min, x_max = g.xMin, g.xMax
    y_max = coords[1][1]  # top of stem

    stem_w = x_max - x_min
    tail_len = max(int(stem_w * 0.65), 40)     # ~55 units at Regular
    curve_h = max(int(stem_w * 0.55), 35)      # height where curve starts

    # New outline: l with tail (6 points: 5 ON + 1 OFF)
    new_coords = [
        (x_min, 0),                             # bottom-left
        (x_min, y_max),                         # top-left
        (x_max, y_max),                         # top-right
        (x_max, curve_h),                       # stem going down to curve start
        (x_max + tail_len // 3, curve_h // 4),  # OFF: curve control
        (x_max + tail_len, 0),                  # tail tip at baseline
    ]
    new_flags = [1, 1, 1, 1, 0, 1]

    g.coordinates = type(g.coordinates)(new_coords)
    g.flags = array.array('B', new_flags)
    g.endPtsOfContours = [5]
    g.numberOfContours = 1
    g.recalcBounds(glyf)

    # Update advance width
    hmtx = font['hmtx']
    old_w, old_lsb = hmtx['l']
    new_right = x_max + tail_len
    new_w = new_right + (old_w - x_max)  # preserve right sidebearing ratio
    hmtx['l'] = (max(old_w, new_w), x_min)

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
echo "  Surgery:      Terminal softening on 12 glyphs"
echo "  Disambig:     Serifed I, tailed l, dotted zero (static instances)"
echo "  Line height:  ~1.30x (DM Sans native, body text optimized)"
echo "  Optical size: ${OPSZ} (pinned for body text sweet spot)"
echo ""
echo "Preview: open $(dirname "$SCRIPT_DIR")/preview.html"
