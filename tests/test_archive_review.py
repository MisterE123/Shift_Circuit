from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute('''
R=dofile(path..'/rules.lua');L=dofile(path..'/levels.lua');Q=dofile(path..'/courses.lua');T=dofile(path..'/course_routes.lua')
local s=L.blank(10);s.round=1;s.bots={};s.pickups={};s.walls={};local b={id='A',x=2,z=2,dir=0,hp=5,energy=9,parts={blink=2},home={x=2,z=2,dir=1}};s.bots={b}
R.command(s,b,'BLINK');assert(b.z==4 and b.parts.blink==1 and b.blink_left==0)
R.command(s,b,'BLINK');assert(b.z==4 and b.parts.blink==1)
b.blink_left=1;s.board['2,6']={kind='pit'};R.command(s,b,'BLINK');assert(b.parts.blink==1 and b.energy==8)
s.board['2,6']={kind='floor'};R.command(s,b,'BLINK');R.normalize(b);assert(b.parts.blink==0 and not b.blink)
b.parts={blueprint_archive=1,range=3,cache=2,double_laser=2,hard_disk=1};b.weapon='tractor_beam';b.archive_item='range';b.keep={1};R.drop(b,'Crusher');assert(next(b.parts)==nil and b.weapon=='green_laser'and b.range==4 and #b.keep==0)
R.respawn(s);assert(b.parts.range==1 and b.range==7 and not b.parts.blueprint_archive and b.weapon=='green_laser')
b.parts.blueprint_archive=1;b.weapon='double_laser';b.archive_item='double_laser';R.drop(b,'Fell into a pit');R.respawn(s);assert(b.weapon=='double_laser'and next(b.parts)==nil)
b.parts.blueprint_archive=1;b.archive_item='blueprint_archive';R.drop(b,'Robot weapon');R.respawn(s);assert(b.parts.blueprint_archive==1 and b.weapon=='green_laser')
b.archive_item='not_owned';R.drop(b,'test');R.respawn(s);assert(next(b.parts)==nil)
local data=L.blank(10);local choices={{id='a',size=10,data=data}};local layout={items={{id='a',size=10,w=1,x=2,z=1}}};local route={checkpoints={}}
assert(T.click(route,layout,choices,'start',28,13));assert(T.click(route,layout,choices,'checkpoint',22,12));assert(T.click(route,layout,choices,'checkpoint',28,18));assert(T.validate(route,layout,choices))
local course=Q.assemble(R,{data},2,layout.items,route);assert(not course.route_error and course.start.x==8 and course.start.z==3 and course.board['2,2'].number==1 and course.board['8,8'].number==2)
assert(not T.click(route,layout,choices,'checkpoint',28,13));assert(T.click(route,layout,choices,'checkpoint',22,12));assert(#route.checkpoints==1)
local saved={};local function clone(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=clone(x)end;return t end
local blobs={};local serial=0
local core={get_modpath=function()return path end,get_player_privs=function(n)return {server=n=='admin'}end,serialize=function(v)serial=serial+1;blobs[tostring(serial)]=clone(v);return tostring(serial)end,deserialize=function(v)return clone(blobs[v])end,formspec_escape=function(v)return tostring(v)end,show_formspec=function(n,f,spec)shown=spec end,register_on_player_receive_fields=function(fn)receive=fn end,close_formspec=function()end}
local store={get_string=function(_,k)return saved[k]or ''end,set_string=function(_,k,v)saved[k]=v end,get_int=function(_,k)return saved[k]or 0 end,set_int=function(_,k,v)saved[k]=v end}
local B=dofile(path..'/board_builder.lua');local A=dofile(path..'/course_library.lua')(core,store,B)
local id=A.save('author','Test',layout,2,choices,route);assert(id);assert(not A.review('other',id,'approve'));assert(A.review('admin',id,'note','Please check the route'));assert(A.list('author')[1].notes[1].text=='Please check the route')
assert(A.review('admin',id,'approve'));assert(A.load('other',id,choices,16));assert(A.review('admin',id,'disable'));assert(A.load('author',id,choices,16));assert(not A.load('other',id,choices,16));assert(A.review('admin',id,'enable'));assert(A.load('author',id,choices,16).route.start.x==28)
local E={catalog={['1']={data=data,author='author',approved=false}},review=function(n,id,action,note)assert(n=='admin');reviewed=action;return true,'Saved'end}
local P=dofile(path..'/board_preview.lua');local room={solo_mode='test'}
local M=dofile(path..'/moderation.lua')(core,E,A,P,T,function()return choices end,function()return room end,function()end)
M.open('other');assert(not shown);M.open('admin');assert(shown:find('SUBMISSION REVIEW'));receive({get_player_name=function()return 'admin'end},'shift_circuit:moderation',{inspect_1=true});assert(shown:find('SAVE NOTE FOR SUBMITTER'));receive({get_player_name=function()return 'admin'end},'shift_circuit:moderation',{disable=true});assert(reviewed=='disable')
print('PASS consumable Blink, destruction/reset/archive, translated manual routes, review permissions, notes and configuration availability')
''')


