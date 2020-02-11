unit LuaeXComponent;

{$mode delphi}

interface

uses
  Classes, SysUtils,lua, lualib, lauxlib, LuaHandler, LuaCaller,
  ExtCtrls, StdCtrls, ExtraTrainerComponents;

procedure initializeLuaeXComponent;

implementation

uses LuaClass, LuaWinControl;

function eXcomponent_getActive(L: PLua_State): integer; cdecl;
var
  eXcomponent: TeX;
begin
  eXcomponent:=luaclass_getClassObject(L);
  lua_pushboolean(L, eXcomponent.activated);
  result:=1;
end;


function eXcomponent_setActive(L: PLua_State): integer; cdecl;
var
  paramstart, paramcount: integer;
  eXcomponent: TeX;

  deactivatetime: integer;
  t: TTimer;
begin
  result:=0;
  eXcomponent:=luaclass_getClassObject(L, @paramstart, @paramcount);


  if paramcount>=1 then
  begin
    eXcomponent.activated:=lua_toboolean(L,paramstart);

    if paramcount=2 then
    begin
      deactivatetime:=lua_tointeger(L,paramstart+1);
      if eXcomponent.activated then
        eXcomponent.setDeactivateTimer(deactivatetime);

    end;
  end;
end;

function eXcomponent_getDescription(L: PLua_State): integer; cdecl;
var
  parameters: integer;
  eXcomponent: TeX;
begin
  eXcomponent:=luaclass_getClassObject(L);
  lua_pushstring(L, eXcomponent.Description);
  result:=1;
end;


function eXcomponent_setDescription(L: PLua_State): integer; cdecl;
var
  parameters: integer;
  eXcomponent: TeX;

  deactivatetime: integer;
  t: TTimer;
begin
  result:=0;
  eXcomponent:=luaclass_getClassObject(L);

  if lua_gettop(L)>=1 then
    eXcomponent.Description:=Lua_ToString(L,-1);
end;

function eXcomponent_getHotkey(L: PLua_State): integer; cdecl;
var
  parameters: integer;
  eXcomponent: TeX;
begin
  result:=0;
  eXcomponent:=luaclass_getClassObject(L);
  lua_pushstring(L, eXcomponent.Hotkey);
  result:=1;
end;


function eXcomponent_setHotkey(L: PLua_State): integer; cdecl;
var
  eXcomponent: TeX;

  deactivatetime: integer;
  t: TTimer;
begin
  result:=0;
  eXcomponent:=luaclass_getClassObject(L);
  if lua_gettop(L)>=1 then
    eXcomponent.Hotkey:=Lua_ToString(L,-1);
end;

function eXcomponent_getDescriptionLeft(L: PLua_State): integer; cdecl;
var
  eXcomponent: TeX;
begin
  eXcomponent:=luaclass_getClassObject(L);
  lua_pushinteger(L, eXcomponent.DescriptionLeft);
  result:=1;
end;


function eXcomponent_setDescriptionLeft(L: PLua_State): integer; cdecl;
var
  parameters: integer;
  eXcomponent: TeX;

  deactivatetime: integer;
  t: TTimer;
begin
  result:=0;
  eXcomponent:=luaclass_getClassObject(L);

  if lua_gettop(L)>=1 then
    eXcomponent.Descriptionleft:=lua_tointeger(L,-1);
end;


function eXcomponent_getHotkeyLeft(L: PLua_State): integer; cdecl;
var
  parameters: integer;
  eXcomponent: TeX;
begin
  result:=0;
  eXcomponent:=luaclass_getClassObject(L);
  lua_pushinteger(L, eXcomponent.Hotkeyleft);
  result:=1;
end;


function eXcomponent_setHotkeyLeft(L: PLua_State): integer; cdecl;
var
  eXcomponent: TeX;

  deactivatetime: integer;
  t: TTimer;
begin
  result:=0;
  eXcomponent:=luaclass_getClassObject(L);
  if lua_gettop(L)>=1 then
    eXcomponent.Hotkeyleft:=lua_tointeger(L,-1);
end;

function eXcomponent_getEditValue(L: PLua_State): integer; cdecl;
var
  eXcomponent: TeX;
begin
  eXcomponent:=luaclass_getClassObject(L);
  lua_pushstring(L, eXcomponent.EditValue);
  result:=1;
end;


function eXcomponent_setEditValue(L: PLua_State): integer; cdecl;
var
  parameters: integer;
  eXcomponent: TeX;

  deactivatetime: integer;
  t: TTimer;
begin
  result:=0;
  eXcomponent:=luaclass_getClassObject(L);
  if lua_gettop(L)>=1 then
    eXcomponent.EditValue:=Lua_ToString(L,-1);
end;

procedure eXcomponent_addMetaData(L: PLua_state; metatable: integer; userdata: integer );
begin
  wincontrol_addMetaData(L, metatable, userdata);
  luaclass_addClassFunctionToTable(L, metatable, userdata, 'setActive', eXcomponent_setActive);
  luaclass_addClassFunctionToTable(L, metatable, userdata, 'getActive', eXcomponent_getActive);
end;

procedure initializeLuaeXComponent;
begin
  Lua_register(LuaVM, 'eXcomponent_setActive', eXcomponent_setActive);
  Lua_register(LuaVM, 'eXcomponent_getActive', eXcomponent_getActive);
  Lua_register(LuaVM, 'eXcomponent_setDescription', eXcomponent_setDescription);
  Lua_register(LuaVM, 'eXcomponent_getDescription', eXcomponent_getDescription);
  Lua_register(LuaVM, 'eXcomponent_setHotkey', eXcomponent_setHotkey);
  Lua_register(LuaVM, 'eXcomponent_getHotkey', eXcomponent_getHotkey);
  Lua_register(LuaVM, 'eXcomponent_setDescriptionLeft', eXcomponent_setDescriptionLeft);
  Lua_register(LuaVM, 'eXcomponent_getDescriptionLeft', eXcomponent_getDescriptionLeft);
  Lua_register(LuaVM, 'eXcomponent_setHotkeyLeft', eXcomponent_setHotkeyLeft);
  Lua_register(LuaVM, 'eXcomponent_getHotkeyLeft', eXcomponent_getHotkeyLeft);
  Lua_register(LuaVM, 'eXcomponent_setEditValue', eXcomponent_setEditValue);
  Lua_register(LuaVM, 'eXcomponent_getEditValue', eXcomponent_getEditValue);
end;

initialization
  luaclass_register(TeX, eXcomponent_addMetaData);


end.

