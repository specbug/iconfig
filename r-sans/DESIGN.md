# R Sans — Design Philosophy & Build Reference

> "Less, but better." — Dieter Rams

R Sans is a warm geometric reading font built on DM Sans. It sits between Anthropic's Styrene B (rounded, warm, slightly squishy) and Google Sans Text (geometric, clean, body-text optimized). Optimized for body text reading at 16–20px.

---

## Aesthetic Lineage

**Base skeleton**: DM Sans by Colophon Foundry — the same team behind Google Sans Text. Geometric DNA, optical size axis (9–40), designed for body text. Downloaded from [Google Fonts GitHub](https://github.com/google/fonts/tree/main/ofl/dmsans).

**Target aesthetic** — the intersection of three voices:

| Influence | What we take | What we leave |
|-----------|-------------|---------------|
| **Styrene B** | Warmth, rounded terminals, slightly organic feel | The full rounded-sans treatment |
| **Google Sans Text** | Geometric clarity, reading comfort, generous metrics | The goofiness, brand coupling |
| **Söhne** | Intellectual restraint, confident geometry | The coldness, tight metrics |

Filtered through the same Dieter Rams / Andy Matuschak design language as [R Mono](../r-mono/): circles and rectangles, heavy lines and negative space, simplified forms.

**What R Sans is not**: It's not a display font, not a UI font, not a brand font. It's a reading font — optimized for the experience of sitting with a 2,000-word blog post and forgetting you're reading a screen.

---

## Why DM Sans (and not Inter)

The previous version of R Sans used Inter 4.1 as its base. Despite aggressive character variant selection and glyph surgery on 'e' and 't', it still read as "Inter with tweaks" — because Inter's neo-grotesque DNA fights geometric warmth at every turn.

DM Sans was chosen because:
- **Same design team as Google Sans Text** — Colophon Foundry built both
- **Geometric from birth** — no fighting neo-grotesque DNA
- **Optical size axis** (9–40) — auto-switches to double-storey 'a'/'g' at text sizes
- **Body text optimized** — generous metrics (~1.30x default line-height)
- **1000 UPM** — standard for Google Fonts ecosystem

What we gave up moving from Inter:
- Fewer glyphs (~486 vs ~2,548) — no Cyrillic, limited Greek
- Fewer OpenType features — no cv01–cv14 character variants
- Narrower weight range for opsz axis control

The tradeoff is worth it: DM Sans gets us 80% to the target aesthetic without surgery. The remaining 20% — warmth via terminal softening, disambiguation, and proper metadata — is what the build system handles.

---

## Design Decisions

### Terminal Softening — The Core Transformation

DM Sans has clean, geometric terminals with flat horizontal cuts at stroke endings. R Sans softens 12 key glyphs by tapering terminal tips and rounding junctions, creating the warm, slightly organic feel of Styrene B while preserving DM Sans's geometric clarity. Since v2, the `c`/`e`/`s` cuts also move away from the counter, so the softening opens the apertures instead of closing them.

All adjustments are 5–18 units on a 1000 UPM grid — subtle individually, but cumulative across all glyphs.

| Glyph | Surgery | Effect |
|-------|---------|--------|
| **c** | Taper top + bottom terminals, lift cuts away from the counter | Softer endings, open aperture |
| **e** | Taper bottom-right terminal, drop it away from the counter | More open, welcoming aperture |
| **s** | Taper upper + lower terminals, open both apertures | Less mechanical, warmer curves |
| **t** | Soften bottom hook | Gentler terminal, less angular |
| **f** | Round top hook cap corners | Softer, less boxy hook |
| **a** | Soften stem-bowl junction | Smoother connection point |
| **r** | Round branch terminal corner | Less abrupt cutoff |
| **n** | Push arch shoulder outward | Warmer, more generous arch |
| **u** | Push bowl-stem junction outward | Consistent with 'n' treatment |
| **g** | Round ear corners | Softer ear shape |
| **j** | Soften bottom hook curve | Gentler descender |
| **y** | Taper descender terminal | Less flat ending |

**Technical implementation**: fontTools `glyf` table coordinate manipulation on the variable font default master. gvar deltas (weight/opsz variations) are preserved automatically since we only modify existing point coordinates, never add/remove points.

For the italic variable font, `c` and `e` share the upright topology shifted by one and two points, and `s` shares it exactly, so all three get the same explicit, verified edits; the italic `a` differs and is skipped. Glyphs with matching topology (f, g, j, n, r, t, u, y) receive identical treatment.

Note: `ss04` is frozen, so the visible `u` is `u.ss04`; `surgery_u` edits the unused `u` glyph and has no visible effect.

### Disambiguation — I/l/1 and 0/O

DM Sans's default 'I' and 'l' are nearly identical rectangles (84-unit stems, differing only by 20 units in height). At 16px, they're indistinguishable. Zero and O differ only in width.

Applied to **static instances only** (adding/removing points breaks gvar deltas):

| Glyph | Change | Approach |
|-------|--------|----------|
| **I** (uppercase) | Subtle serifs | 12-point serifed outline, proportional to stem width |
| **l** (lowercase) | Rightward tail | 6-point outline with quadratic curve at bottom-right |
| **0** (zero) | Center dot | 8-point circular contour added inside counter |
| **1** (one) | No change needed | DM Sans '1' already has distinctive flag |

The variable fonts retain DM Sans's default disambiguation (width differences only). Use CSS `font-feature-settings` for web-based disambiguation if needed.

### Metrics — Already Optimized

DM Sans ships with excellent reading metrics:

```
                    DM Sans stock    R Sans          Why
                    ─────────────    ──────          ───
sTypoAscender       992             992             Glyph extent is correct
sTypoDescender      -310            -310            Same
sTypoLineGap        0               0               Already ~1.30x line-height
usWinAscent         1012            1012            Clipping prevention on Windows
usWinDescent        310             310             Same
hhea.ascent         992 → 1012      1012            Aligned with usWin for Mac
hhea.descent        -310            -310            Consistent
hhea.lineGap        0               0               Matches OS/2

Default line-height  1.30x          1.30x           Body text sweet spot
UPM                  1000           1000            Google Fonts standard
```

The only metric change is aligning `hhea.ascent` with `usWinAscent` (992 → 1012) for cross-platform consistency. The USE_TYPO_METRICS bit (fsSelection bit 7) is preserved.

### Optical Size

Static instances are pinned to `opsz=14` — the body text sweet spot within DM Sans's 9–40 range. At this value:
- Double-storey 'a' and 'g' are used (better for body text)
- Stroke contrast is optimized for 14–18px rendering
- Spacing is balanced between tight (display) and open (small text)

The variable font retains the full `opsz` axis (9–40) for CSS `font-optical-sizing: auto` to work.

### Font Metadata

Each static instance gets proper RIBBI grouping:

| Weight | nameID 1 (Family) | nameID 2 (Subfamily) | nameID 16 (Pref Family) | nameID 17 (Pref Subfamily) |
|--------|-------------------|---------------------|------------------------|---------------------------|
| Regular | R Sans | Regular | R Sans | Regular |
| Bold | R Sans | Bold | R Sans | Bold |
| Italic | R Sans | Italic | R Sans | Italic |
| Bold Italic | R Sans | Bold Italic | R Sans | Bold Italic |
| Light | R Sans Light | Regular | R Sans | Light |
| Light Italic | R Sans Light | Italic | R Sans | Light Italic |
| ... | ... | ... | ... | ... |

`fsSelection` bits: Bold (bit 5) for wght≥700, Italic (bit 0), Regular (bit 6) only for Regular, USE_TYPO_METRICS (bit 7) always set.

`macStyle` bits: Bold (bit 0) for wght≥700, Italic (bit 1).

---

## v2: Proportion and Rhythm Retune

v1 R Sans read well but a little older and wider than the faces it sits beside on sixeleven. Measured against Google Sans Text (the OFL Google Sans at `opsz=17, GRAD=0`) at wght 400 / opsz 17, the causes were concrete:

1. **Short x-height, wide letters.** Lowercase was ~5% shorter relative to the em and ~7% wider relative to its own x-height.
2. **Loose rounds.** Space around `o c e d b p q` was ~20% looser than the references, leaving holes in the rhythm.
3. **More contrast.** Thin horizontals (0.84) read slightly spindly.
4. **Softening closed the apertures.** v1 pulled the `c`/`e`/`s` terminal tips *toward the counter*, so `c` and `e` ended up more closed than stock DM Sans.

v2 fixes these as proportions and rhythm, never shapes: no outline is borrowed from a reference.

### What changed

| Step | Change | Implementation |
|------|--------|----------------|
| **G1** x-height | Lowercase ×1.048 (`XHEIGHT_K`) | Piecewise-linear vertical remap: y≤0 fixed; 0…1.03×x-height scales; above that compresses so ascenders stay put; ascender overshoots (ß) untouched |
| **G2** proportions | width/x-height 0.951 → 0.902 | Falls out of G1; no horizontal condensing |
| **G3** spacing | Round side of `o c e d q b p a g` (+ `a.ss02`, `g.ss03`, accented forms) −12% (`ROUND_SB_TIGHTEN`) | Constant unit change sized at opsz 17 (≈6 units); outline, hmtx, mark offsets and anchors shift together; HVAR untouched |
| **G4** contrast | 0.84 → 0.88 | Falls out of G1 (horizontals stretch, stems don't) |
| **G5** apertures | `c e s` cut moves away from the counter | `open_terminal()`: outer corner still tucks in (`TERMINAL_TUCK=8`) so the end tapers soft; the cut lifts away from the counter (`APERTURE_LIFT=9`, `c` takes 40% per end since it opens at both) |
| **G7** italic | Same transforms | Explicit point indices for italic `c`/`e` (v1's adaptive rule also moved the `e` crossbar end) |

**Doing it right on a variable font.** The remap runs per master: each of the 12 masters (opsz 9/24/40 × wght 100/300/400/1000) is evaluated in absolute coordinates (IUP-expanded), remapped with *that master's own* x-height and ascender, and the deltas are re-solved with `VariationModel` and re-IUP-optimised (tolerance 0.5). This matters because DM Sans's x-height shrinks with optical size (526 → 496) and its ascender drops to 700 at opsz 40. A single default-master remap would lift opsz-40 ascenders.

- **Marks follow anchors.** Each GPOS mark-to-base anchor on a lowercase base moves by `remap(anchor) − anchor` per master, with new GDEF VarStore rows. Accents on x-height letters rise by exactly the x-height gain (the accent gap is unchanged); accents over ascenders stay. Composite mark offsets use the same anchor-derived shift, so precomposed `é` and `e + ◌́` agree everywhere on the grid (≤1.4 units).
- **ď ľ ť** apostrophe-caron follows its stem top (d, l stay; t's shorter stem rises a little).
- **Tittles** (i j ﬁ) move with the x-height like accents, keeping their gap; floating strokes in the ascender zone (đ ħ bars, ð) ride the compression.
- **Italic** is remapped shear-aware (de-slant → remap → re-slant), so stems don't kink at the overshoot band, and italic sidebearings are measured on the de-slanted outline.
- **Metrics:** `OS/2.sxHeight` and the `MVAR` `xhgt` deltas scale with the x-height. Vertical metrics, line gap and caps are untouched.

### Measured (wght 400, opsz 17)

| metric | v1 | **v2** | Google Sans Text | target |
|---|---|---|---|---|
| x-height / UPM | 0.501 | **0.525** | 0.526 | 0.522–0.528 |
| x-height / cap | 0.716 | **0.750** | 0.735 | 0.74–0.75 |
| avg advance / x-h | 0.951 | **0.902** | 0.884 | 0.89–0.91 |
| `n` sidebearing / x-h | 0.129 | **0.123** | 0.133 | ≥ 0.12 |
| `o` sidebearing / x-h | 0.097 | **0.081** | 0.078 | 0.079–0.085 |
| contrast | 0.84 | **0.88** | 0.92 | 0.87–0.90 |
| px to match GST@17px | 18.0 | **17.1** | 17.1 | |
| `c` aperture | 0.337 | **0.367** | 0.363 | ≥ 0.360 |
| `e` aperture | 0.149 | **0.179** | 0.188 | 0.172–0.188 |
| colour @ wght 400 | 0.362 | 0.363 | 0.375 | |
| colour @ wght 425 | | **0.375** | | 0.372–0.380 |

Colour is a setting, not an outline change: the variable font at **wght 425** matches Google Sans Text's paragraph density while semibold (0.472) and bold (0.513) stay clearly distinct. Italic apertures (de-slanted): `c` 0.322 → 0.349, `e` 0.163 → 0.179.

Verified across wght 100/400/700/1000 × opsz 9/14/17/24/40, upright and italic: x-height exactly ×1.048, overshoots of `n o e s` 12–13 units everywhere, ascenders/caps/descenders fixed (one sub-unit exception: the wght-100 `b` stem top, which sits 6 units under the ascender), no contour direction or count changes, OTS sanitizer passes on all 36 files.

---

## DM Sans Stylistic Sets

DM Sans includes several stylistic sets that remain available in R Sans (unfrozen):

| Tag | Description | Notes |
|-----|-------------|-------|
| `ss01` | Round quotes/commas | Warmer punctuation |
| `ss02` | Single-storey 'a' (+ accented forms) | Display-style 'a' |
| `ss03` | Alternate 'g' (+ accented forms) | Different loop style |
| `ss04` | Alternate 'u' (+ accented forms) | |
| `ss05` | Alternate 'y' (+ accented forms) | |
| `ss06` | Alternate 'Q' (different tail) | |
| `ss07` | Alternate digits (1, 3, 4, 6, 9) | |
| `ss08` | Alternate quotes/arrows | |

**No `zero` feature**: DM Sans does not include a slashed/dotted zero feature. Disambiguation is handled by our surgical dot addition on static instances.

---

## Build System

### Requirements
- Python 3.11+ (the build installs fonttools, brotli, numpy and opentype-feature-freezer in its own venv)
- `curl` (for downloading DM Sans from raw.githubusercontent.com)
- Internet access (downloads from Google Fonts GitHub)

### Quick Build
```bash
cd r-sans/
./build.sh
```

The script creates an isolated venv, downloads DM Sans, applies all transformations, and outputs to `fonts/` and `web-fonts/`. Build artifacts go to `/tmp` and are cleaned up automatically.

### Inspect Mode
```bash
./build.sh --inspect
```

Dumps glyph coordinates for all surgery target characters. Useful for verifying point indices before modifying surgery parameters.

### Build Pipeline

1. **Download** — DM Sans variable fonts from Google Fonts GitHub
2. **Rename** — All name table entries: `DM Sans` → `R Sans`
3. **Terminal softening** — 12 glyph coordinate adjustments on variable fonts (c/e/s open their apertures)
3b. **Proportion retune (v2)** — per-master lowercase x-height remap (outlines, gvar, composites, GPOS anchors, MVAR) and tighter round sidebearings
4. **Metrics** — Align hhea with usWin for cross-platform consistency
5. **Instance generation** — 8 weights × 2 styles = 16 static TTFs via `fontTools.varLib.instancer`
6. **Disambiguation** — Serifed I, tailed l, dotted zero on each static instance
7. **Metadata** — Fix name table, fsSelection, macStyle per instance
8. **WOFF2** — Convert all files (static + variable) to WOFF2

---

## Refinement Guide

### Adjusting Terminal Softening

Edit the surgery functions in `build.sh`. Each function documents:
- Which glyph points it modifies
- The expected coordinates at those points
- The displacement applied (dx, dy)

Example: to make the `c`/`e`/`s` terminals softer, or less open:
```python
# In build.sh: TERMINAL_TUCK=8 → 10 tapers the c/e/s ends more;
# APERTURE_LIFT=9 → 6 keeps the cuts closer to stock DM Sans
```

Use `./build.sh --inspect` to dump current coordinates before modifying.

### Changing Optical Size

Edit `OPSZ` at the top of `build.sh`:

| opsz | Optimized for | Character |
|------|--------------|-----------|
| 9 | DM Sans default — small text | Most open spacing |
| **14** | **R Sans default — body text** | **Balanced** |
| 20 | Subheadings | Tighter, more refined |
| 40 | Display text | Tightest spacing, highest contrast |

### Enabling Stylistic Sets

DM Sans's stylistic sets are available via CSS:
```css
.warm-quotes { font-feature-settings: 'ss01' 1; }
.single-storey-a { font-feature-settings: 'ss02' 1; }
.alt-digits { font-feature-settings: 'ss07' 1; }
```

### Generating Fewer Weights

Edit the `WEIGHTS` dict in the GENERATE section:
```python
weights = {'Regular': 400, 'Medium': 500, 'Bold': 700}
```

Or use the variable font directly — one file covers all weights.

---

## Web Deployment

### Variable Font (Recommended)

```css
@font-face {
  font-family: 'R Sans';
  src: url('/fonts/RSans-Variable.woff2') format('woff2');
  font-weight: 100 1000;
  font-display: swap;
}

@font-face {
  font-family: 'R Sans';
  src: url('/fonts/RSans-Italic-Variable.woff2') format('woff2');
  font-weight: 100 1000;
  font-style: italic;
  font-display: swap;
}

body {
  font-family: 'R Sans', system-ui, -apple-system, sans-serif;
  font-optical-sizing: auto;
  font-weight: 425;  /* v2: matches Google Sans Text's paragraph colour */
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
  src: url('/fonts/RSans-Bold.woff2') format('woff2');
  font-weight: 700;
  font-style: normal;
  font-display: swap;
}

/* Add more weights/styles as needed */
```

---

## Cross-Family Consistency with R Mono

R Sans and R Mono share a design philosophy:

| Decision | R Mono (code) | R Sans (prose) | Shared principle |
|----------|--------------|----------------|-----------------|
| Terminal treatment | Softened terminals | Terminal softening surgery | Warmth without whimsy |
| Disambiguation | Serifed `l`, dotted zero | Serifed `I`, tailed `l`, dotted zero | Instant character distinction |
| Geometry | Geometric overrides on Iosevka | DM Sans geometric base | Confident geometry |
| Line spacing | JB Mono width (600 units) | ~1.30x default line-height | "Room to breathe" |
| Design DNA | Iosevka + geometric | DM Sans + warmth | Precision + humanity |

**Pairing in CSS:**
```css
body      { font-family: 'R Sans', system-ui, sans-serif; }
code, pre { font-family: 'R Mono', 'JetBrains Mono', monospace; }
```

---

## Verification Checklist

After building or modifying R Sans:

- [ ] **Build**: `./build.sh` completes without errors
- [ ] **Font Book**: Install, all 8 weights show with correct names (Thin through ExtraBold) plus italic variants
- [ ] **Warmth test**: Compare R Sans vs stock DM Sans at 16px — terminals should be visibly softer/rounder
- [ ] **Reading test**: Set as system font, read 2,000+ word article at 16–18px — should feel warm and comfortable
- [ ] **Disambiguation**: Type `Il1| 0O` at 16px — all characters instantly distinct
- [ ] **Weight range**: All weights render correctly, no metadata confusion
- [ ] **Optical size**: Variable font respects opsz axis with `font-optical-sizing: auto`
- [ ] **Line spacing**: In apps that use default font metrics, text feels comfortably spaced

---

## Technical Specs

| Property | Value |
|----------|-------|
| Base font | DM Sans 4.x (variable, from Google Fonts GitHub) |
| UPM | 1000 |
| x-height | 551 at opsz 9, **525 at opsz 17** (body), 520 at opsz 24–40; `sxHeight` 551 (variable), 528 (statics, opsz 14) |
| Cap height | 700 (0.700 UPM) |
| Lowercase ascender | 720 (700 at opsz 40), unchanged by v2 |
| Typo ascender | 992 (0.992 UPM) |
| Descender | -310 (-0.310 UPM) |
| Line gap | 0 |
| Default line-height | ~1.30x |
| Variable axes | `wght` (100–1000), `opsz` (9–40) |
| Static instance opsz | 14 |
| Terminal softening | 12 glyphs (a, c, e, f, g, j, n, r, s, t, u, y) |
| v2 retune | x-height ×1.048, round sidebearings −12%, open c/e/s apertures |
| Recommended web weight | 425 for body text (matches Google Sans Text colour) |
| Disambiguation | Serifed I, tailed l, dotted zero (static only) |
| Glyph count | ~486 |
| Language support | Latin extended |
| Weights | Thin (100) through ExtraBold (800) |
| Styles | Upright + Italic for each weight |
| Static files | 16 TTF + 16 WOFF2 |
| Variable files | 2 TTF + 2 WOFF2 (upright + italic) |
| Build tool | fonttools (coordinate surgery + instancer + WOFF2) |
| License | SIL Open Font License 1.1 (inherited from DM Sans) |
