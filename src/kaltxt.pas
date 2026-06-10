{$mode tp}
unit kaltxt;
{
  Plain-text file export for PravKal.
  Pure Pascal I/O — no external units, works on Linux / macOS / Windows.
}

interface

const
  KTXT_MAXLINES = 120;

type
  TKTXTLine  = string[255];
  TKTXTLines = array[0..KTXT_MAXLINES - 1] of TKTXTLine;

{ Write nlines from lines[] as a plain-text file to fname.
  Returns true on success, false on any I/O error. }
function writeTXTLines(const fname  : TKTXTLine;
                             nlines : integer;
                       const lines  : TKTXTLines): boolean;

implementation

function writeTXTLines(const fname  : TKTXTLine;
                             nlines : integer;
                       const lines  : TKTXTLines): boolean;
var
  f : text;
  i : integer;
  r : integer;
begin
  writeTXTLines := false;
  Assign(f, fname);
  {$I-}
  Rewrite(f);
  r := IOResult;
  {$I+}
  if r <> 0 then exit;
  {$I-}
  for i := 0 to nlines - 1 do
    WriteLn(f, lines[i]);
  Close(f);
  r := IOResult;
  {$I+}
  if r <> 0 then exit;
  writeTXTLines := true;
end;

end.
