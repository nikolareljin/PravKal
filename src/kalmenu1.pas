{$mode tp}
unit kalmenu1;
{
  Menu bar, drop-down menus, and function-key strip.
  Replaces the original DOS kalmenu1 unit.
  Uses FPC crt for all screen output.
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
    sta : array[1..2] of string[20];
    kps : byte;
  end;

  { Screen-row save buffers — allocated but not used for direct video in FPC }
  mmmem : pointer;
  pamzr : pointer;
  kkmem : pointer;

procedure showmainmenu;
procedure showkeyfunc(n: byte);
function  tastmenu: word;

implementation

{ ── Color helpers ───────────────────────────────────────────────── }

procedure setAttr(attr: byte);
begin
  TextColor(attr and $0F);
  TextBackground((attr shr 4) and $07);
end;

{ ── Menu bar (row 1) ────────────────────────────────────────────── }

procedure showmainmenu;
var i: integer;
begin
  GotoXY(1, 1);
  setAttr(co[4]);
  Write(niz(79, ' '));
  for i := 1 to mmmax do
  begin
    GotoXY(mmpos[i], 1);
    setAttr(co[4]);
    Write(' ' + mainm[i] + ' ');
  end;
  NormVideo;
end;

{ ── Function-key strip (row 25) ─────────────────────────────────── }

procedure showkeyfunc(n: byte);
var i: integer;
begin
  GotoXY(1, 25);
  setAttr(co[1]);
  Write(niz(79, ' '));
  for i := 1 to n do
  begin
    GotoXY(kfun[i].kps, 25);
    setAttr(co[6]);
    Write(kfun[i].sta[1]);
    setAttr(co[1]);
    Write(' ' + kfun[i].sta[2]);
  end;
  NormVideo;
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
  GotoXY(x, y);
  setAttr(co[27]);
  Write(BOX_ULC + niz(w, BOX_H) + BOX_URC);
  { items }
  for j := 1 to mmnli[mi] do
  begin
    GotoXY(x, y + j);
    if j = selected then
      setAttr(co[15])
    else
      setAttr(co[27]);
    Write(BOX_V + ' ' + mmsss[mi][j] +
          niz(w - length(mmsss[mi][j]) - 1, ' ') + BOX_V);
  end;
  { bottom border }
  GotoXY(x, y + mmnli[mi] + 1);
  setAttr(co[27]);
  Write(BOX_LLC + niz(w, BOX_H) + BOX_LRC);
  NormVideo;
end;

procedure eraseDropDown(mi: byte);
var j: byte;
    x: byte;
begin
  x := mmpos[mi];
  for j := 2 to mmnli[mi] + 3 do
  begin
    GotoXY(x, j);
    setAttr(co[1]);
    Write(niz(mmdim[mi][1] + 2, ' '));
  end;
  NormVideo;
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
    GotoXY(mmpos[curMenu], 1);
    setAttr(co[15]);
    Write(' ' + mainm[curMenu] + ' ');
    NormVideo;
    k := ReadKey;
    if k = #0 then k := ReadKey;  { extended key: consume prefix }
    case k of
      rightkey:
        begin
          eraseDropDown(curMenu);
          GotoXY(mmpos[curMenu], 1);
          setAttr(co[4]);
          Write(' ' + mainm[curMenu] + ' ');
          if curMenu < mmmax then inc(curMenu) else curMenu := 1;
          curItem := 1;
          drawDropDown(curMenu, curItem);
        end;
      leftkey:
        begin
          eraseDropDown(curMenu);
          GotoXY(mmpos[curMenu], 1);
          setAttr(co[4]);
          Write(' ' + mainm[curMenu] + ' ');
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
          eraseDropDown(curMenu);
          GotoXY(mmpos[curMenu], 1);
          setAttr(co[4]);
          Write(' ' + mainm[curMenu] + ' ');
          NormVideo;
          tastmenu := 0;
          exit;
        end;
    end;
  until done;
  eraseDropDown(curMenu);
  GotoXY(mmpos[curMenu], 1);
  setAttr(co[4]);
  Write(' ' + mainm[curMenu] + ' ');
  NormVideo;
  tastmenu := word(curMenu) shl 8 or word(curItem);
end;

begin
  mmmem := nil;
  pamzr := nil;
  kkmem := nil;
end.
