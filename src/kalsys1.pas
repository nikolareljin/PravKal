{$mode tp}
unit kalsys1;
{
  Calendar system constants, types, and core functions.
  Contains:
    - Color table (co[])
    - Month names (imm[])
    - Julian / Gregorian leap-year predicates
    - 532-year Alexandrian Paschalion (datumi[]) computed at init
    - 15-year liturgical Indiction function
    - Cross art for printing (krst1[])
    - Path / screen globals (seg_scr stub for FPC)
}

interface

uses nizz, SysUtils;

const
  wsingle = 0;   { window border style selector }

  { Julian-to-Gregorian day offset anchored at __indiktg.
    Name derives from original: razlika 20. veka = 20th-century difference. }
  _r20_    = 13;
  __indiktg = 1941;   { first year of current 532-year Paschalion cycle }

type
  datarr = array[1..2] of byte;   { [1]=day [2]=month }

var
  co  : array[0..30] of byte;      { DOS-style color attribute bytes }
  imm : array[1..12] of string;    { Serbian month names }
  datumi : array[1..532] of datarr;{ Julian Easter dates for each cycle year }
  krst1  : array[1..6] of string;  { printing cross (6 lines) }

  { DOS remnants — kept for declaration compatibility; not used for video. }
  seg_scr : word;
  scr     : pointer;
  direct  : pathstr;               { program directory, path-separator correct }

  colorTheme : integer;            { 0=Plava 1=Zelena 2=CrnoBela }

function prestupna_greg(g: integer): boolean;
function prestupna_jul(g: integer): boolean;
function indiktiong(g: integer): integer;
procedure setconstcol;
procedure applyTheme(t: integer);
procedure julianEaster(year: integer; var d, m: integer);

implementation

{ ── Leap year predicates ───────────────────────────────────────────────── }

function prestupna_greg(g: integer): boolean;
begin
  prestupna_greg := ((g mod 4 = 0) and (g mod 100 <> 0))
                 or  (g mod 400 = 0);
end;

function prestupna_jul(g: integer): boolean;
begin
  prestupna_jul := (g mod 4 = 0);
end;

{ ── 15-year liturgical Indiction ─────────────────────────────────────── }

function indiktiong(g: integer): integer;
begin
  indiktiong := ((g + 2) mod 15) + 1;
end;

{ ── Julian Easter (Alexandrian/Meeus algorithm) ─────────────────────── }

procedure julianEaster(year: integer; var d, m: integer);
var a, b, c, dd, e: integer;
begin
  a  := year mod 4;
  b  := year mod 7;
  c  := year mod 19;
  dd := (19 * c + 15) mod 30;
  e  := (2 * a + 4 * b - dd + 34) mod 7;
  m  := (dd + e + 114) div 31;
  d  := ((dd + e + 114) mod 31) + 1;
end;

{ ── Color table ─────────────────────────────────────────────────────── }
{
  DOS text attribute byte: bits 6-4 = background (0-7), bits 3-0 = foreground (0-15).
  Color indices:
    0=black  1=blue  2=green  3=cyan  4=red  5=magenta  6=brown  7=ltgray
    8=dkgray 9=ltblue 10=ltgreen 11=ltcyan 12=ltred 13=ltmagenta 14=yellow 15=white
  All on blue background (bg=1 → high nibble = $10).
}
procedure setconstcol;
begin
  co[0]  := $17;  { ltgray on blue  — default fill }
  co[1]  := $17;  { ltgray on blue  — screen background }
  co[2]  := $17;  { ltgray on blue  — box borders }
  co[3]  := $1F;  { white on blue   }
  co[4]  := $1B;  { ltcyan on blue  }
  co[5]  := $1E;  { yellow on blue  — decorative cross }
  co[6]  := $1C;  { ltred on blue   }
  co[7]  := $19;  { ltblue on blue  }
  co[8]  := $1A;  { ltgreen on blue }
  co[9]  := $1B;  { ltcyan on blue  }
  co[10] := $1F;  { white on blue   }
  co[11] := $1E;  { yellow on blue  }
  co[12] := $1C;  { ltred on blue   }
  co[13] := $1B;  { ltcyan on blue  }
  co[14] := $17;  { ltgray on blue  }
  co[15] := $1E;  { yellow on blue  — Sundays and major ('c') feasts }
  co[16] := $1B;  { ltcyan on blue  — middle ('m') feasts }
  co[17] := $17;  { ltgray on blue  — minor ('o') feasts }
  co[18] := $1A;  { ltgreen on blue }
  co[19] := $1C;  { ltred on blue   — fasting-day bullet }
  co[20] := $17;
  co[21] := $1F;
  co[22] := $1E;
  co[23] := $1B;
  co[24] := $1C;
  co[25] := $17;
  co[26] := $1F;
  co[27] := $1B;  { ltcyan on blue  — window borders (passed directly) }
  co[28] := $1E;
  co[29] := $1F;
  co[30] := $17;
end;

{ ── Color theme switcher ────────────────────────────────────────────── }
{ Apply a color theme.
  t=0 (Plava):    full restore via setconstcol — resets both fg and bg.
  t=1 (Zelena):   replaces background nibble of every co[] entry with $20.
  t=2 (CrnoBela): replaces background nibble with $00, high-contrast.
  Out-of-range values are silently treated as t=0. }
procedure applyTheme(t: integer);
var bg: byte;
    i : integer;
begin
  if (t < 0) or (t > 2) then t := 0;
  colorTheme := t;
  case t of
    1: bg := $20;   { green background }
    2: bg := $00;   { black background }
  else bg := $10;   { blue background (default) }
  end;
  if t = 0 then
  begin
    setconstcol;
    exit;
  end;
  for i := 0 to 30 do
    co[i] := bg or (co[i] and $0F);
end;

{ ── Month names (Serbian Latin) ────────────────────────────────────── }

procedure initMonthNames;
begin
  imm[1]  := 'Januar';
  imm[2]  := 'Februar';
  imm[3]  := 'Mart';
  imm[4]  := 'April';
  imm[5]  := 'Maj';
  imm[6]  := 'Jun';
  imm[7]  := 'Jul';
  imm[8]  := 'Avgust';
  imm[9]  := 'Septembar';
  imm[10] := 'Oktobar';
  imm[11] := 'Novembar';
  imm[12] := 'Decembar';
end;

{ ── Printing cross (6 lines, used in stampaj) ────────────────────── }

procedure initKrst1;
begin
  krst1[1] := '          |          ';
  krst1[2] := '     -----+-----     ';
  krst1[3] := '          |          ';
  krst1[4] := '          |          ';
  krst1[5] := '          |          ';
  krst1[6] := '          |          ';
end;

{ ── Program directory (platform-aware) ─────────────────────────────── }

procedure initDirect;
var sep: char;
begin
  {$IFDEF UNIX}
  sep := '/';
  {$ELSE}
  sep := '\';
  {$ENDIF}
  direct := ExtractFilePath(ParamStr(0));
  if (direct <> '') and (direct[Length(direct)] <> sep) then
    direct := direct + sep;
  if direct = '' then
    direct := '.' + sep;
end;

{ ── Build 532-year Paschalion table at startup ──────────────────────
  Anchor: year __indiktg = cycle position 1.
  datumi[i][1] = Julian Easter day, datumi[i][2] = month for cycle year i. }

procedure initPaschalion;
var i, d, m: integer;
begin
  for i := 1 to 532 do
  begin
    julianEaster(__indiktg + i - 1, d, m);
    datumi[i][1] := d;
    datumi[i][2] := m;
  end;
end;

{ ── Unit initialisation ─────────────────────────────────────────── }

begin
  seg_scr    := $B800;   { stub; not used for actual video access }
  scr        := nil;
  colorTheme := 0;
  setconstcol;
  initMonthNames;
  initKrst1;
  initDirect;
  initPaschalion;
end.
