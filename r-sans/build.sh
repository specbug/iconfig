#!/usr/bin/env bash
# R Sans — Custom Proportional Sans-Serif Font
# Reproducible build script
#
# Based on Inter 4.1, customized for body text reading (16-20px).
# Character variants: cv05 (tailed l), cv10 (spurred G), cv12 (compact f),
#                     cv13 (compact t), zero (slashed zero)
# Metrics: Line gap increased from 0 to 164 units (1.29x default line-height)
#
# Requirements: python3, gh (GitHub CLI)
# Usage: ./build.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="/tmp/r-sans-build-$$"
INTER_VERSION="4.1"
FEATURES="cv05,cv10,cv12,cv13,zero"
LINE_GAP=164
OPSZ=16.0

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
    os2.sTypoLineGap = LINE_GAP
    os2.usWinAscent = os2.sTypoAscender + (LINE_GAP // 2)
    os2.usWinDescent = abs(os2.sTypoDescender) + (LINE_GAP // 2)
    hhea.lineGap = LINE_GAP
    hhea.ascent = os2.usWinAscent
    hhea.descent = -os2.usWinDescent
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
echo "  Base: Inter ${INTER_VERSION}"
echo "  Features: ${FEATURES}"
echo "  Line gap: ${LINE_GAP} units (1.29x default line-height)"
echo "  Optical size: ${OPSZ}px (body text optimized)"
