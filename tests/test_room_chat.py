from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local member={Alpha=1,Beta=1,Gamma=2};local commands,received={},{}
local core={get_player_privs=function(n)return {shout=n~='Muted'}end,
 get_connected_players=function()local list={};for _,n in ipairs({'Alpha','Beta','Gamma','Lobby','Observer','Muted'})do list[#list+1]={get_player_name=function()return n end}end;return list end,
 chat_send_player=function(n,msg)received[n]=msg end,
 register_chatcommand=function(n,def)commands[n]=def end,
 register_on_chat_message=function(fn)chat=fn end}
local C=dofile(path..'/room_chat.lua')(core,member)
assert(chat('Alpha','hello')==true);assert(received.Alpha and received.Beta and not received.Gamma and not received.Lobby)
received={};chat('Lobby','hello');assert(received.Lobby and received.Observer and not received.Alpha and not received.Gamma)
for _,alias in ipairs({'all','global','g'})do received={};assert(commands[alias].func('Alpha','everybody'));for _,n in ipairs({'Alpha','Beta','Gamma','Lobby','Observer'})do assert(received[n]:find('[Global]',1,true))end end
received={};member.Observer=1;chat('Observer','watching');assert(received.Alpha and received.Beta and received.Observer and not received.Gamma)
received={};member.Alpha=nil;chat('Alpha','returned');assert(received.Lobby and not received.Beta)
received={};assert(chat('Alpha','/help')==false and next(received)==nil,'commands pass through')
assert(not commands.g.func('Muted','test'));assert(next(received)==nil,'muted players cannot broadcast')
assert(not commands.g.func('Alpha','  '));assert(next(received)==nil,'empty broadcasts rejected')
print('PASS lobby/room isolation, spectators, room changes, all three global aliases, command passthrough and shout permissions')
""")
