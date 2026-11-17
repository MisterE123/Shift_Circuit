local R=dofile(assert(PROOF_RULES_PATH))
local E={R=R}
local ignore={shots=true,collections=true,reaches=true,drop_events=true,drop_falls=true,factory_events=true,finish_events=true,pickup_moves=true,pickup_losses=true,last_action=true,last_laser=true,action_serial=true,hit_serial=true,save_serial=true,parts_serial=true,last_collect=true,collect_serial=true}
local function clone(t)
 if type(t)~='table'then return t end
 local r={};for k,v in pairs(t)do if not ignore[k]and not tostring(k):match('_serial$')then r[k]=clone(v)end end;return r
end
E.clone=clone
function E.step(state,command,depth,settings,seed)
 local s=clone(state);local b=s.bots[1];s.round=math.floor((depth-1)/5)+1;s.register=(depth-1)%5+1
 math.randomseed((seed or 911)+depth)
 if settings then b.enabled={gyro_stabilizer=settings.gyro,electromagnetic_brake=settings.brake};b.aim_offset=settings.aim or 0 end
 b.program={};b.program[s.register]=command;b.program_ids={100000,100000,100000,100000,100000}
 for _,o in ipairs(s.bots)do if o.scripted then o.program={'WAIT','WAIT','WAIT','WAIT','WAIT'}end end
 R.programs(s,s.register);if b.down then return nil end
 R.belts(s,true);R.collect_phase(s);R.belts(s,false);R.collect_phase(s)
 R.pushers(s,s.register);R.plates(s);R.collect_phase(s);R.rotators(s)
 R.robot_weapons(s,s.register);R.collect_phase(s);R.lasers(s);R.hazards(s,s.register)
 R.register_repairs(s);R.ghosts(s,true)
 if b.down then return nil end
 if s.register==5 and not b.finished then R.repairs(s);R.respawn(s);s.round=s.round+1;R.ghosts(s,true);R.spawn_pickups(s)end
 return s
end
return E
