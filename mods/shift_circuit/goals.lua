local G={}
function G.current(s,b,phase)
 if phase=='editor'then return {texture='sc_goal_editor.png'}end
 if phase=='lobby'or phase=='loading'then return {texture='sc_goal_start.png'}end
 if phase=='finished'then return {texture=s.failed and 'sc_goal_failed.png'or 'sc_goal_complete.png'}end
 if not b then return {texture='sc_goal_observe.png'}end
 if b.down then return {texture='sc_goal_reboot.png',x=(b.holo_reboot or b.home).x,z=(b.holo_reboot or b.home).z,label='REBOOT'}end
 if s.puzzle and (b.next or 1)>(s.checkpoint_count or 0)then for _,id in ipairs(s.puzzle.targets)do for _,c in pairs(s.crates or {})do if c.id==id and not c.destroyed then return {texture='sc_goal_target_crate.png',x=c.x,z=c.z,label='DESTROY TARGET CRATE'}end end;for _,q in ipairs(s.bots)do if q.id==id and not q.down then return {texture='sc_goal_target_robot.png',x=q.x,z=q.z,label='DESTROY TARGET ROBOT'}end end end end
 local item=s.objective_collect
 if item and not (b.collected_counts and b.collected_counts[item])then
  local best,distance
  for key,kind in pairs(s.pickups or {})do if kind==item then local x,z=key:match('(%d+),(%d+)');x=tonumber(x);z=tonumber(z);local d=math.abs(b.x-x)+math.abs(b.z-z)
   if not distance or d<distance then best={x=x,z=z};distance=d end
  end end
  return {texture='sc_goal_collect_'..item..'.png',x=best and best.x,z=best and best.z,label='COLLECT '..item:upper()}
 end
 local total=s.checkpoint_count or 3;local next=b.next or 1
 if next>total then return {texture='sc_goal_complete.png'}end
 for key,t in pairs(s.board)do if t.kind=='station'and t.number==next then local x,z=key:match('(%d+),(%d+)');return {texture='sc_goal_flag_'..next..'_'..total..'.png',x=tonumber(x),z=tonumber(z),label='CHECKPOINT '..next}end end
 return {texture='sc_goal_observe.png'}
end
return G
