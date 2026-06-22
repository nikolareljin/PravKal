{$mode tp}
unit kalmenu1;
{
  Menu bar, drop-down menus, and function-key strip.
  Replaces the original DOS kalmenu1 unit.
  Screen output goes through nizz's raw ANSI layer (UTF-8 safe);
  crt is used only for keyboard input (ReadKey).
}

interface

uses crt, nizz, kalsys1;

const
  { Extended key scan codes (returned by scankey after consuming #0/#224 prefix) }
  F1       = #59;
  F2       = #60;
  F3       = #61;
  F4       = #62;
  F5       = #63;
  F6       = #64;
  F7       = #65;
  F8       = #66;
  F9       = #67;
  F10      = #68;
  upkey    = #72;
  downkey  = #80;
  leftkey  = #75;
  rightkey = #77;
  pgupkey  = #73;
  pgdnkey  = #81;
  homekey  = #71;
  endkey   = #79;
  esckey   = #27;
  enterkey = #13;

const
  MMMAX_CAP = 5;
  MMNLI_CAP = 6;

var
  mmmax : byte;
  mainm : array[1..MMMAX_CAP] of string;
  mainh : array[1..MMMAX_CAP] of string;
  mmsss : array[1..MMMAX_CAP, 1..MMNLI_CAP] of string;
  mmsuh : array[1..MMMAX_CAP, 1..MMNLI_CAP] of string;
  mmpos : array[1..MMMAX_CAP] of byte;
  mmpol : array[1..MMMAX_CAP] of byte;
  mmdim : array[1..MMMAX_CAP] of mssm;
  mmnli : array[1..MMMAX_CAP] of byte;
  mmcrt : array[1..MMMAX_CAP] of byte;
  mmpcm : array[1..MMMAX_CAP] of byte;
  mmboj : array[1..MMMAX_CAP] of string;

  { kfun: function-key label strip, each entry has 2 labels and a column pos }
  kfun  : array[1..5] of record
    sta : array[1..2] of string[40];   { string[20] -> [40]: Cyrillic is 2 bytes/char }
    kps : byte;
  end;

  { Screen-row save buffers — allocated but not used for direct video in FPC }
  mmmem : pointer;
  pamzr : pointer;
  kkmem : pointer;

  { Optional callback set by the caller before tastmenu.
    Called instead of eraseDropDown so the full calendar is restored
    before each new dropdown is drawn. }
  onNavRedraw : procedure;

procedure showmainmenu;
procedure showkeyfunc(n: byte);
function  tastmenu: word;

implementation

{ ── Color helpers ───────────────────────────────────────────────── }

procedure setAttr(attr: byte);
begin
  scrAttr(attr);
end;

{ ── Menu bar (row 1) ────────────────────────────────────────────── }

procedure showmainmenu;
var i: integer;
begin
  scrGoto(1, 1);
  setAttr(co[4]);
  scrPut(niz(79, ' '));
  for i := 1 to mmmax do
  begin
    scrGoto(mmpos[i], 1);
    setAttr(co[4]);
    scrPut(' ' + mainm[i] + ' ');
  end;
  scrNorm;
end;

{ ── Function-key strip (row 25) ─────────────────────────────────── }

procedure showkeyfunc(n: byte);
var i: integer;
begin
  scrGoto(1, 25);
  setAttr(co[1]);
  scrPut(niz(79, ' '));
  for i := 1 to n do
  begin
    scrGoto(kfun[i].kps, 25);
    setAttr(co[6]);
    scrPut(kfun[i].sta[1]);
    setAttr(co[1]);
    scrPut(' ' + kfun[i].sta[2]);
  end;
  scrNorm;
end;

{ ── Drop-down rendering ─────────────────────────────────────────── }

procedure drawDropDown(mi: byte; selected: byte);
var j    : byte;
    x, y : byte;
    w    : byte;
begin
  x := mmpos[mi];
  y := 2;
  w := mmdim[mi][1];
  { top border }
  scrGoto(x, y);
  setAttr(co[27]);
  scrPut(BOX_ULC + nizs(w, BOX_H) + BOX_URC);
  { items }
  for j := 1 to mmnli[mi] do
  begin
    scrGoto(x, y + j);
    if j = selected then
      setAttr(co[15])
    else
      setAttr(co[27]);
    scrPut(BOX_V + ' ' + mmsss[mi][j] +
          niz(w - dlen(mmsss[mi][j]) - 1, ' ') + BOX_V);
  end;
  { bottom border }
  scrGoto(x, y + mmnli[mi] + 1);
  setAttr(co[27]);
  scrPut(BOX_LLC + nizs(w, BOX_H) + BOX_LRC);
  scrNorm;
end;

procedure eraseDropDown(mi: byte);
var j: byte;
    x: byte;
begin
  x := mmpos[mi];
  for j := 2 to mmnli[mi] + 3 do
  begin
    scrGoto(x, j);
    setAttr(co[1]);
    scrPut(niz(mmdim[mi][1] + 2, ' '));
  end;
  scrNorm;
end;

{ ── Menu navigation ─────────────────────────────────────────────── }

function tastmenu: word;
var curMenu : byte;
    curItem : byte;
    k       : char;
    done    : boolean;
begin
  curMenu := 1;
  curItem := 1;
  done    := false;
  drawDropDown(curMenu, curItem);
  repeat
    { highlight active menu title }
    scrGoto(mmpos[curMenu], 1);
    setAttr(co[15]);
    scrPut(' ' + mainm[curMenu] + ' ');
    scrNorm;
    k := ReadKey;
    if k = #0 then k := ReadKey;  { extended key: consume prefix }
    case k of
      rightkey:
        begin
          if Assigned(onNavRedraw) then onNavRedraw
          else begin
            eraseDropDown(curMenu);
            scrGoto(mmpos[curMenu], 1);
            setAttr(co[4]);
            scrPut(' ' + mainm[curMenu] + ' ');
          end;
          if curMenu < mmmax then inc(curMenu) else curMenu := 1;
          curItem := 1;
          drawDropDown(curMenu, curItem);
        end;
      leftkey:
        begin
          if Assigned(onNavRedraw) then onNavRedraw
          else begin
            eraseDropDown(curMenu);
            scrGoto(mmpos[curMenu], 1);
            setAttr(co[4]);
            scrPut(' ' + mainm[curMenu] + ' ');
          end;
          if curMenu > 1 then dec(curMenu) else curMenu := mmmax;
          curItem := 1;
          drawDropDown(curMenu, curItem);
        end;
      downkey:
        begin
          if curItem < mmnli[curMenu] then
          begin
            inc(curItem);
            drawDropDown(curMenu, curItem);
          end;
        end;
      upkey:
        begin
          if curItem > 1 then
          begin
            dec(curItem);
            drawDropDown(curMenu, curItem);
          end;
        end;
      enterkey:
        done := true;
      esckey:
        begin
          if Assigned(onNavRedraw) then onNavRedraw
          else begin
            eraseDropDown(curMenu);
            scrGoto(mmpos[curMenu], 1);
            setAttr(co[4]);
            scrPut(' ' + mainm[curMenu] + ' ');
          end;
          scrNorm;
          tastmenu := 0;
          exit;
        end;
    end;
  until done;
  eraseDropDown(curMenu);
  scrGoto(mmpos[curMenu], 1);
  setAttr(co[4]);
  scrPut(' ' + mainm[curMenu] + ' ');
  scrNorm;
  tastmenu := word(curMenu) shl 8 or word(curItem);
end;

begin
  mmmem      := nil;
  pamzr      := nil;
  kkmem      := nil;
  onNavRedraw := nil;
end.
