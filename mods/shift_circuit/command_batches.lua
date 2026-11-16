-- Group independent enemy animations while retaining command priority at conflicts.
return function(R)
 local B={}
 local function footprint(s,b,slot)
  local cells={};local function mark(x,z)cells[R.key(x,z)]=true end
  mark(b.x,b.z)
  if b.down or b.finished or b.emp_round==s.round then return cells end
  local c=(b.program or {})[slot]or 'WAIT';local steps=({STEP=1,DASH=2,MOVE3=3,BACK=1,BACK2=2})[c]or 0
  local dir=(c=='BACK'or c=='BACK2')and (b.dir+2)%4 or b.dir
  local ray=c=='PULSE';local blink=c=='BLINK'
  if b.scripted then
   steps=b.kind=='patroller'and 1 or (b.kind=='ram_bot'and b.winding and 3 or 0)
   ray=b.kind=='ram_bot'and not b.winding;blink=false
  end
  local d=R.dirs[dir+1];local x,z=b.x,b.z
  if blink then mark(x+d.x*2,z+d.z*2);return cells end
  if ray then
   for _=1,s.size or 40 do
    if R.blocked(s,x,z,dir)then break end
    x,z=x+d.x,z+d.z;mark(x,z)
    if R.at(s,x,z,b)or R.tile(s,x,z).kind=='wall'then break end
   end
   return cells
  end
  for step=1,steps do
   if R.blocked(s,x,z,dir)then break end
   x,z=x+d.x,z+d.z;mark(x,z)
   local tile=R.tile(s,x,z);if tile.kind=='wall'then break end
   -- Include the entire pushed chain and its destination, even for multi-step cards.
   local px,pz=x,z;local pushed=R.at(s,px,pz,b)~=nil
   while R.at(s,px,pz,b)do
    if R.blocked(s,px,pz,dir)then break end
    px,pz=px+d.x,pz+d.z;mark(px,pz)
   end
   if pushed then for _=step+1,steps do if R.blocked(s,px,pz,dir)or R.tile(s,px,pz).kind=='pit'then break end;px,pz=px+d.x,pz+d.z;mark(px,pz)end end
   if tile.kind=='pit'then break end
  end
  return cells
 end
 function B.take(s,pending,slot)
  local batch,remaining,earlier={},{},{}
  for _,b in ipairs(pending)do
   local cells=footprint(s,b,slot);local blocked=false
   for _,previous in ipairs(earlier)do
    if not b.enemy or not previous.bot.enemy then blocked=true;break end
    for cell in pairs(cells)do if previous.cells[cell]then blocked=true;break end end
    if blocked then break end
   end
   if blocked then remaining[#remaining+1]=b else batch[#batch+1]=b end
   earlier[#earlier+1]={bot=b,cells=cells}
  end
  return batch,remaining
 end
 return B
end
