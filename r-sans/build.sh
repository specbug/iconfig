#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# R Sans — A custom proportional sans-serif
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
# Aesthetic lineage:
#   Inter (mechanical precision) + Google Sans (geometric warmth)
#   + iA Writer Quattro (humanist readability) + Circular (confident geometry)
#   + SF Pro Text (system-grade polish)
#
# Where R Mono is built for code — monospaced, dense, disambiguating —
# R Sans is its proportional sibling for prose, UI, and long-form reading.
# They share a design language: softened geometry, purposeful disambiguation,
# warmth without whimsy, and Rams-inspired restraint.
#
# ─── What Makes R Sans ≠ Stock Inter ─────────────────────────────────
#
# 1. SINGLE-STOREY 'a' (cv11) — The signature move.
#    The geometric, one-bowl 'a' is what separates "designed" from "default."
#    Futura, Circular, Google Sans, Century Gothic — every geometric sans
#    worth its salt uses single-storey 'a'. Inter's double-storey default
#    is why it reads as neutral-to-generic. This one change transforms it.
#    Echoes R Mono's toothless-corner 'a' bowl philosophy.
#
# 2. DISAMBIGUATION SET (cv05 + cv08 + zero)
#    Tailed 'l' to distinguish from '1' and 'I'. Serifed uppercase 'I'
#    for instant recognition in body text. Slashed zero for 0/O clarity.
#    These aren't stylistic flourishes — they're functional necessities
#    that match R Mono's disambiguation rigor.
#
# 3. GEOMETRIC DIGIT REFINEMENT (cv01 + cv09)
#    Alternate '1' with distinctive flag. Flat-top '3' for cleaner geometry.
#    Combined with the default closed '4', '6', '9' — the digit set reads
#    as a cohesive geometric family, just like R Mono's closed contours.
#
# 4. COMPACT LETTERFORMS (cv12 + cv13)
#    Compact 'f' and 't' — tighter horizontal footprint without sacrificing
#    readability. These reduce the "loose" feeling that makes Inter feel
#    like a system font. More economical, more intentional.
#
# 5. STRUCTURAL DETAILS (cv10 + ss03)
#    Spurred 'G' adds the structural tooth that aids recognition at small sizes.
#    Round quotes & commas (ss03) replace Inter's angular punctuation with
#    warmer, softer forms — the typographic equivalent of R Mono's
#    "softened terminals on a geometric base."
#
# 6. TYPOGRAPHIC POLISH (dlig)
#    Discretionary ligatures: fi, fl, ff, ffi, fft. Most sans-serifs
#    don't ship with ligatures. These add the kind of quiet refinement
#    that separates a curated font from a commodity typeface. When you
#    see "difficult" or "affluent" set with proper ligatures, the
#    difference is subtle but unmistakable.
#
# 7. READING-OPTIMIZED METRICS
#    Optical size pinned to 16px (body text sweet spot).
#    Line gap increased to 164 units (~1.29× default line-height).
#    These aren't visible changes — they're felt over hours of reading.
#
# ─── Feature Map ─────────────────────────────────────────────────────
#
#   cv01  Alternate '1'        — distinctive flag, matches geometric digits
#   cv05  Tailed 'l'           — l/1/I disambiguation
#   cv08  Serifed 'I'          — I/l disambiguation in proportional text
#   cv09  Flat-top '3'         — cleaner geometry
#   cv10  Spurred 'G'          — structural clarity at small sizes
#   cv11  Single-storey 'a'    — THE signature geometric form
#   cv12  Compact 'f'          — tighter, more intentional
#   cv13  Compact 't'          — tighter, more intentional
#   ss03  Round quotes/commas  — warmth in punctuation
#   zero  Slashed zero         — 0/O disambiguation
#   dlig  Ligatures fi fl ff   — typographic refinement
#
# ─── Build Instructions ──────────────────────────────────────────────
#
#   Requirements: python3, gh (GitHub CLI)
#   Usage: ./build.sh
#
#   Preview: open ../preview.html in a browser to test features
#            interactively before rebuilding.
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="/tmp/r-sans-build-$$"
INTER_VERSION="4.1"

# ── Feature selection ─────────────────────────────────────────────────
# Core personality: single-storey a, tailed l, serifed I, spurred G
# Digit refinement: alternate 1, flat-top 3
# Compactness: compact f, compact t
# Warmth: round quotes & commas
# Polish: slashed zero, discretionary ligatures
FEATURES="cv01,cv05,cv08,cv09,cv10,cv11,cv12,cv13,ss03,zero,dlig"

# ── Metric tuning ─────────────────────────────────────────────────────
LINE_GAP=164           # ~1.29x default line-height for comfortable reading
OPSZ=16.0              # Optical size: body text optimized (16-20px sweet spot)

cleanup() {
  rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

echo "==> Setting up build environment..."
mkdir -p "$BUILD_DIR"
python3 -m venv "$BUILD_DIR/venv"
source "$BUILD_DIR/venv/bin/activate"
pip install -q opentype-feature-freezer fonttools brotli

echo "==> Downloading Inter ${INTER_VERSION}..."
gh release download "v${INTER_VERSION}" --repo rsms/inter \
  --pattern "Inter-${INTER_VERSION}.zip" --dir "$BUILD_DIR/"
unzip -q "$BUILD_DIR/Inter-${INTER_VERSION}.zip" -d "$BUILD_DIR/inter-release"

echo "==> Applying character variants (${FEATURES})..."
mkdir -p "$BUILD_DIR/output"
pyftfeatfreeze -f "$FEATURES" -R 'Inter Variable/R Sans' \
  "$BUILD_DIR/inter-release/InterVariable.ttf" \
  "$BUILD_DIR/output/RSans-Variable.ttf"
pyftfeatfreeze -f "$FEATURES" -R 'Inter Variable Italic/R Sans Italic' \
  "$BUILD_DIR/inter-release/InterVariable-Italic.ttf" \
  "$BUILD_DIR/output/RSans-Italic-Variable.ttf"

echo "==> Tuning metrics and generating instances..."
python3 - "$BUILD_DIR" "$LINE_GAP" "$OPSZ" << 'PYEOF'
import os
import sys
import glob
from fontTools.ttLib import TTFont
from fontTools.varLib.mutator import instantiateVariableFont

BUILD = sys.argv[1]
LINE_GAP = int(sys.argv[2])
OPSZ = float(sys.argv[3])

WEIGHTS = {
    'Thin': 100, 'ExtraLight': 200, 'Light': 300, 'Regular': 400,
    'Medium': 500, 'SemiBold': 600, 'Bold': 700, 'ExtraBold': 800,
}

# --- Tune metrics on variable fonts ---
print("  Tuning line metrics...")
for var_file in ['RSans-Variable.ttf', 'RSans-Italic-Variable.ttf']:
    path = os.path.join(BUILD, 'output', var_file)
    font = TTFont(path)
    os2 = font['OS/2']
    hhea = font['hhea']
    name = font['name']

    # Line spacing: generous gap for sustained reading comfort
    os2.sTypoLineGap = LINE_GAP
    os2.usWinAscent = os2.sTypoAscender + (LINE_GAP // 2)
    os2.usWinDescent = abs(os2.sTypoDescender) + (LINE_GAP // 2)
    hhea.lineGap = LINE_GAP
    hhea.ascent = os2.usWinAscent
    hhea.descent = -os2.usWinDescent

    # Update font description in name table
    for record in name.names:
        try:
            text = record.toStr()
            if 'Inter' in text:
                record.string = text.replace('Inter', 'R Sans')
        except:
            pass

    font.save(path)
    print(f"    {var_file}: lineGap={LINE_GAP}")

# --- Generate static instances ---
print("  Generating static instances...")
for var_file, italic in [('RSans-Variable.ttf', False), ('RSans-Italic-Variable.ttf', True)]:
    for wname, wval in WEIGHTS.items():
        font = TTFont(os.path.join(BUILD, 'output', var_file))
        instance = instantiateVariableFont(font, {'wght': wval, 'opsz': OPSZ})
        if italic:
            suffix = 'Italic' if wname == 'Regular' else f'{wname}Italic'
        else:
            suffix = wname
        outpath = os.path.join(BUILD, 'output', f'RSans-{suffix}.ttf')
        instance.save(outpath)
        print(f"    RSans-{suffix}.ttf")

# --- Convert to WOFF2 ---
print("  Converting to WOFF2...")
for ttf_path in sorted(glob.glob(os.path.join(BUILD, 'output', 'RSans-*.ttf'))):
    basename = os.path.splitext(os.path.basename(ttf_path))[0]
    woff2_path = os.path.join(BUILD, 'output', f'{basename}.woff2')
    font = TTFont(ttf_path)
    font.flavor = 'woff2'
    font.save(woff2_path)
    print(f"    {basename}.woff2")

print("  All fonts generated.")
PYEOF

echo "==> Copying to output directory..."
mkdir -p "$SCRIPT_DIR/fonts" "$SCRIPT_DIR/web-fonts"

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
echo "  Base:     Inter ${INTER_VERSION}"
echo "  Features: ${FEATURES}"
echo "  Line gap: ${LINE_GAP} units (~1.29x default line-height)"
echo "  Optical:  ${OPSZ}px (body text optimized)"
echo ""
echo "Preview: open $(dirname "$SCRIPT_DIR")/preview.html"
