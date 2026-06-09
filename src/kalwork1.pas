{$mode tp}
unit kalwork1;
{
  Screen I/O, dialog boxes, and calendar work procedures.
  Replaces the original DOS kalwork1 unit.
  premwindsve (scroll) is replaced by a full-redraw flag since terminals
  cannot read back their own content; the main loop calls kalendar() instead.
}

interface

uses crt, nizz, kalsys1, kalmenu1, SysUtils;

var
  { Fasting-period boundary dates: postd[period][1/2][1/2]
    postd[p][1][1..2] = start day/month
    postd[p][2][1..2] = end   day/month                     }
  postd : array[1..8] of array[1..2] of array[1..2] of integer;

  { Set to true by premwindsve so the main loop redraws the calendar. }
  needRedraw : boolean;

procedure elwrite(x, y: integer; const s: string);
procedure elwritecol(x, y: integer; const s: string; col: byte);
procedure openwind(x1, y1, x2, y2: byte; col1, col2: byte;
                   const title: string; n: byte;
                   b1, b2, b3, b4: boolean;
                   wtype: byte; n1, n2: integer;
                   b5, b6: boolean; n3: integer);
procedure elbojwind(x1, y1, x2, y2: integer; col: byte);
procedure premwindsve(x1, y1, x2, y2, dir: integer);
function  scankey: char;

procedure about;
function  setdat(var m, g: integer): boolean;
procedure tabpost(g: integer);
procedure helppraz;
procedure tabindikt;

implementation

{ ── Color helper ────────────────────────────────────────────────── }

procedure setAttr(attr: byte);
begin
  TextColor(attr and $0F);
  TextBackground((attr shr 4) and $07);
end;

{ ── Basic positioned output ─────────────────────────────────────── }

procedure elwrite(x, y: integer; const s: string);
begin
  GotoXY(x, y);
  Write(s);
end;

procedure elwritecol(x, y: integer; const s: string; col: byte);
begin
  GotoXY(x, y);
  setAttr(col);
  Write(s);
  NormVideo;
end;

{ ── Window: draws a bordered box, clears interior ───────────────── }

procedure openwind(x1, y1, x2, y2: byte; col1, col2: byte;
                   const title: string; n: byte;
                   b1, b2, b3, b4: boolean;
                   wtype: byte; n1, n2: integer;
                   b5, b6: boolean; n3: integer);
var row, col, w, h: integer;
begin
  w := x2 - x1;   { interior width }
  h := y2 - y1;   { interior height }
  setAttr(col1);
  { top border }
  GotoXY(x1, y1);
  Write(BOX_ULC + niz(w - 1, BOX_H) + BOX_URC);
  { side borders + clear interior }
  for row := y1 + 1 to y2 - 1 do
  begin
    GotoXY(x1, row);
    setAttr(col1);
    Write(BOX_V);
    setAttr(col2);
    Write(niz(w - 1, ' '));
    setAttr(col1);
    Write(BOX_V);
  end;
  { bottom border }
  GotoXY(x1, y2);
  setAttr(col1);
  Write(BOX_LLC + niz(w - 1, BOX_H) + BOX_LRC);
  { optional title, centred on top border }
  if length(title) > 0 then
  begin
    col := x1 + (w - length(title)) div 2;
    GotoXY(col, y1);
    setAttr(col2);
    Write(title);
  end;
  NormVideo;
end;

{ ── Flood-colour a rectangular region ──────────────────────────── }

procedure elbojwind(x1, y1, x2, y2: integer; col: byte);
var row: integer;
begin
  setAttr(col);
  for row := y1 to y2 do
  begin
    GotoXY(x1, row);
    Write(niz(x2 - x1 + 1, ' '));
  end;
  NormVideo;
end;

{ ── Scroll substitute ───────────────────────────────────────────
  Terminals cannot read back their own content so a true pixel-level
  scroll is not possible with basic CRT.  Set a flag; the main loop
  will call kalendar() to repaint the affected area. }

procedure premwindsve(x1, y1, x2, y2, dir: integer);
begin
  needRedraw := true;
end;

{ ── Key reading ─────────────────────────────────────────────────── }

function scankey: char;
var c: char;
begin
  c := ReadKey;
  { #0 and #224 are both used as extended-key prefixes depending on
    the FPC CRT backend and platform. }
  if (c = #0) or (c = #224) then
    c := ReadKey;
  scankey := c;
end;

{ ── Wait for any key with a centered prompt ─────────────────────── }

procedure waitKey(msg: string);
var dummy: char;
begin
  GotoXY((80 - length(msg)) div 2 + 1, 24);
  setAttr(co[4]);
  Write(msg);
  NormVideo;
  dummy := ReadKey;
  if dummy = #0 then dummy := ReadKey;
end;

{ ── About dialog ────────────────────────────────────────────────── }

procedure about;
const
  X1 = 15; Y1 = 6; X2 = 65; Y2 = 18;
begin
  openwind(X1, Y1, X2, Y2, co[27], co[27],
           ' NEA BYZANTIA ', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  elwritecol(X1 + 2, Y1 + 2,  'Pravoslavni kalendar v6', co[15]);
  elwritecol(X1 + 2, Y1 + 4,  'Autori:', co[4]);
  elwritecol(X1 + 4, Y1 + 5,  'Nikola Reljin', co[17]);
  elwritecol(X1 + 4, Y1 + 6,  'Ivona Maric', co[17]);
  elwritecol(X1 + 4, Y1 + 7,  'Nikola Lecic', co[17]);
  elwritecol(X1 + 2, Y1 + 9,  'Originalni DOS program: Turbo Pascal 6/7', co[17]);
  elwritecol(X1 + 2, Y1 + 10, 'FPC port: Free Pascal (cross-platform)', co[17]);
  waitKey(' Pritisnite bilo koji taster... ');
end;

{ ── Set active month / year dialog ─────────────────────────────── }

function setdat(var m, g: integer): boolean;
const
  X1 = 20; Y1 = 8; X2 = 60; Y2 = 16;
var
  nm, ng : integer;
  buf    : string[6];
  ok     : boolean;
  k      : char;
begin
  setdat := false;
  openwind(X1, Y1, X2, Y2, co[27], co[27],
           ' Promena datuma ', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  nm := m;
  ng := g;
  ok := false;
  repeat
    elwritecol(X1 + 2, Y1 + 2, 'Mesec (1-12): ', co[4]);
    setAttr(co[15]);
    Str(nm, buf);
    Write(buf + '   ');
    elwritecol(X1 + 2, Y1 + 4, 'Godina:       ', co[4]);
    setAttr(co[15]);
    Str(ng, buf);
    Write(buf + '     ');
    NormVideo;
    elwritecol(X1 + 2, Y1 + 6, 'Enter=potvrdi  Esc=odustani', co[17]);
    elwritecol(X1 + 2, Y1 + 7, 'PgUp/PgDn mesec,  +/- godina', co[17]);
    k := ReadKey;
    if k = #0 then k := ReadKey;
    case k of
      pgupkey : if nm < 12 then inc(nm) else nm := 1;
      pgdnkey : if nm > 1  then dec(nm) else nm := 12;
      '+': inc(ng);
      '-': if ng > 1 then dec(ng);
      enterkey: ok := true;
      esckey:   begin setdat := false; exit; end;
    end;
  until ok;
  m := nm;
  g := ng;
  setdat := true;
end;

{ ── Helper: fasting-period name ─────────────────────────────────── }

function postName(idx: integer): string;
begin
  case idx of
    1: postName := 'Veliki post (pred Vasrks)';
    2: postName := 'Apostolski post';
    3: postName := 'Preobrazenjski post / Gospojinski post';
    4: postName := 'Bozicnji post (Filipovka)';
    5: postName := 'Sredom i petkom';
  else postName := 'Post';
  end;
end;

{ ── Fasting table ───────────────────────────────────────────────── }

procedure tabpost(g: integer);
const
  X1 = 5; Y1 = 4; X2 = 75; Y2 = 22;
var
  row, i : integer;
begin
  openwind(X1, Y1, X2, Y2, co[27], co[27],
           ' Postovi ' + strf(g), 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  row := Y1 + 2;
  elwritecol(X1 + 2, row, 'Visednevni postovi:', co[15]);
  inc(row, 2);
  for i := 1 to 4 do
  begin
    elwritecol(X1 + 2, row, postName(i), co[4]);
    elwritecol(X1 + 35, row,
      strf(postd[i][1][1]) + '.' + strf(postd[i][1][2]) + ' - ' +
      strf(postd[i][2][1]) + '.' + strf(postd[i][2][2]) + '.',
      co[17]);
    inc(row);
  end;
  inc(row);
  elwritecol(X1 + 2, row, 'Napomena: svi datumi su po starom (Julijanskom) kalendaru.', co[6]);
  waitKey(' Pritisnite bilo koji taster... ');
end;

{ ── Heortology (feast text viewer) ─────────────────────────────── }

procedure helppraz;
const
  X1 = 5; Y1 = 4; X2 = 75; Y2 = 22;
  KAL_NAMES : array[1..6] of string = (
    '_PRAZ1.KAL', '_PRAZ2.KAL', '_PRAZ3.KAL',
    '_PRAZ4.KAL', '_PRAZ5.KAL', '_PRAZ6.KAL');
var
  i, row : integer;
  f      : text;
  fname  : string;
  line   : string;
  k      : char;
begin
  openwind(X1, Y1, X2, Y2, co[27], co[27],
           ' Heortologija ', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  elwritecol(X1 + 2, Y1 + 2, 'Dostupni tekstovi:', co[15]);
  row := Y1 + 4;
  for i := 1 to 6 do
  begin
    fname := direct + KAL_NAMES[i];
    {$I-}
    Assign(f, fname);
    Reset(f);
    {$I+}
    if IOResult = 0 then
    begin
      ReadLn(f, line);  { first line = feast title }
      Close(f);
      elwritecol(X1 + 2, row, strf(i) + '. ' + Trim(line), co[17]);
      inc(row);
    end;
  end;
  waitKey(' Pritisnite bilo koji taster... ');
end;

{ ── Indiction table ─────────────────────────────────────────────── }

procedure tabindikt;
const
  X1 = 5; Y1 = 3; X2 = 75; Y2 = 23;
  COLS  = 4;
  ROWS  = 14;
  COLGAP= 17;
var
  ig, yr, d, m, row, col: integer;
  leap: string[1];
begin
  openwind(X1, Y1, X2, Y2, co[27], co[27],
           ' Veliki indiktion ', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  elwritecol(X1 + 2, Y1 + 1,
    '  God.  Datum Vaskrsa  Prst.', co[15]);
  elwritecol(X1 + 2 + COLGAP * 2, Y1 + 1,
    '  God.  Datum Vaskrsa  Prst.', co[15]);
  { Show next 56 years (4 columns of 14) }
  for ig := 1 to ROWS * COLS do
  begin
    { map to actual year relative to current }
    yr := ig;
    julianEaster(yr + 2024, d, m);
    if prestupna_jul(yr + 2024) then leap := '*' else leap := ' ';
    col := ((ig - 1) div ROWS);
    row := ((ig - 1) mod ROWS);
    elwritecol(X1 + 2 + col * COLGAP, Y1 + 2 + row,
      strf(yr + 2024) + '  ' +
      strf(d) + '.' + strf(m) + '.  ' + leap,
      co[17]);
  end;
  waitKey(' Pritisnite bilo koji taster... ');
end;

begin
  needRedraw := false;
end.
