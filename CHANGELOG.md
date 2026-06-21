# Changelog

All notable changes to this project are documented here.

## [1.0.0] — 2026-06-21

### Added
- Serbian Cyrillic across the entire UI — menus, dialogs, help, search, the
  feast database (372 entries), month/day names, and the TXT exports
- UTF-8-aware layout helpers: `dlen()` (visible-column width by counting
  codepoints, not bytes) and `nizs()` (repeat a multi-byte string)
- Cyrillic-aware `upcasestr()` so the month-title header renders all-caps
- UTF-8-safe raw screen layer (`scrGoto`/`scrPut`/`scrAttr`/`scrCls`) that
  writes ANSI directly, bypassing FPC `crt`'s byte-based cursor/wrap tracking

### Fixed
- Screen corruption with multi-byte glyphs: FPC `crt` counts bytes (not
  display columns) for line-wrapping, so Cyrillic/box-drawing rows wrapped
  mid-line and shifted the layout. All screen output now goes through the raw
  ANSI layer; `crt` is used only for keyboard input

### Changed
- TUI borders now use proper single-line box-drawing glyphs
  (`┌ ─ ┐ │ └ ┘ ├ ┤ ┬ ┴ ┼`) instead of ASCII `+ - |`, matching the original
  DOS application; calendar grid uses correct tee/cross junctions
- Heortologija prose data files (`data/_PRAZ1..6.KAL`, `_GRESKE.MOL`)
  translated to Cyrillic
- String-type capacities widened (`prstr`, `tbstr`, menu/day arrays) to hold
  the 2-bytes-per-letter UTF-8 Cyrillic without overflow

### Notes
- Requires a UTF-8 terminal (standard on modern Linux/macOS)

## [0.2.1] — 2026-06-12

### Fixed
- CI: release workflow now resolves correctly against the `production` ref

## [0.2.0] — 2026-06-10

### Added
- F7 exports current month to `mesec_YYYY_MM.txt` (plain-text layout)
- F8 exports the annual fasting schedule to `postovi_YYYY.txt`
- `-h` / `--help` CLI flag prints usage and exits
- `-v` / `--version` CLI flag prints version and exits
- Help (Pomoc) and Configuration (Konfiguracija) stub menu items under Pomoc menu
- Bilingual About dialog (Serbian + English)
- Original authorship year 1993 shown in About dialog

### Fixed
- Correct column alignment in TXT month export (off-by-one spacing)
- Calendar screen fully restored after closing any menu (no ghost content)

### Changed
- Project renamed from KalendarFPC to **PravKal**
- Binary renamed to `pravkal`

### Known limitations (carry-forward)
- Search (Traganje) menu items: wired but no implementation
- Print to actual printer/file: stdout only
- Configuration dialogs: not implemented
- Help system: not implemented

## [0.1.0] — 2026-06-09

### Added
- Initial FPC port of the original DOS Turbo Pascal 6/7 program
- Reconstructed four missing units from API usage patterns and binary extraction:
  - `nizz.pas` — string utilities, shared types, ASCII box-drawing constants
  - `kalsys1.pas` — calendar engine, Paschalion, leap-year predicates, colour table
  - `kalmenu1.pas` — menu bar, drop-down navigation, function-key strip
  - `kalwork1.pas` — screen I/O, dialog boxes, key handling
- `{$mode tp}` + `{$H-}` compatibility mode for Turbo Pascal semantics
- Runtime 532-year Alexandrian Paschalion via Meeus Julian Easter algorithm
  (no hard-coded table; works for any year in range 0 AD – 4000 AD)
- Parallel Gregorian / Julian date columns with correct 13-day offset
- Fasting-day markers (`*`) computed from Julian Easter and fixed periods
- Movable feast names for the entire liturgical year
- Month/week scroll navigation via ↑/↓ arrow keys (`_topday` window tracking)
- F3 date-change dialog (month/year selection)
- F5 heortology viewer (reads `.KAL` files from program directory)
- F7 print current month to stdout
- F10 drop-down menu (Desk, Opcije, Traganje, Stampanje, Pomoc)
- About dialog showing original authors
- Fasting-period table dialog
- Indiction table dialog (56-year lookahead)
- Cross-platform program directory detection (`ExtractFilePath(ParamStr(0))`)
- `build.sh` compile + data-copy script

### Ported / Fixed from original DOS source
- Removed all DOS-specific code: `intr($10,reg)` BIOS calls, direct video
  buffer access (`ptr($B800,0)`), `GetDate`/`DosVersion` DOS unit,
  `lst` printer unit, `fsplit`, `lastmode`/`mono` globals
- Replaced `ptr(seg,ofs)` `FillChar` trick with `FillChar(_post, SizeOf, 0)`
- Fixed `else else` syntax in `setjulijan` and `go` (Turbo Pascal parser quirk)
- Fixed F7 key not wired in `mainwork` case statement
- Fixed `drawfirstscreen` draw order (`elbojwind` flood-fill now runs before
  border/header writes, not after)
- Fixed 80-char row-25 write causing terminal scroll (changed to 79 chars in
  `showmainmenu` and `showkeyfunc` to avoid wrap+scroll on last terminal row)
- Fixed scroll navigation: `mt___` advances by 10 per week (period of the
  `tabs` layout string), not by 1; added `_topday` day-offset tracking
- Fixed dialog dismissal leaving ghost content: `drawfirstscreen` + `drawscreen`
  called after each dialog closes via `menuwork`

### Known limitations (carry-forward)
- `premwindsve` (DOS video scroll) is a no-op stub; full redraw used instead
- Search (Traganje) menu items: wired but no implementation
- Print to actual printer/file: stdout only
- Configuration dialogs: not implemented
- Help system: not implemented
- Box-drawing uses ASCII art (`+`, `-`, `|`); Unicode upgrade deferred to GUI port
