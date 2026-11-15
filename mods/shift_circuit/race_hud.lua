local H={}
function H.rows(s,phase)
 local rows,seen={},{};local total=s.checkpoint_count or 3
 for _,entry in ipairs(s.finishers or {})do rows[#rows+1]={id=entry.id,rank=entry.rank,checkpoint=total,status='finished',human=entry.human};seen[entry.id]=true end
 for _,b in ipairs(s.bots or {})do if not seen[b.id]and (not b.enemy or b.racing)then
  rows[#rows+1]={id=b.id,human=not b.enemy,rank=b.rank,checkpoint=math.min(total,math.max(0,(b.next or 1)-1)),status=b.finished and 'finished'or (b.down and 'down'or ((phase=='program'or phase=='planning_ai')and (b.ready and 'ready'or 'planning')or 'executing'))}
 end end
 table.sort(rows,function(a,b)
  if a.status=='finished'and b.status~='finished'then return true end
  if b.status=='finished'and a.status~='finished'then return false end
  if a.rank and b.rank and a.rank~=b.rank then return a.rank<b.rank end
  if a.checkpoint~=b.checkpoint then return a.checkpoint>b.checkpoint end
  return a.id<b.id
 end)
 return rows
end
return H
