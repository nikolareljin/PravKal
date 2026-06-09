{$mode tp}
unit nizz;
{
  String utilities and shared type definitions.
  Replaces the original DOS-era nizz unit.
}

interface

type
  pathstr = string[255];
  namestr = string[9];
  extstr  = string[5];
  kstr    = string[15];
  prstr   = string[70];
  tbstr   = string[65];
  spec    = array[1..2] of integer;
  mssm    = array[1..2] of byte;

{ Box-drawing: ASCII for now — upgrade to UTF-8 box chars later }
const
  BOX_V    = '|';   { was #179  │ }
  BOX_H    = '-';   { was #196  ─ }
  BOX_ULC  = '+';   { was #218  ┌ }
  BOX_URC  = '+';   { was #191  ┐ }
  BOX_LLC  = '+';   { was #192  └ }
  BOX_LRC  = '+';   { was #217  ┘ }
  BOX_LTEE = '+';   { was #195  ├ }
  BOX_RTEE = '+';   { was #180  ┤ }
  BOX_BTEE = '+';   { was #193  ┴ }
  BOX_TTEE = '+';   { was #194  ┬ }
  BOX_CROSS= '+';   { was #197  ┼ }
  BOX_BULL = '*';   { was #254  ■ }

function niz(n: integer; c: char): string;
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

function strf(n: integer): string;
var s: string;
begin
  Str(n, s);
  strf := s;
end;

function upcasestr(const s: string): string;
var i: integer;
    r: string;
begin
  r := s;
  for i := 1 to length(r) do
    r[i] := UpCase(r[i]);
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
