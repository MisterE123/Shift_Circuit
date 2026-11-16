-- Shared pixel UI chrome. Nine-slicing keeps borders crisp at every menu size.
local U={}
local function panel(x,y,w,h)return ('background9[%s,%s;%s,%s;sc_ui_panel.png;false;8]'):format(x,y,w,h)end

function U.wrap_tooltips(text)
 local out={};local cursor=1
 while true do
  local start=text:find('tooltip[',cursor,true);if not start then out[#out+1]=text:sub(cursor);break end
  out[#out+1]=text:sub(cursor,start-1);local fields={};local part={};local i=start+8
  while i<=#text do
   local c=text:sub(i,i)
   if c=='\\'then part[#part+1]=text:sub(i,i+1);i=i+2
   elseif c==';'or c==']'then fields[#fields+1]=table.concat(part);part={};i=i+1;if c==']'then break end
   else part[#part+1]=c;i=i+1 end
  end
  local index=fields[1]and fields[1]:match('^%-?[%d.]+,%-?[%d.]+$')and 3 or 2
  if fields[index]then
   local lines={}
   for line in (fields[index]..'\n'):gmatch('(.-)\n')do
    local current=''
    for word in line:gmatch('%S+')do
     if #current>0 and #current+1+#word>52 then lines[#lines+1]=current;current=''end
     current=current==''and word or current..' '..word
    end
    lines[#lines+1]=current
   end
   fields[index]=table.concat(lines,'\n')
  end
  out[#out+1]='tooltip['..table.concat(fields,';')..']';cursor=i
 end
 return table.concat(out)
end

function U.decorate(text)
 text=U.wrap_tooltips(text)
 if text:find('sc_ui_frame.png',1,true)then return text end
 local w,h=text:match('size%[([%d.]+),([%d.]+)');w,h=tonumber(w),tonumber(h);if not w then return text end
 text=text:gsub('(sc_ui_[%w_]+%.png;false;)4%]', function(prefix)return prefix..'8]'end)
 text=text:gsub('background%[[^%]]-sc_[%w_]+%.png%]',''):gsub('bgcolor%[[^%]]*%]',''):gsub('style_type%[button;[^%]]*%]','')
 local chrome=('bgcolor[#050d16dd;true]background9[0,0;%s,%s;sc_ui_frame.png;false;8]'):format(w,h)
 chrome=chrome..'style_type[button,button_exit;bgimg=sc_ui_button.png;bgimg_hovered=sc_ui_hover.png;bgimg_pressed=sc_ui_pressed.png;bgimg_middle=8;border=false;textcolor=#e1f1ee]style_type[label,textarea,checkbox;textcolor=#d7e8e9]style_type[field,pwdfield;bgcolor=#193644;border=true;textcolor=#eff9f5]style_type[textarea;bgcolor=#193644;border=false]style_type[dropdown;bgcolor=#24414d;textcolor=#e1f1ee;border=false]listcolors[#142d39;#24414d;#49777d;#142d39;#e1f1ee]'
 -- Calm content panels replace the old oversized decorative industrial borders.
 local header_y=text:match('label%[[%d.]+,([%d.]+);');if header_y and tonumber(header_y)<=.8 then chrome=chrome..('box[.45,%s;%s,.025;#49777d]'):format(text:find('ROBOT / DASHBOARD',1,true)and .78 or 1.02,w-.9)end
 if text:find('SINGLEPLAYER',1,true)then chrome=chrome..panel(.45,1.25,6.5,5)..panel(7.05,1.25,6.5,5)..panel(.45,6.75,13.1,2.65)
 elseif text:find('FACTORY WORKSHOP',1,true)and h==11 then chrome=chrome..panel(.45,3.8,8.25,3.4)..panel(8.85,3.8,4.7,3.25)
 elseif text:find('SOLO RACE',1,true)then chrome=chrome..panel(.45,1.15,13.1,3.2)..panel(.45,4.4,13.1,3.65)
 elseif text:find('YOUR PERSONAL MIX',1,true)then chrome=chrome..panel(.65,1.5,12.7,2.35)..panel(.65,4.1,12.7,2.35)
 elseif text:find('SUBMISSION REVIEW',1,true)and text:find('Review history',1,true)then chrome=chrome..panel(8,1.5,7.4,7.3)
 end
 -- Apply action hierarchy without changing field names or event behavior.
 local styles={}
 for geometry,key,label in text:gmatch('button%[([^;]+;[^;]+);([^;]+);([^%]]*)%]')do
  label=label:gsub('\\([%[%]])','%1')
  local texture
  if label:sub(1,2)=='> 'or label:match('^%[')or label:find(' / SELECTED',1,true)then texture='selected'
  elseif key=='launch'or key=='play_solo'or key=='create_confirm'or key=='save_library'or key=='config_save'or key=='resume'or key:match('^play_%d+$')then texture='primary'
  elseif key:find('delete',1,true)or key=='reset_draft'or key=='reject'or key=='disable_entry'or key=='disable'then texture='danger'end
  if texture then styles[#styles+1]='style['..key..';bgimg=sc_ui_'..texture..'.png]';if texture=='selected'then styles[#styles+1]=U.selected(key)end end
 end
 -- Named text areas are editable; empty-name text areas are read-only descriptions.
 for geometry,key in text:gmatch('textarea%[([^;]+;[^;]+);([^;]*);')do if key~=''then styles[#styles+1]='style['..key..';border=true;bgcolor=#193644]'end end
 text=text:gsub('image%[([^;]+;[^;]+);sc_dashboard_(%w+)%.png%]',function(geometry,kind)if kind=='stat'or kind=='weapon'or kind=='equipment'then return 'image['..geometry..';sc_ui_panel.png;8]'end;return 'image['..geometry..';sc_dashboard_'..kind..'.png]'end)
 -- Insert styles after size, ahead of elements so Luanti applies them consistently.
 local pos=text:find(']',text:find('size[',1,true),true)
 return text:sub(1,pos)..chrome..table.concat(styles)..text:sub(pos+1)
end
function U.selected(key)
 return 'style['..key..';bgimg=sc_ui_selected.png]style['..key..':hovered;bgimg=sc_ui_selected_hover.png]style['..key..':pressed;bgimg=sc_ui_selected_pressed.png]'
end
function U.scroll(x,y,w,h,key,content)
 local max=math.max(0,math.ceil((content-h)*10))
 if max==0 then return ('container[%s,%s]'):format(x,y),'container_end[]'end
 return ('scrollbaroptions[min=0;max=%d;smallstep=3;largestep=%d;thumbsize=%d]scrollbar[%s,%s;.22,%s;vertical;%s;0]scroll_container[%s,%s;%s,%s;%s;vertical;.1]'):format(max,math.max(1,math.floor(h*8)),math.max(1,math.floor(h*10)),x+w+.12,y,h,key,x,y,w,h,key),'scroll_container_end[]'
end
function U.wrap(core)
 if core._sc_menu_theme then return core end
 local proxy=setmetatable({_sc_menu_theme=true},{__index=core});local offsets={}
 proxy.show_formspec=function(name,form,text)
  local saved=offsets[name]and offsets[name][form]or {}
  text=text:gsub('(scrollbar%[[^;]+;[^;]+;[^;]+;([^;]+);)[%d.]+%]',function(prefix,key)return prefix..(saved[key]or 0)..']'end)
  return core.show_formspec(name,form,U.decorate(text))
 end
 if core.register_on_player_receive_fields then proxy.register_on_player_receive_fields=function(fn)
  core.register_on_player_receive_fields(function(p,form,fields)
   local n=p:get_player_name();offsets[n]=offsets[n]or {};offsets[n][form]=offsets[n][form]or {}
   for key,value in pairs(fields)do if key:match('_scroll$')and type(value)=='string'then local v=value:match('^[A-Z]+:(%d+)$');if v then offsets[n][form][key]=tonumber(v)end end end
   for key,value in pairs(fields)do if key:match('_scroll$')and type(value)=='string'and value:match('^CHG:')then return end end
   return fn(p,form,fields)
  end)
 end end
 return proxy
end
return U
