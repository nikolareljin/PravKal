{$mode tp}
unit kalwork1;
{
  Screen I/O, dialog boxes, and calendar work procedures.
  Replaces the original DOS kalwork1 unit.
  premwindsve (scroll) is replaced by a full-redraw flag since terminals
  cannot read back their own content; the main loop calls kalendar() instead.
}

interface

uses crt, nizz, kalsys1, kalmenu1, SysUtils, kaltxt;

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

procedure waitKey(msg: string);
procedure about;
function  setdat(var m, g: integer): boolean;
procedure tabpost(g: integer);
procedure helppraz;
procedure tabindikt;
procedure stampajPost(g: integer);
procedure pomoc;
procedure sadrzaj;
procedure konfig;
procedure snimKonfig;
procedure ucitajKonfig;

implementation

{ ── Color helper ────────────────────────────────────────────────── }

procedure setAttr(attr: byte);
begin
  scrAttr(attr);
end;

{ ── Basic positioned output ─────────────────────────────────────── }

procedure elwrite(x, y: integer; const s: string);
begin
  scrGoto(x, y);
  scrPut(s);
end;

procedure elwritecol(x, y: integer; const s: string; col: byte);
begin
  scrGoto(x, y);
  setAttr(col);
  scrPut(s);
  scrNorm;
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
  scrGoto(x1, y1);
  scrPut(BOX_ULC + nizs(w - 1, BOX_H) + BOX_URC);
  { side borders + clear interior }
  for row := y1 + 1 to y2 - 1 do
  begin
    scrGoto(x1, row);
    setAttr(col1);
    scrPut(BOX_V);
    setAttr(col2);
    scrPut(niz(w - 1, ' '));
    setAttr(col1);
    scrPut(BOX_V);
  end;
  { bottom border }
  scrGoto(x1, y2);
  setAttr(col1);
  scrPut(BOX_LLC + nizs(w - 1, BOX_H) + BOX_LRC);
  { optional title, centred on top border }
  if length(title) > 0 then
  begin
    col := x1 + (w - dlen(title)) div 2;
    scrGoto(col, y1);
    setAttr(col2);
    scrPut(title);
  end;
  scrNorm;
end;

{ ── Flood-colour a rectangular region ──────────────────────────── }

procedure elbojwind(x1, y1, x2, y2: integer; col: byte);
var row: integer;
begin
  setAttr(col);
  for row := y1 to y2 do
  begin
    scrGoto(x1, row);
    scrPut(niz(x2 - x1 + 1, ' '));
  end;
  scrNorm;
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
  scrGoto((80 - dlen(msg)) div 2 + 1, 24);
  setAttr(co[4]);
  scrPut(msg);
  scrNorm;
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
  elwritecol(X1 + 2, Y1 + 2,  'Православни календар', co[15]);
  elwritecol(X1 + 2, Y1 + 4,  'Аутори:', co[4]);
  elwritecol(X1 + 4, Y1 + 5,  'Никола Рељин', co[17]);
  elwritecol(X1 + 4, Y1 + 6,  'Ивона Марић', co[17]);
  elwritecol(X1 + 4, Y1 + 7,  'Никола Лечић', co[17]);
  elwritecol(X1 + 2, Y1 + 9,  'Оригинални DOS програм: Turbo Pascal 6/7', co[17]);
  elwritecol(X1 + 2, Y1 + 10, 'FPC порт: Free Pascal (вишеплатформски)', co[17]);
  waitKey(' Притисните било који тастер...');
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
           ' Промена датума ', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  nm := m;
  ng := g;
  ok := false;
  repeat
    elwritecol(X1 + 2, Y1 + 2, 'Месец (1-12): ', co[4]);
    Str(nm, buf);
    { keep all output on the UTF-8-safe scr* layer; mixing crt Write here
      desyncs the cursor and corrupts the Cyrillic/box-glyph layout }
    elwritecol(X1 + 16, Y1 + 2, buf + '   ', co[15]);
    elwritecol(X1 + 2, Y1 + 4, 'Година:       ', co[4]);
    Str(ng, buf);
    elwritecol(X1 + 16, Y1 + 4, buf + '     ', co[15]);
    elwritecol(X1 + 2, Y1 + 6, 'Enter=потврди  Esc=одустани', co[17]);
    elwritecol(X1 + 2, Y1 + 7, 'PgUp/PgDn месец,  +/- година', co[17]);
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
    1: postName := 'Велики пост (пред Васкрс)';
    2: postName := 'Апостолски пост';
    3: postName := 'Преображењски пост / Госпојински пост';
    4: postName := 'Божићни пост (Филиповка)';
    5: postName := 'Средом и петком';
  else postName := 'Пост';
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
           ' Постови ' + strf(g), 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  row := Y1 + 2;
  elwritecol(X1 + 2, row, 'Вишедневни постови:', co[15]);
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
  elwritecol(X1 + 2, row, 'Напомена: сви датуми су по старом (Јулијанском) календару.', co[6]);
  waitKey(' Притисните било који тастер...');
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
           ' Хеортологија ', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  elwritecol(X1 + 2, Y1 + 2, 'Доступни текстови:', co[15]);
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
  waitKey(' Притисните било који тастер...');
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
           ' Велики индиктион ', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  elwritecol(X1 + 2, Y1 + 1,
    '  Год.  Датум Васкрса  Прст.', co[15]);
  elwritecol(X1 + 2 + COLGAP * 2, Y1 + 1,
    '  Год.  Датум Васкрса  Прст.', co[15]);
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
  waitKey(' Притисните било који тастер...');
end;

{ ── Export fasting schedule to plain-text file (F8) ─────────────── }

procedure stampajPost(g: integer);
const W = 60;
var lines : TKTXTLines;
    nl    : integer;
    fname : string;
    pn, ds, hdr : string;
    i : integer;

  procedure addLine(const s: string);
  begin
    if nl < KTXT_MAXLINES then begin lines[nl] := s; inc(nl); end;
  end;

  procedure wline(const s: string);
  begin
    addLine(BOX_V + '  ' + s + niz(W - 2 - dlen(s), ' ') + BOX_V);
  end;

  { Left-label row, padded by visible width. }
  procedure lline(const s: string);
  begin
    addLine(BOX_V + ' ' + s + niz(W - 1 - dlen(s), ' ') + BOX_V);
  end;

  { Blank interior row. }
  procedure bline;
  begin
    addLine(BOX_V + niz(W, ' ') + BOX_V);
  end;

begin
  nl    := 0;
  fname := direct + 'postovi_' + strf(g) + '.txt';

  for i := 1 to 6 do addLine(krst1[i]);
  addLine('');
  hdr := 'ПОСТОВИ ' + strf(g);
  addLine(BOX_ULC + nizs(W, BOX_H) + BOX_URC);
  addLine(BOX_V + niz((W - dlen(hdr)) div 2, ' ') + hdr +
          niz(W - dlen(hdr) - (W - dlen(hdr)) div 2, ' ') + BOX_V);
  addLine(BOX_LTEE + nizs(W, BOX_H) + BOX_RTEE);
  bline;
  lline('Вишедневни постови:');
  bline;
  for i := 1 to 2 do
  begin
    if i = 1 then pn := 'Велики пост (Часни пост)'
             else pn := 'Апостолски пост (Петровка)';
    ds := strf(postd[i][1][1]) + '.' + strf(postd[i][1][2]) + '. - ' +
          strf(postd[i][2][1]) + '.' + strf(postd[i][2][2]) + '.';
    addLine(BOX_V + '  ' + pn + niz(W - 2 - dlen(pn) - dlen(ds), ' ') + ds + BOX_V);
  end;
  { Fixed fasts }
  pn := 'Госпојински пост';          ds := '1.8. - 14.8.';
  addLine(BOX_V + '  ' + pn + niz(W - 2 - dlen(pn) - dlen(ds), ' ') + ds + BOX_V);
  pn := 'Божићни пост (Филиповка)'; ds := '14.11. - 24.12.';
  addLine(BOX_V + '  ' + pn + niz(W - 2 - dlen(pn) - dlen(ds), ' ') + ds + BOX_V);
  bline;
  lline('Једнодневни постови:');
  bline;
  wline('Среда и петак (целогодишње)');
  wline('Богојављењски сочељник - 5. јануар');
  wline('Крстовдан (Воздвижење) - 14. септембар');
  wline('Усековање главе св. Јована - 29. август');
  bline;
  lline('Напомена: датуми су по Јулијанском календару.');
  addLine(BOX_LLC + nizs(W, BOX_H) + BOX_LRC);

  if writeTXTLines(fname, nl, lines) then
  begin
    openwind(8, 10, 71, 15, co[27], co[27], ' Извоз у TXT ', 0,
             false, false, false, false, wsingle, 0, 0, true, false, 0);
    elwritecol(10, 11, 'TXT снимљен:', co[4]);
    elwritecol(10, 12, fname, co[15]);
    waitKey('');
  end
  else
  begin
    openwind(8, 10, 71, 15, co[27], co[27], ' Грешка ', 0,
             false, false, false, false, wsingle, 0, 0, true, false, 0);
    elwritecol(10, 11, 'Грешка при снимању TXT фајла!', co[6]);
    elwritecol(10, 12, fname, co[17]);
    waitKey('');
  end;
end;

{ ── Help: keyboard shortcuts (F1) ──────────────────────────────────── }

procedure pomoc;
const X1 = 5; Y1 = 3; X2 = 74; Y2 = 22;
begin
  openwind(X1, Y1, X2, Y2, co[27], co[27],
           ' Помоћ — Тастатура ', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  elwritecol(X1+2, Y1+2,  'Тастатура:', co[4]);
  elwritecol(X1+4, Y1+3,  'F1          Помоћ (ова порука)', co[17]);
  elwritecol(X1+4, Y1+4,  'F3          Промена активног датума', co[17]);
  elwritecol(X1+4, Y1+5,  'F5          Хеортологија (текстови празника)', co[17]);
  elwritecol(X1+4, Y1+6,  'F7          Извоз месеца у TXT фајл', co[17]);
  elwritecol(X1+4, Y1+7,  'F8          Извоз постова у TXT фајл', co[17]);
  elwritecol(X1+4, Y1+8,  'F10         Активирање менија', co[17]);
  elwritecol(X1+4, Y1+9,  'Ctrl-P      Табела постова за годину', co[17]);
  elwritecol(X1+4, Y1+10, 'Ctrl-C      Излазак из програма', co[17]);
  elwritecol(X1+4, Y1+11, 'PgUp/PgDn   Померање приказа горе/доле', co[17]);
  elwritecol(X1+2, Y1+13, 'Боје празника у календару:', co[4]);
  elwritecol(X1+4, Y1+14, 'Жуто  = Недељни дан / Велики празник', co[15]);
  elwritecol(X1+4, Y1+15, 'Плаво = Средњи празник', co[16]);
  elwritecol(X1+4, Y1+16, 'Сиво  = Мањи празник', co[17]);
  elwritecol(X1+4, Y1+17, '*     = Посни дан', co[19]);
  waitKey(' Притисните било који тастер...');
end;

{ ── Help: table of contents (Sadrzaj) ───────────────────────────────── }

procedure sadrzaj;
const X1 = 5; Y1 = 3; X2 = 74; Y2 = 22;
begin
  openwind(X1, Y1, X2, Y2, co[27], co[27],
           ' Садржај — Упутство ', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  elwritecol(X1+2, Y1+2,  'Православни календар — преглед функција:', co[15]);
  elwritecol(X1+2, Y1+4,  '1. КАЛЕНДАР (главна страна)', co[4]);
  elwritecol(X1+4, Y1+5,  'Месечни приказ православних празника.', co[17]);
  elwritecol(X1+4, Y1+6,  'G = Грегориј. дан, J = Јулиј. дан; боја = ранг празника.', co[17]);
  elwritecol(X1+2, Y1+8,  '2. ОПЦИЈЕ (мени, F3/F5/Ctrl-P)', co[4]);
  elwritecol(X1+4, Y1+9,  'Промена датума, табела постова, хеортологија, индиктион.', co[17]);
  elwritecol(X1+2, Y1+11, '3. ТРАГАЊЕ (мени)', co[4]);
  elwritecol(X1+4, Y1+12, 'Претрага по датуму, празнику, посту или литургијској недељи.', co[17]);
  elwritecol(X1+2, Y1+14, '4. ИЗВОЗ (F7 / F8)', co[4]);
  elwritecol(X1+4, Y1+15, 'Извоз месечног календара или табеле постова у TXT.', co[17]);
  elwritecol(X1+2, Y1+17, 'Напомена: датуми су по јулијанском (старом) календару.', co[6]);
  waitKey(' Притисните било који тастер...');
end;

{ ── Configuration dialog ────────────────────────────────────────────── }

procedure konfig;
const
  X1 = 18; Y1 = 7; X2 = 61; Y2 = 18;
  NTHEMES = 3;
  TNAMES  : array[1..NTHEMES] of string[44] = (
    'Плава (подразумевана)', 'Зелена', 'Црно-бела');
var
  sel, orig, i : integer;
  k            : char;
begin
  orig := colorTheme;
  sel  := colorTheme + 1;
  repeat
    applyTheme(sel - 1);
    openwind(X1, Y1, X2, Y2, co[27], co[27],
             ' Конфигурација ', 0,
             false, false, false, false, wsingle, 0, 0, true, false, 0);
    elwritecol(X1+2, Y1+2, 'Тема екрана:', co[4]);
    for i := 1 to NTHEMES do
      if i = sel then
        elwritecol(X1+4, Y1+3+i, '> ' + TNAMES[i], co[15])
      else
        elwritecol(X1+4, Y1+3+i, '  ' + TNAMES[i], co[17]);
    elwritecol(X1+2, Y1+8, 'Стрелице = избор,  Enter = примени', co[17]);
    elwritecol(X1+2, Y1+9, 'Esc = одустани (враћа претходну тему)', co[17]);
    k := scankey;
    case k of
      upkey:   if sel > 1 then dec(sel) else sel := NTHEMES;
      downkey: if sel < NTHEMES then inc(sel) else sel := 1;
      enterkey: exit;
      esckey:
        begin
          applyTheme(orig);
          exit;
        end;
    end;
  until false;
end;

{ ── Save configuration to KALENDAR.CFG ──────────────────────────────── }

procedure snimKonfig;
var f     : text;
    fname : string;
begin
  fname := direct + 'KALENDAR.CFG';
  {$I-}
  Assign(f, fname);
  Rewrite(f);
  {$I+}
  if IOResult <> 0 then
  begin
    openwind(15, 11, 65, 14, co[27], co[27], ' Грешка ', 0,
             false, false, false, false, wsingle, 0, 0, true, false, 0);
    elwritecol(17, 12, 'Не могу снимити: ' + fname, co[6]);
    waitKey(' Тастер за наставак...');
    exit;
  end;
  {$I-}
  WriteLn(f, 'theme=' + strf(colorTheme));
  {$I+}
  if IOResult <> 0 then
  begin
    {$I-} Close(f); {$I+}  { best-effort close }
    openwind(15, 11, 65, 14, co[27], co[27], ' Грешка ', 0,
             false, false, false, false, wsingle, 0, 0, true, false, 0);
    elwritecol(17, 12, 'Грешка при писању: ' + fname, co[6]);
    waitKey(' Тастер за наставак...');
    exit;
  end;
  {$I-}
  Close(f);
  {$I+}
  if IOResult <> 0 then
  begin
    openwind(15, 11, 65, 14, co[27], co[27], ' Грешка ', 0,
             false, false, false, false, wsingle, 0, 0, true, false, 0);
    elwritecol(17, 12, 'Грешка при писању: ' + fname, co[6]);
    waitKey(' Тастер за наставак...');
    exit;
  end;
  openwind(15, 11, 65, 14, co[27], co[27], ' Конфигурација снимљена ', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  elwritecol(17, 12, 'Снимљено: ' + fname, co[4]);
  waitKey(' Тастер за наставак...');
end;

{ ── Load configuration from KALENDAR.CFG ────────────────────────────── }

procedure ucitajKonfig;
var f     : text;
    fname : string;
    line  : string;
    p, t  : integer;
    code  : integer;
begin
  fname := direct + 'KALENDAR.CFG';
  {$I-}
  Assign(f, fname);
  Reset(f);
  {$I+}
  if IOResult <> 0 then exit;
  {$I-}
  while not EOF(f) do
  begin
    ReadLn(f, line);
    p := Pos('=', line);
    if p > 0 then
    begin
      if Copy(line, 1, p-1) = 'theme' then
      begin
        Val(Copy(line, p+1, Length(line)), t, code);
        if code = 0 then applyTheme(t);
      end;
    end;
  end;
  Close(f);
  {$I+}
end;

begin
  needRedraw := false;
end.
