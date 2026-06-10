# Architecture Notes

## Unit Dependency Graph

```
pravkal.pas (main program)
  ├── crt          (FPC standard — terminal I/O)
  ├── SysUtils     (FPC standard — date/path utilities)
  ├── nizz.pas     (string utils, shared types)
  ├── kalsys1.pas  (calendar engine)
  │     ├── nizz.pas
  │     └── SysUtils
  ├── kalmenu1.pas (menus)
  │     ├── crt
  │     ├── nizz.pas
  │     └── kalsys1.pas
  └── kalwork1.pas (dialogs, key handling)
        ├── crt
        ├── nizz.pas
        ├── kalsys1.pas
        └── kalmenu1.pas
```

## Key Data Structures

### `co[0..30]: array of byte` (kalsys1)
DOS-style colour attribute bytes (background×16 + foreground). All colours
use blue background (value $10). Important slots:
- `co[15]` — Sundays and major feasts (yellow on blue, $1E)
- `co[16]` — middle-rank feasts (ltcyan, $1B)
- `co[17]` — minor feasts (ltgray, $17)
- `co[19]` — fasting-day bullet `*` (ltred, $1C)
- `co[27]` — window borders (ltcyan, $1B)

### `datumi[1..532]: array of datarr` (kalsys1)
Precomputed Julian Easter dates for the 532-year Great Indiction cycle
starting at `__indiktg = 1941`. Populated at unit initialisation via
`julianEaster()`. Index `i` = cycle year `__indiktg + i - 1`.

### `praz[1..12][1..31]: array of prstr` (pravkal)
Fixed-feast name strings, one per Julian calendar day. Prefix character
encodes feast rank: `'c'` = major (red-letter), `'m'` = middle, `'o'` = minor.
Easter-movable feasts overlay `praz` via `pok_[1..11]` lookup at runtime.

### `_post[1..12][1..31]: array of boolean` (pravkal)
Fasting-day grid computed each year by `setpost`. Set to `true` for every
Julian calendar day that is a fasting day. Built from fixed fasts and the
Great Lent / Apostles' Fast windows derived from Easter.

### `tabs[1..63]: array of char` (pravkal)
63-character layout driver for the calendar grid. Period-10 repeating pattern:
```
a b c 0 1 2 3 4 5 6  (repeated 6×, plus abc)
│ │ │ └─────────────── Mon–Sat day rows (7 slots)
│ │ └──────────────── separator after Sunday label
│ └───────────────── Sunday label row (writenedelja)
└────────────────── separator before Sunday
```
`mt___` is the index into `tabs` for the start of the visible window.
`_topday` tracks the first calendar day number shown; `mt___` is derived
from it: `base_pos + ((_topday-1) div 7) * 10`.

## Screen Layout (80×25)

```
Row  1  │ Menu bar: Desk  Opcije  Traganje  Stampanje  Pomoc
Row  2  │ +────────────────────────────────────────────────────+ ┌──────────┐
Row  3  │ │ YYYY                  MMMMMM                NN dana│ │ NEA      │
Row  4  │ +───+────+──────+───────────────────────────────────+ │ BYZANTIA │
Row  5  │ │ D │  G │  J   │ Pravoslavni praznik               │ └──────────┘
Row  6  │ +───+────+──────+───────────────────────────────────+       │
Rows 7–23│ calendar day rows (17 rows, ~13 day entries + separators) ···cross···
Row 24  │ +───+────+──────+───────────────────────────────────+ ┌──────────┐
Row 25  │ F1 Pomoc  F3 Promena datuma  F5 Heort.  F7 Stamp. F10 Meni
```

The 17-row window (rows 7–23) shows roughly 13 calendar day entries plus
Sunday label rows and separators. Months with >13 visible days require
scrolling via ↑/↓ arrows.

## Julian Calendar Conversion

`setjulijan(d, m, y, jd, jm, jy, forward)` in `pravkal.pas` converts
between Gregorian and Julian dates using the per-century offset table:

| Century | Extra days |
|---------|-----------|
| 1700s | +11 |
| 1800s | +12 |
| 1900s / 2000s | +13 (current) |
| 2100s | +14 |

## Paschalion (Easter Computation)

Uses the **Meeus Julian Easter algorithm**:
```
a = year mod 4
b = year mod 7
c = year mod 19
d = (19c + 15) mod 30
e = (2a + 4b − d + 34) mod 7
month = (d + e + 114) div 31
day   = ((d + e + 114) mod 31) + 1
```

Result is a Julian calendar date. The 532-year cycle ensures Easter
repeats identically: 19 (Metonic) × 28 (solar) = 532.

## Movable Feast Offset Table (`pok_[1..11]`)

Built by `setuskrs` from the computed Julian Easter date:

| Index | Feast | Offset from Easter |
|-------|-------|--------------------|
| 1 | Great Lent start (Clean Monday) | −48 |
| 2 | Palm Sunday | −7 |
| 3 | Good Friday | −2 |
| 4 | Holy Saturday | −1 |
| 5 | Easter (Pascha) | 0 |
| 6 | Mid-Pentecost | +25 |
| 7 | Ascension | +39 |
| 8 | Pentecost Sunday | +49 |
| 9 | Holy Spirit Monday | +50 |
| 10 | All Saints Sunday | +56 |
| 11 | Apostles' Fast start | +57 |

## Adding a New Dialog

1. Write the dialog procedure in `kalwork1.pas` (use `openwind`, `elwritecol`,
   `waitKey` pattern — see `tabpost` or `tabindikt` for examples).
2. Add a `menuwork` case entry in `pravkal.pas`:
   ```pascal
   $XXYY: begin myDialog; drawfirstscreen; drawscreen; needRedraw := true; end;
   ```
3. Wire the key/menu item that invokes it.

The `drawfirstscreen; drawscreen; needRedraw := true` triple is required after
every dialog to erase the dialog box and trigger a full calendar redraw.

## Implementing Search (Traganje)

The menu slots are:
- `$0301` — Trazenje datuma (find by date)
- `$0302` — Trazenje praznika (find by feast name)
- `$0303` — Trazenje posta (find by fasting period)
- `$0304` — Trazenje nedelje (find by Sunday name)

Each needs a search dialog in `kalwork1.pas` that queries the `praz[m][d]`,
`_post[m][d]`, or `ned[i]` tables and presents results. Wire them in
`menuwork` following the pattern above.

## Porting to Lazarus GUI

The calendar engine (`kalsys1.pas`, `nizz.pas`) is pure logic with no screen
I/O — it can be used directly in a Lazarus LCL project. The recommended approach:

1. Create a new Lazarus project targeting LCL.
2. Add `kalsys1.pas` and `nizz.pas` to the project; compile with `{$mode tp}`.
3. Replace `kalmenu1.pas` and `kalwork1.pas` with LCL forms and components.
4. Replace `tabs`-based row rendering in `pravkal.pas` with a `TStringGrid`
   or custom `TCanvas`-painted component.
5. The `setpost`, `setuskrs`, `kalendar` logic can be adapted to populate
   the grid rows directly.
