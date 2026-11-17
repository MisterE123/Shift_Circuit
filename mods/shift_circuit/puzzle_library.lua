-- Data-only puzzle packs. Imported maps are validated before becoming playable.
return function(core,L,store,catalog,preview,play,back,edit)
 local MenuUI=dofile(core.get_modpath('shift_circuit')..'/menu_ui.lua');core=MenuUI.wrap(core)
 local data_path=core.get_mod_data_path and core.get_mod_data_path()
 local P={packs={}};local pages={};local filters={};local notices={}
 local function admin(n)return core.get_player_privs(n).server==true end
 local function copy(t)return core.deserialize(core.serialize(t))end
 function P.register(modname,file)
  if file~='puzzles.json'then return false,'Expected puzzles.json'end
  local dir=core.get_modpath(modname);if not dir then return false,'Unknown mod'end
  local f=io.open(dir..'/'..file,'rb');if not f then return false,'Missing manifest'end;local raw=f:read(2000001);f:close();if #raw>2000000 then return false,'Puzzle pack too large'end
  local data=core.parse_json(raw);if type(data)~='table'or data.version~=1 or type(data.puzzles)~='table'or #data.puzzles>100 then return false,'Invalid pack'end
  local game=core.get_game_info and core.get_game_info();local root=game and game.path;local normalized=dir:gsub('\\','/'):lower();root=root and root:gsub('\\','/'):lower()
  local pack={title=tostring(data.title or modname):sub(1,80),builtin=root and normalized:sub(1,#root+6)==root..'/mods/'or false,entries={}}
  pack.tutorial=pack.builtin and data.tutorial==true
  local seen={};for index,entry in ipairs(data.puzzles)do
   if type(entry)~='table'or type(entry.id)~='string'or not entry.id:match('^[a-z0-9_]+$')or seen[entry.id]then return false,'Invalid or duplicate puzzle ID'end;seen[entry.id]=true
   local d,err=L.validate_submission(entry.data);if not d or d.map_type~='puzzle'then return false,err or 'Not a puzzle'end
   pack.entries[#pack.entries+1]={id='pack:'..modname..':'..entry.id,data=d,order=index,source=modname,pack=pack.title,builtin=pack.builtin,tutorial=pack.tutorial,installed=true}
  end
  P.packs[modname]=pack;return true
 end
 function P.entries(n,filter)
  local a={};for _,pack in pairs(P.packs)do for _,e in ipairs(pack.entries)do if (filter=='tutorial'and e.tutorial)or (filter~='tutorial'and not e.tutorial)then a[#a+1]=e end end end
  for id,v in pairs(catalog)do if filter~='tutorial'and v.data.map_type=='puzzle'and (v.approved and v.enabled~=false)then a[#a+1]={id='level:'..id,data=v.data,source='Server',order=(v.data.puzzle or {}).order or tonumber(id),private=not v.approved,status=v.status,author=v.author}end end
  table.sort(a,function(x,y)local gx=x.builtin and 0 or x.installed and 1 or 2;local gy=y.builtin and 0 or y.installed and 1 or 2;if gx~=gy then return gx<gy end;if x.source~=y.source then return x.source<y.source end;if x.order~=y.order then return x.order<y.order end;return x.id<y.id end);return a
 end
 function P.export(n,entries,title)
  if not admin(n)then return false,'Admin permission required'end
  if #entries==0 then return false,'Select maps to export'end
  local race=entries[1].data.map_type~='puzzle';local kind=race and 'boards'or 'puzzles';local prefix='shift_circuit_'..kind..'_'
  local filename=kind..'.json'
  title=tostring(title or 'My puzzles'):sub(1,80);local slug=title:lower():gsub('[^a-z0-9]+','_'):gsub('^_+',''):gsub('_+$',''):sub(1,40);if slug==''then slug='puzzles'end
  local serial=store:get_int('puzzle_export_next')+1;store:set_int('puzzle_export_next',serial);local name=prefix..slug..'_'..serial
  local manifest={version=1,title=title};manifest[kind]={}
  for i,e in ipairs(entries)do local d,err=L.validate_submission(e.data);if not d or (d.map_type~='puzzle')~=race then return false,err or 'Export race boards and puzzles separately'end;manifest[kind][#manifest[kind]+1]={id=(race and 'board_'or 'puzzle_')..i,data=d}end
  if not data_path then return false,'Mod data folder is unavailable'end
  local base=data_path..'/exports';core.mkdir(base);local existing={};for _,entry in ipairs(core.get_dir_list and core.get_dir_list(base,true)or {})do existing[entry]=true end
  local installed={};for _,mod in ipairs(core.get_modnames and core.get_modnames()or {})do installed[mod]=true end
  while existing[name]or installed[name]do serial=serial+1;name=prefix..slug..'_'..serial end;store:set_int('puzzle_export_next',serial)
  local dir=base..'/'..name;core.mkdir(dir)
  local init="local ok,err=shift_circuit.register_"..(race and "board"or "puzzle").."_pack(core.get_current_modname(), '"..filename.."')\nif not ok then error(err) end\n"
  if not core.safe_file_write(dir..'/'..filename,core.write_json(manifest,true))or not core.safe_file_write(dir..'/mod.conf','name = '..name..'\ndepends = shift_circuit\ndescription = Exported Shift Circuit map pack\nlicense = MIT\n')or not core.safe_file_write(dir..'/init.lua',init)then return false,'Export failed; check the server log'end
  local license=[[MIT License

Copyright (c) 2026 Shift Circuit contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


Map data: CC0-1.0 (https://creativecommons.org/publicdomain/zero/1.0/).
Registration code generated with Codex GPT-6 Astra Medium.
]]..'\nAuthor/exporter: '..n..'\n'
  if not core.safe_file_write(dir..'/LICENSE.txt',license)then return false,'Could not write pack license'end
  return true,'Exported '..dir
 end
 function P.open(n,filter)
  if filter then filters[n]=filter;pages[n]=1 end
  local entries=P.entries(n,filters[n]);local page=math.max(1,math.min(pages[n]or 1,math.max(1,math.ceil(#entries/4))));pages[n]=page
  local esc=core.formspec_escape;local f={'formspec_version[6]size[16,12]background[0,0;16,12;sc_setup_background.png]style_type[button;bgimg=sc_menu_button.png;bgimg_pressed=sc_menu_button_pressed.png;border=false]label[.7,.6;'..(filters[n]=='tutorial'and 'TUTORIAL'or 'PUZZLES')..']'}
  local opening,closing=MenuUI.scroll(.6,1.5,14.8,8.1,'puzzles_scroll',math.ceil(#entries/2)*3.8-.3);f[#f+1]=opening
  for index,e in ipairs(entries)do local x=.1+((index-1)%2)*7.5;local y=.12+math.floor((index-1)/2)*3.8
   f[#f+1]=('background9[%s,%s;7.35,3.5;sc_ui_panel.png;false;4]'):format(x-.1,y-.12)
   f[#f+1]=('image[%s,%s;2.7,2.7;%s]button[%s,%s;4.2,.7;play_%d;%s]textarea[%s,%s;4.2,1.65;;;%s]label[%s,%s;%s]'):format(x,y,esc(preview.texture(e.data)),x+2.9,y,index,esc(e.data.title),x+2.9,y+.85,esc((e.data.puzzle or {}).description or ''),x+2.9,y+2.5,esc(e.tutorial and 'TUTORIAL'or e.builtin and 'BUILT-IN'or e.installed and e.pack or e.status and e.status:upper()or e.private and 'PRIVATE / YOUR SAVE'or 'ENABLED'))
   local best=store:get_int('puzzle_best:'..n..':'..e.id);if best==0 and e.id:find('pack:shift_circuit_tutorial:',1,true)==1 then best=store:get_int('puzzle_best:'..n..':'..e.id:gsub('pack:shift_circuit_tutorial:','pack:sc_tutorial:'));if best>0 then store:set_int('puzzle_best:'..n..':'..e.id,best)end end;if best>0 then f[#f+1]=('label[%s,%s;BEST: %d ROUNDS]'):format(x,y+3,best)end
  end
  f[#f+1]=closing
  if #entries==0 then f[#f+1]='label[.8,2;No puzzles yet. Create one in the Workshop.]'end
  f[#f+1]='button[.7,10.8;3,.7;back;MAIN MENU]'
  f[#f+1]='label[.7,10;'..esc(notices[n]or '')..']';core.show_formspec(n,'shift_circuit:puzzles',table.concat(f))
 end
 core.register_on_player_receive_fields(function(player,form,f)
  if form~='shift_circuit:puzzles'then return end;local n=player:get_player_name();local entries=P.entries(n,filters[n])
  for i,e in ipairs(entries)do if f['play_'..i]then local d,err=L.validate_submission(e.data);if d then play(n,copy(d),e.id);core.close_formspec(n,form);return else notices[n]=err end end end
  if f.next then pages[n]=(pages[n]or 1)+1 elseif f.prev then pages[n]=math.max(1,(pages[n]or 1)-1)end
  if f.back then filters[n]=nil;back(n);return end;if not f.quit then P.open(n)end
 end)
 return P
end
