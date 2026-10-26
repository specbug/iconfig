#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# R Sans → CrossPoint Reader (.cpfont) for the Xteink X4 Pro
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# CrossPoint stores fonts as pre-rasterized 2-bit (4-level) glyph bitmaps,
# one file per point size holding all four styles, plus class kerning and
# ligatures. This script feeds R Sans through CrossPoint's own converter
# (fontconvert_sdcard.py, pinned below) with settings chosen for the X4
# Pro's panel. See DESIGN.md › "CrossPoint (.cpfont)" for the reasoning.
#
# ─── Spec ───────────────────────────────────────────────────────────
#
#   Source       web-fonts/RSans-Variable.ttf, RSans-Italic-Variable.ttf
#                (R Sans v2)
#   Sizes        12 14 16 18 pt  (CrossPoint's Small/Medium/Large/XL steps)
#   Weights      Regular & Italic 450, Bold & Bold Italic 700
#   Optical size per file: the physical size each point size renders at on
#                the panel = pt × 150 / 219 (converter DPI / panel PPI),
#                clamped to the axis minimum of 9:
#                  12 → 9   14 → 9.6   16 → 11   18 → 12.3
#   Hinting      FreeType auto-hinter (--force-autohint). R Sans ships no
#                hinting instructions, so the default path is unhinted and
#                x-height/baseline/stems land between pixel rows.
#   Coverage     latin-ext + reading + ipa-chars presets, trimmed by the converter to
#                the glyphs R Sans actually has.
#
#   Usage: ./build-cpfont.sh            (KEEP_BUILD=1 keeps the /tmp build:
#                                        instances + converter logs)
#   Output: cpfont/RSans/RSans_{12,14,16,18}.cpfont
#   Install: copy cpfont/RSans/ to /fonts/ (or /.fonts/) on the SD card,
#            or upload the files in the reader's web UI › Fonts.
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="/tmp/r-sans-cpfont-$$"

# ── Configuration ────────────────────────────────────────────────────
FAMILY="RSans"                 # letters/digits only; also the SD folder name
SIZES="12 14 16 18"            # pt; one .cpfont per size
REGULAR_WGHT=450               # matches Inter-as-shipped ink per line on the panel
BOLD_WGHT=700                  # heavier only widens; stems already saturate black
CONVERTER_DPI=150              # fontconvert_sdcard.py rasterizes at 150 DPI
PANEL_PPI=219                  # Xteink X4 / X4 Pro: 4.3", 480×800
OPSZ_MIN=9                     # R Sans opsz axis: 9–40
INTERVALS="latin-ext,reading,ipa-chars"
CROSSPOINT_REV="0727f9f035e09790a7696f3d7f4348e068037d2b"
CONVERTER_URL="https://raw.githubusercontent.com/crosspoint-reader/crosspoint-reader/${CROSSPOINT_REV}/lib/EpdFont/scripts"

cleanup() {
  [[ -n "${KEEP_BUILD:-}" ]] && { echo "Build kept at $BUILD_DIR"; return; }
  rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

echo "==> Setting up build environment..."
mkdir -p "$BUILD_DIR/converter" "$BUILD_DIR/instances" "$BUILD_DIR/out"
python3 -m venv "$BUILD_DIR/venv"
source "$BUILD_DIR/venv/bin/activate"
pip install -q "fonttools>=4.62.1" "freetype-py>=2.5.1"

echo "==> Fetching CrossPoint converter (${CROSSPOINT_REV:0:7})..."
for f in fontconvert_sdcard.py cpfont_version.py; do
  curl -sfL -o "$BUILD_DIR/converter/$f" "$CONVERTER_URL/$f"
done

# ── Step 1: Static instances, one optical size per point size ───────

echo "==> Instancing R Sans per size..."
python3 - "$SCRIPT_DIR" "$BUILD_DIR" "$SIZES" "$REGULAR_WGHT" "$BOLD_WGHT" \
  "$CONVERTER_DPI" "$PANEL_PPI" "$OPSZ_MIN" << 'INSTANCE'
import os
import sys
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

SRC, BUILD = sys.argv[1], sys.argv[2]
SIZES = [int(s) for s in sys.argv[3].split()]
REGULAR, BOLD = int(sys.argv[4]), int(sys.argv[5])
DPI, PPI, OPSZ_MIN = float(sys.argv[6]), float(sys.argv[7]), float(sys.argv[8])

styles = {
    'Regular':    ('RSans-Variable.ttf', REGULAR),
    'Bold':       ('RSans-Variable.ttf', BOLD),
    'Italic':     ('RSans-Italic-Variable.ttf', REGULAR),
    'BoldItalic': ('RSans-Italic-Variable.ttf', BOLD),
}

for size in SIZES:
    # Optical size = the physical point size this file renders at on the panel.
    opsz = max(OPSZ_MIN, round(size * DPI / PPI, 1))
    for style, (var_file, wght) in styles.items():
        font = TTFont(os.path.join(SRC, 'web-fonts', var_file))
        inst = instantiateVariableFont(font, {'wght': wght, 'opsz': opsz})
        inst.save(os.path.join(BUILD, 'instances', f'RSans-{size}-{style}.ttf'))
    print(f"  {size}pt: opsz {opsz:g}, wght {REGULAR}/{BOLD}")
INSTANCE

# ── Step 2: Convert to .cpfont ───────────────────────────────────────

echo "==> Converting to .cpfont..."
for size in $SIZES; do
  i="$BUILD_DIR/instances/RSans-$size"
  python3 "$BUILD_DIR/converter/fontconvert_sdcard.py" \
    --regular "$i-Regular.ttf" \
    --bold "$i-Bold.ttf" \
    --italic "$i-Italic.ttf" \
    --bolditalic "$i-BoldItalic.ttf" \
    --intervals "$INTERVALS" \
    --size "$size" \
    --force-autohint \
    --name "$FAMILY" \
    --output-dir "$BUILD_DIR/out/$FAMILY" 2> "$BUILD_DIR/convert-$size.log"
  grep -E "Validated|Kerning:|Ligatures:" "$BUILD_DIR/convert-$size.log" | sed 's/^/    /' | head -12
done

# ── Step 3: Copy to output directory ─────────────────────────────────

echo "==> Copying to output directory..."
rm -rf "$SCRIPT_DIR/cpfont/$FAMILY"
mkdir -p "$SCRIPT_DIR/cpfont"
cp -r "$BUILD_DIR/out/$FAMILY" "$SCRIPT_DIR/cpfont/"

echo ""
echo "=== R Sans .cpfont Build Complete ==="
ls -l "$SCRIPT_DIR/cpfont/$FAMILY"
echo ""
echo "Install: copy $SCRIPT_DIR/cpfont/$FAMILY/ to /fonts/ (or /.fonts/) on the SD card."
