{$mode tp}
unit nizz;
{
  String utilities and shared type definitions.
  Replaces the original DOS-era nizz unit.
}

interface

uses SysUtils;   { FileWrite for raw stdout }

type
  { Capacities sized in BYTES. Cyrillic text is UTF-8 (2 bytes/letter),
    so string types that hold displayed Serbian text are widened to fit
    the same number of visible columns after the Latin->Cyrillic switch. }
  pathstr = string[255];
  namestr = string[9];
  extstr  = string[5];
  kstr    = string[15];
  prstr   = string[160];   { feast lines: up to ~70 visible cols -> <=140 bytes }
  tbstr   = string[220];   { table separators: ~62 box glyphs * 3 bytes = ~186 }
  spec    = array[1..2] of integer;
  mssm    = array[1..2] of byte;

{ Box-drawing: UTF-8 single-line glyphs (restored from the original DOS
  CP437 box characters). Each glyph is a multi-byte string, so use nizs()
  (not niz()) to repeat them and dlen() (not length()) to measure columns. }
const
  BOX_V    = #$E2#$94#$82;   { │  U+2502  was #179 }
  BOX_H    = #$E2#$94#$80;   { ─  U+2500  was #196 }
  BOX_ULC  = #$E2#$94#$8C;   { ┌  U+250C  was #218 }
  BOX_URC  = #$E2#$94#$90;   { ┐  U+2510  was #191 }
  BOX_LLC  = #$E2#$94#$94;   { └  U+2514  was #192 }
  BOX_LRC  = #$E2#$94#$98;   { ┘  U+2518  was #217 }
  BOX_LTEE = #$E2#$94#$9C;   { ├  U+251C  was #195 }
  BOX_RTEE = #$E2#$94#$A4;   { ┤  U+2524  was #180 }
  BOX_BTEE = #$E2#$94#$B4;   { ┴  U+2534  was #193 }
  BOX_TTEE = #$E2#$94#$AC;   { ┬  U+252C  was #194 }
  BOX_CROSS= #$E2#$94#$BC;   { ┼  U+253C  was #197 }
  BOX_BULL = #$E2#$96#$A0;   { ■  U+25A0  was #254 }

function niz(n: integer; c: char): string;
{ Repeat a (possibly multi-byte) string n times — use for box glyphs. }
function nizs(n: integer; const s: string): string;
{ Visible-column width of a UTF-8 string (counts codepoints, not bytes). }
function dlen(const s: string): integer;

{ ── Raw screen output (UTF-8 safe) ──────────────────────────────────
  FPC's crt unit counts bytes (not glyphs) for cursor/wrap tracking, so
  multi-byte UTF-8 (Cyrillic, box-drawing) makes it wrap mid-line and
  shred the layout. These write ANSI directly to stdout, bypassing crt's
  byte counter. crt is still used for keyboard input (ReadKey). }
procedure scrGoto(x, y: integer);         { position cursor (1-based) }
procedure scrPut(const s: string);        { emit text verbatim         }
procedure scrAttr(attr: byte);            { DOS attr byte: fg|bg<<4     }
procedure scrAttrFB(fg, bg: integer);     { explicit fg/bg DOS colors   }
procedure scrNorm;                        { reset attributes            }
procedure scrCls;                         { clear screen + home         }
function strf(n: integer): string;
function upcasestr(const s: string): string;
function prsl(g: integer): string;

implementation

function niz(n: integer; c: char): string;
var i: integer;
    r: string;
begin
  r := '';
  for i := 1 to n do r := r + c;
  niz := r;
end;

function nizs(n: integer; const s: string): string;
var i: integer;
    r: string;
begin
  r := '';
  for i := 1 to n do r := r + s;
  nizs := r;
end;

function dlen(const s: string): integer;
var i, n: integer;
begin
  n := 0;
  for i := 1 to length(s) do
    { count every byte that is NOT a UTF-8 continuation byte (10xxxxxx) }
    if (ord(s[i]) and $C0) <> $80 then inc(n);
  dlen := n;
end;

{ ── Raw screen output ─────────────────────────────────────────────── }

const
  { DOS colour index (0..15) -> ANSI SGR foreground code }
  ansiFg : array[0..15] of integer =
    (30,34,32,36,31,35,33,37, 90,94,92,96,91,95,93,97);

procedure rawOut(const s: string);
begin
  if length(s) > 0 then FileWrite(1, s[1], length(s));
end;

procedure scrPut(const s: string);
begin
  rawOut(s);
end;

procedure scrGoto(x, y: integer);
begin
  rawOut(#27 + '[' + strf(y) + ';' + strf(x) + 'H');
end;

procedure scrAttrFB(fg, bg: integer);
begin
  rawOut(#27 + '[0;' + strf(ansiFg[fg and $0F]) + ';' +
         strf(ansiFg[bg and $07] + 10) + 'm');
end;

procedure scrAttr(attr: byte);
begin
  scrAttrFB(attr and $0F, (attr shr 4) and $07);
end;

procedure scrNorm;
begin
  rawOut(#27 + '[0m');
end;

procedure scrCls;
begin
  rawOut(#27 + '[2J' + #27 + '[H');
end;

function strf(n: integer): string;
var s: string;
begin
  Str(n, s);
  strf := s;
end;

{ Uppercase that understands UTF-8 Serbian Cyrillic as well as ASCII.
  Cyrillic lowercase blocks: U+0430..U+044F -> -0x20, U+0450..U+045F -> -0x50
  (the latter covers ђ ј љ њ ћ џ). Other bytes are passed through unchanged. }
function upcasestr(const s: string): string;
var i, cp: integer;
    b1, b2: byte;
    r: string;
begin
  r := '';
  i := 1;
  while i <= length(s) do
  begin
    b1 := ord(s[i]);
    if b1 < $80 then
    begin
      r := r + UpCase(s[i]);
      inc(i);
    end
    else if ((b1 = $D0) or (b1 = $D1)) and (i < length(s)) then
    begin
      b2 := ord(s[i + 1]);
      cp := ((b1 and $1F) shl 6) or (b2 and $3F);
      if (cp >= $0430) and (cp <= $044F) then cp := cp - $20
      else if (cp >= $0450) and (cp <= $045F) then cp := cp - $50;
      r := r + chr($C0 or (cp shr 6)) + chr($80 or (cp and $3F));
      inc(i, 2);
    end
    else
    begin
      r := r + s[i];
      inc(i);
    end;
  end;
  upcasestr := r;
end;

{ Byzantine year shown alongside the Gregorian year in the side panel.
  Anno Mundi = Gregorian + 5508 (before September) or +5509 (after). }
function prsl(g: integer): string;
var s: string;
begin
  Str(g + 5508, s);
  prsl := s + '.';
end;

end.
