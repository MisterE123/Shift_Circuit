-- Per-player audio mix. Music is non-positional and never shared across sessions.
return function(core,store)
 local M={};local active,settings,retiring,last_click={},{},{},{};local clock=0
 local function pref(name)
  if not settings[name]then local p=core.deserialize(store:get_string('audio:'..name));settings[name]=type(p)=='table' and p or {music=.12,effects=1}end
  return settings[name]
 end
 local function stop(handle)if handle and core.sound_stop then core.sound_stop(handle)end end
 local function fade(handle,rate,gain)if handle and core.sound_fade then core.sound_fade(handle,rate,gain)end end
 function M.settings(name)return pref(name)end
 function M.set(name,key,value)
  if key~='music' and key~='effects'then return end
  local allowed=key=='music' and {[0]=true,[.12]=true,[.22]=true} or {[0]=true,[.5]=true,[1]=true}
  if not allowed[value]then return end
  pref(name)[key]=value;store:set_string('audio:'..name,core.serialize(pref(name)))
 end
 function M.effect(name,spec,params)
  local gain=pref(name).effects;if gain<=0 or not core.sound_play then return end
  local p={};for k,v in pairs(params or {})do p[k]=v end;p.to_player=name;p.gain=(p.gain or .4)*gain
  core.sound_play(spec,p,true)
 end
 function M.click(name,pitch)
  if last_click[name] and clock-last_click[name]<.075 then return end;last_click[name]=clock
  M.effect(name,'sc_ui_click',{gain=.22,pitch=pitch or 1})
 end
 function M.update(name,mode,executing)
  local volume=pref(name).music*(mode=='game' and (executing and .45 or .65) or 1)
  local old=active[name]
  if old and (old.mode~=mode or volume==0)then
   local h=old.handle;fade(h,.16,0);if h then retiring[h]=1.8 end;active[name]=nil;old=nil
  end
  if volume<=0 then return end
  if not old then
   local h=core.sound_play and core.sound_play('sc_music_'..mode,{to_player=name,gain=.001,loop=true},false)
   old={mode=mode,handle=h};active[name]=old
  end
  if old.gain~=volume then fade(old.handle,.12,volume);old.gain=volume end
 end
 function M.tick(dt)
  clock=clock+dt;for h,left in pairs(retiring)do left=left-dt;if left<=0 then stop(h);retiring[h]=nil else retiring[h]=left end end
 end
 function M.leave(name)
  local a=active[name];if a then stop(a.handle)end;active[name]=nil;last_click[name]=nil;settings[name]=nil
 end
 function M.shutdown()for n in pairs(active)do M.leave(n)end;for h in pairs(retiring)do stop(h)end;retiring={}end
 return M
end
