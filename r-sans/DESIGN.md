# R Sans — Design Philosophy & Build Reference

> "Less, but better." — Dieter Rams

R Sans is a custom proportional sans-serif font optimized for body text reading at 16–20px. It transforms Inter from a UI font into a reading font through purposeful character variant selection and retuned vertical metrics.

---

## Aesthetic Lineage

**Base skeleton**: Inter 4.1 — proven kerning tables, language support, screen hinting, optical size axis. Downloaded from [GitHub releases](https://github.com/rsms/inter/releases) (not Google Fonts, which strips OpenType features).

**Target aesthetic** — the intersection of three voices:

| Influence | What we take | What we leave |
|-----------|-------------|---------------|
| **Google Sans Text** | Warmth, reading comfort, generous line spacing | The goofiness, brand coupling |
| **Söhne** | Intellectual restraint, confident geometry | The coldness, tight metrics |
| **Adobe Garamond Pro** | Classical reading rhythm, the sense that text *flows* | Serifs, ornamental details |

Filtered through the same Dieter Rams / Andy Matuschak design language as [R Mono](../r-mono/): circles and rectangles, heavy lines and negative space, simplified forms. Every deviation from stock Inter must earn its place.

**What R Sans is not**: It's not a display font, not a UI font, not a brand font. It's a reading font — optimized for the experience of sitting with a 2,000-word blog post and forgetting you're reading a screen.

---

## Design Decisions

### Why Inter (and not start from scratch)

Inter gives us:
- **2,548 glyphs** covering Latin, Cyrillic, Greek, Vietnamese
- **Kerning tables** refined over 8+ years of production use
- **Optical size axis** (14–32px) that subtly adjusts stroke contrast and spacing
- **Screen hinting** optimized for subpixel rendering

What Inter gets wrong for body text:
- Line metrics tuned for **UI labels** (11–14px), not paragraphs (16–20px)
- Default line-height of **1.21x** — too tight for sustained reading
- Character forms optimized for **scanning** (quick recognition), not **reading** (comfortable flow)

Our job is surgical: fix the metrics, choose the right character variants, preserve everything else.

### Character Variants — What We Changed and Why

We enable 5 features via [pyftfeatfreeze](https://github.com/twardoch/fonttools-opentype-feature-freezer). Each choice mirrors R Mono's philosophy for cross-family consistency.

| Feature | Glyph | Change | Rationale |
|---------|-------|--------|-----------|
| `cv05` | `l` (lowercase L) | Adds tail | **1/l/I disambiguation.** R Mono uses serifed-flat-tailed `l` — same principle. At body text size, tailed `l` is instantly distinct from `1` and `I`. |
| `cv10` | `G` (capital) | Adds crossbar spur | **G/C disambiguation.** R Mono uses toothed-serifless-hooked `G`. The spur is a tiny detail that prevents misreading at a glance. |
| `cv12` | `f` | Compact form | **Tighter, more geometric.** Less horizontal sprawl. Consistent with R Mono's flat-hook-serifless `f`. |
| `cv13` | `t` | Compact form | **Consistent with compact `f`.** The `f`/`t` pair should share terminal language. R Mono uses flat-hook `t`. |
| `zero` | `0` | Slashed | **0/O disambiguation.** Standard for any font used in technical contexts. R Mono uses dotted zero — slashed is the proportional convention. |

### Character Variants — What We Deliberately Skipped

| Feature | What it does | Why we skip it |
|---------|-------------|----------------|
| `cv11` | Single-storey `a` | **Double-storey is better for body text.** Single-storey `a` risks confusion with `o` at small sizes. R Mono uses double-storey upright for the same reason. |
| `ss01` | Open digits (6, 9) | **We chose closed digits in R Mono.** Consistency across the family. Closed forms are more geometric. |
| `cv01` | Alternate `1` | Evaluated — Inter's default `1` is already well-disambiguated in proportional context. |
| `cv09` | Flat-top `3` | Evaluated — more geometric but reduces the readability benefit of the curved top at body size. |
| `ss02` | Disambiguation set | Overlaps with our individual `cv` choices. Applying it would also enable changes we don't want. |

### Metrics Tuning — The Key Transformation

This is what makes R Sans a *reading* font instead of a UI font.

```
                    Inter stock     R Sans          Why
                    ──────────      ──────          ───
sTypoLineGap        0              164             +8% UPM breathing room
usWinAscent         1984           2066            Prevent clipping on Windows
usWinDescent        494            576             Prevent clipping on Windows
hhea.ascent         1984           2066            Match Win metrics for macOS
hhea.descent        -494           -576            Match Win metrics for macOS
hhea.lineGap        0              164             macOS line gap

Default line-height 1.21x          1.29x           Body text comfort zone
```

**Why 1.29x?** It sits precisely between Söhne (~1.25x, intellectual restraint) and Google Sans Text (~1.30x, reading comfort). At 16–18px, this gives paragraphs room to breathe without feeling loose or wasteful.

**Why line gap instead of inflating ascender/descender?**
1. Doesn't affect glyph clipping boundaries
2. CSS `line-height` overrides still work predictably
3. Extra space distributes evenly above and below the line
4. Ascender/descender values still accurately describe the glyph extent

**Unchanged metrics** (and why):

| Metric | Value | Rationale |
|--------|-------|-----------|
| `sTypoAscender` | 1984 | Glyph extent is correct — don't lie about it |
| `sTypoDescender` | -494 | Same |
| `sxHeight` | 1118 (0.546 UPM) | Inter's x-height is already generous for screen reading |
| `sCapHeight` | 1490 (0.728 UPM) | Proportional to x-height, no reason to change |
| UPM | 2048 | Standard; changing would require rescaling everything |

### Optical Size

Static instances are pinned to `opsz=16` — the center of our target range (16–20px). Inter's optical size axis adjusts:
- Stroke contrast (slightly higher at larger sizes)
- Spacing (slightly tighter at larger sizes)
- Detail (more refined at larger sizes)

At `opsz=16`, we get the body-text-optimized version of each glyph. The variable font retains the full `opsz` axis (14–32) for CSS `font-optical-sizing: auto` to work.

---

## Full Feature Reference

All Inter 4.1 OpenType features available in R Sans. Features marked **frozen** are baked into the default glyphs. All others remain toggleable via CSS `font-feature-settings` or application OpenType controls.

### Character Variants (cv01–cv14)

| Tag | Glyph | Description | Status |
|-----|-------|-------------|--------|
| `cv01` | `1` | Alternate one (no base serif) | Available |
| `cv02` | `4` | Open four | Available |
| `cv03` | `6` | Open six | Available |
| `cv04` | `9` | Open nine | Available |
| `cv05` | `l` | Lowercase L with tail | **Frozen on** |
| `cv06` | `ß` | Alternate Eszett | Available |
| `cv07` | `β` | Alternate beta | Available |
| `cv08` | `ΐ/ΰ` | Uppercase-style accent marks | Available |
| `cv09` | `3` | Flat-top three | Available |
| `cv10` | `G` | Capital G with spur | **Frozen on** |
| `cv11` | `a` | Single-storey a | Available (intentionally not frozen) |
| `cv12` | `f` | Compact f | **Frozen on** |
| `cv13` | `t` | Compact t | **Frozen on** |
| `cv14` | `ə` | Alternate schwa | Available |

### Stylistic Sets (ss01–ss08)

| Tag | Description | Status |
|-----|-------------|--------|
| `ss01` | Open digits (4, 6, 9) | Available |
| `ss02` | Disambiguation (1, l, I, 0, O) | Available |
| `ss03` | Rounded r, y | Available |
| `ss04` | Rounded i, l | Available |
| `ss05` | Round quotes | Available |
| `ss06` | German quotes | Available |
| `ss07` | Square quotes | Available |
| `ss08` | Belgian quotes | Available |

### Other Features

| Tag | Description | Status |
|-----|-------------|--------|
| `zero` | Slashed zero | **Frozen on** |
| `tnum` | Tabular (monospaced) figures | Available |
| `pnum` | Proportional figures | Available (default) |
| `frac` | Diagonal fractions | Available |
| `sups` | Superscripts | Available |
| `subs` | Subscripts | Available |
| `numr` | Numerators | Available |
| `dnom` | Denominators | Available |
| `ordn` | Ordinals | Available |
| `sinf` | Scientific inferiors | Available |
| `salt` | Stylistic alternates (all variants) | Available |
| `calt` | Contextual alternates | On by default |
| `case` | Case-sensitive forms | Available |
| `ccmp` | Glyph composition/decomposition | On by default |
| `dlig` | Discretionary ligatures | Available |

---

## Build System

### Requirements
- Python 3.11+
- [GitHub CLI](https://cli.github.com/) (`gh`)
- Internet access (downloads Inter from GitHub)

### Quick Build
```bash
cd r-sans/
./build.sh
```

The script creates an isolated venv, downloads Inter, applies all transformations, and outputs to `fonts/` and `web-fonts/`. Build artifacts go to `/tmp` and are cleaned up automatically.

### Manual Build (step by step)

```bash
# 1. Setup
python3 -m venv /tmp/r-sans-venv
source /tmp/r-sans-venv/bin/activate
pip install opentype-feature-freezer fonttools brotli

# 2. Download Inter 4.1
gh release download v4.1 --repo rsms/inter --pattern "Inter-4.1.zip" --dir /tmp/
unzip /tmp/Inter-4.1.zip -d /tmp/inter

# 3. Freeze character variants + rename
pyftfeatfreeze -f 'cv05,cv10,cv12,cv13,zero' \
  -R 'Inter Variable/R Sans' \
  /tmp/inter/InterVariable.ttf \
  /tmp/RSans-Variable.ttf

pyftfeatfreeze -f 'cv05,cv10,cv12,cv13,zero' \
  -R 'Inter Variable Italic/R Sans Italic' \
  /tmp/inter/InterVariable-Italic.ttf \
  /tmp/RSans-Italic-Variable.ttf

# 4. Tune metrics (Python)
python3 -c "
from fontTools.ttLib import TTFont
for path in ['/tmp/RSans-Variable.ttf', '/tmp/RSans-Italic-Variable.ttf']:
    font = TTFont(path)
    os2, hhea = font['OS/2'], font['hhea']
    os2.sTypoLineGap = 164
    os2.usWinAscent = os2.sTypoAscender + 82
    os2.usWinDescent = abs(os2.sTypoDescender) + 82
    hhea.lineGap = 164
    hhea.ascent = os2.usWinAscent
    hhea.descent = -os2.usWinDescent
    font.save(path)
"

# 5. Generate static instances
python3 -c "
from fontTools.ttLib import TTFont
from fontTools.varLib.mutator import instantiateVariableFont
weights = {'Thin':100,'ExtraLight':200,'Light':300,'Regular':400,
           'Medium':500,'SemiBold':600,'Bold':700,'ExtraBold':800}
for var, italic in [('RSans-Variable.ttf',False),('RSans-Italic-Variable.ttf',True)]:
    for name, val in weights.items():
        font = TTFont(f'/tmp/{var}')
        inst = instantiateVariableFont(font, {'wght':val, 'opsz':16.0})
        suffix = ('Italic' if name=='Regular' else f'{name}Italic') if italic else name
        inst.save(f'/tmp/RSans-{suffix}.ttf')
"

# 6. Convert to WOFF2
python3 -c "
import glob
from fontTools.ttLib import TTFont
for p in glob.glob('/tmp/RSans-*.ttf'):
    f = TTFont(p)
    f.flavor = 'woff2'
    f.save(p.replace('.ttf','.woff2'))
"
```

---

## Refinement Guide

### Adjusting Line Metrics

The single most impactful parameter. Change `LINE_GAP` in `build.sh` or the manual step:

| Line gap | Default line-height | Feel |
|----------|-------------------|------|
| 0 | 1.21x | Stock Inter — tight, UI-density |
| 82 | 1.25x | Söhne territory — restrained but readable |
| **164** | **1.29x** | **R Sans default — body text sweet spot** |
| 205 | 1.31x | Google Sans Text territory — generous |
| 246 | 1.33x | Approaching book typography |

Remember: CSS `line-height: 1.6` overrides the font's default. The line gap primarily affects apps that use the font's natural line spacing (native apps, text editors, Slack, Notes).

### Changing Character Variants

Edit the `-f` flag in the `pyftfeatfreeze` command:

```bash
# Current: cv05,cv10,cv12,cv13,zero
# To add single-storey 'a':
pyftfeatfreeze -f 'cv05,cv10,cv11,cv12,cv13,zero' -R 'Inter Variable/R Sans' ...

# To add open digits (matching ss01):
pyftfeatfreeze -f 'cv02,cv03,cv04,cv05,cv10,cv12,cv13,zero' -R 'Inter Variable/R Sans' ...

# To add full disambiguation set:
pyftfeatfreeze -f 'cv05,cv10,cv12,cv13,ss02,zero' -R 'Inter Variable/R Sans' ...
```

**Evaluating variants visually**: Before freezing, test in CSS:
```css
.test-cv11 { font-feature-settings: 'cv11' 1; }  /* single-storey a */
.test-ss01 { font-feature-settings: 'ss01' 1; }  /* open digits */
```

### Changing Optical Size

The `opsz` parameter in instance generation controls which optical size master to use:

| opsz | Optimized for | Character |
|------|--------------|-----------|
| 14 | Inter's default — small UI text | Slightly more open spacing, lower contrast |
| **16** | **R Sans default — body text** | **Balanced** |
| 20 | Subheadings | Slightly tighter, more refined |
| 28 | Display text | Tightest spacing, highest contrast |

For variable web fonts, let the browser choose:
```css
body { font-optical-sizing: auto; }     /* browser picks based on font-size */
body { font-variation-settings: 'opsz' 18; }  /* force specific value */
```

### Generating Fewer Weights

If you only need Regular/Medium/Bold (smaller total file size):

```python
weights = {'Regular': 400, 'Medium': 500, 'Bold': 700}
```

Or use the variable font directly — one file covers all weights.

### Creating a New Font from Inter

To create a sibling font (e.g., "R Display" for headings):

```bash
# 1. Different features for display use
pyftfeatfreeze -f 'cv11,cv10,ss01,zero' \
  -R 'Inter Variable/R Display' \
  InterVariable.ttf RDisplay-Variable.ttf

# 2. Tighter line gap for headings (or zero)
# Change LINE_GAP to 0 in the metrics step

# 3. Higher optical size for display
# Change opsz to 28 in instance generation
```

---

## Web Deployment

### Variable Font (Recommended)

```css
@font-face {
  font-family: 'R Sans';
  src: url('/fonts/RSans-Variable.woff2') format('woff2');
  font-weight: 100 900;
  font-display: swap;
}

@font-face {
  font-family: 'R Sans';
  src: url('/fonts/RSans-Italic-Variable.woff2') format('woff2');
  font-weight: 100 900;
  font-style: italic;
  font-display: swap;
}

body {
  font-family: 'R Sans', system-ui, -apple-system, sans-serif;
  font-optical-sizing: auto;
  letter-spacing: 0.01em;   /* Slight tracking for reading comfort */
  line-height: 1.6;         /* Override default for web — more generous than 1.29 */
}
```

### Static Fonts (Maximum Compatibility)

```css
@font-face {
  font-family: 'R Sans';
  src: url('/fonts/RSans-Regular.woff2') format('woff2');
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: 'R Sans';
  src: url('/fonts/RSans-Italic.woff2') format('woff2');
  font-weight: 400;
  font-style: italic;
  font-display: swap;
}

@font-face {
  font-family: 'R Sans';
  src: url('/fonts/RSans-Medium.woff2') format('woff2');
  font-weight: 500;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: 'R Sans';
  src: url('/fonts/RSans-Bold.woff2') format('woff2');
  font-weight: 700;
  font-style: normal;
  font-display: swap;
}

/* Add more weights/styles as needed */
```

---

## Cross-Family Consistency with R Mono

R Sans and R Mono share a design philosophy. Key parallels:

| Decision | R Mono (code) | R Sans (prose) | Shared principle |
|----------|--------------|----------------|-----------------|
| Double-storey `a` (upright) | `double-storey-toothless-corner` | Stock Inter (double-storey) | Body text disambiguation |
| Tailed `l` | `serifed-flat-tailed` | `cv05` (tailed) | 1/l/I clarity |
| Spurred `G` | `toothed-serifless-hooked` | `cv10` (spurred) | G/C clarity |
| Compact `f`/`t` | `flat-hook-serifless` / `flat-hook` | `cv12` / `cv13` | Geometric restraint |
| Zero disambiguation | Dotted (`zero = "dotted"`) | Slashed (`zero` feature) | Convention per context |
| Closed digits | 4, 6, 9 closed contours | Not frozen (available via ss01) | Mono needs it more |
| Line spacing | JB Mono width (600 units) | Line gap 164 (1.29x) | "Room to breathe" |

**Pairing in CSS:**
```css
body      { font-family: 'R Sans', system-ui, sans-serif; }
code, pre { font-family: 'R Mono', 'JetBrains Mono', monospace; }
```

---

## Verification Checklist

After building or modifying R Sans:

- [ ] **Disambiguation**: Set as system font, type `Il1| 0O` at 16px — all six characters should be instantly distinct
- [ ] **Reading comfort**: Open a 2,000+ word article in Safari/Chrome with R Sans at 16–18px. Read for 10 minutes. Note any fatigue or distraction
- [ ] **Line spacing**: In Notes.app or Slack (which use default font metrics, not CSS), does text feel comfortably spaced?
- [ ] **Weight range**: Check Regular (body), Medium (subheads), Bold (emphasis) at 16px — do they form a clear hierarchy?
- [ ] **Italic contrast**: In a Markdown preview with `*italic*` text, is the italic noticeable but not jarring?
- [ ] **Cross-platform**: If testing on multiple devices, check that text doesn't clip vertically (the Win metrics adjustment prevents this)

---

## Future Directions

### Terminal Softening (Step 6 from original plan)

If R Sans still feels too much like "Inter with different defaults," the next step is softening specific glyph terminals using FontForge:

**Candidates for softening** (toward Google Sans Text's warmth):
- `a` — the connection between bowl and stem
- `c` — the terminal endpoints
- `e` — the terminal of the crossbar
- `s` — both terminal endpoints

This requires manual glyph editing in FontForge and real type design judgment. The font would need to be opened as a UFO or SFD, terminals adjusted with Bézier handles, then re-exported. This is a significant step beyond the automated build.

### Subsetted Web Fonts

For maximum web performance, generate Latin-only subsets:
```bash
pip install fonttools[woff]
pyftsubset RSans-Variable.woff2 \
  --unicodes="U+0000-007F,U+00A0-00FF,U+2000-206F,U+20AC,U+2122" \
  --layout-features='*' \
  --flavor=woff2 \
  --output-file=RSans-Variable-latin.woff2
```

### Variable Font Slicing

To create a weight-restricted variable font (e.g., 300–700 only):
```bash
fonttools varLib.instancer RSans-Variable.ttf wght=300:700 -o RSans-Variable-trimmed.ttf
```

---

## Technical Specs

| Property | Value |
|----------|-------|
| Base font | Inter 4.1 (variable, from GitHub releases) |
| UPM | 2048 |
| x-height | 1118 (0.546 UPM) |
| Cap height | 1490 (0.728 UPM) |
| Ascender | 1984 (0.969 UPM) |
| Descender | -494 (-0.241 UPM) |
| Line gap | 164 (0.080 UPM) |
| Default line-height | 1.29x |
| Variable axes | `wght` (100–900), `opsz` (14–32) |
| Static instance opsz | 16 |
| Frozen features | cv05, cv10, cv12, cv13, zero |
| Glyph count | ~2,548 |
| Language support | Latin, Cyrillic, Greek, Vietnamese |
| Weights | Thin (100) through ExtraBold (800) |
| Styles | Upright + Italic for each weight |
| Static files | 16 TTF + 16 WOFF2 |
| Variable files | 2 TTF + 2 WOFF2 (upright + italic) |
| Build tool | pyftfeatfreeze + fonttools |
| License | SIL Open Font License 1.1 (inherited from Inter) |
