-- Shared inventory of board pieces. One grid cell represents ten game squares.
local B={width=4}
local function adjacent(a,b)
 return ((a.x+a.w==b.x or b.x+b.w==a.x)and math.max(a.z,b.z)<math.min(a.z+a.w,b.z+b.w))or
 ((a.z+a.w==b.z or b.z+b.w==a.z)and math.max(a.x,b.x)<math.min(a.x+a.w,b.x+b.w))
end
function B.connected(items)
 if #items<2 then return true end
 local seen={[1]=true};local queue={1};local head=1
 while queue[head]do local i=queue[head];head=head+1;for j,q in ipairs(items)do if not seen[j]and adjacent(items[i],q)then seen[j]=true;queue[#queue+1]=j end end end
 return #queue==#items
end
function B.new(limit)return {limit=16,items={},revision=0}end
function B.at(layout,x,z)
 for i,q in ipairs(layout.items)do if x>=q.x and x<q.x+q.w and z>=q.z and z<q.z+q.w then return i,q end end
end
function B.place(layout,id,size,x,z)
 if size~=10 and size~=20 then return false,'Invalid board size'end
 local w=size/10
 if type(x)~='number'or type(z)~='number'or x~=math.floor(x)or z~=math.floor(z)or x<0 or z<0 or x+w>B.width or z+w>B.width then return false,'This board does not fit inside the grid'end
 for dx=0,w-1 do for dz=0,w-1 do if B.at(layout,x+dx,z+dz)then return false,'Those inventory squares are occupied'end end end
 local q={id=id,size=size,w=w,x=x,z=z};layout.items[#layout.items+1]=q
 if not B.connected(layout.items)then table.remove(layout.items);return false,'Place against an existing board edge'end
 layout.revision=layout.revision+1;return true
end
function B.remove(layout,x,z)
 local i=B.at(layout,x,z);if not i then return false,'Select an occupied square'end
 local q=table.remove(layout.items,i)
 if not B.connected(layout.items)then table.insert(layout.items,i,q);return false,'Removing that board would disconnect the course'end
 layout.revision=layout.revision+1;return true
end
function B.rotate(layout,x,z)
 local _,q=B.at(layout,x,z);if not q then return false,'Select a placed board to rotate'end
 q.rotation=((q.rotation or 0)+1)%4;layout.revision=layout.revision+1
 return true
end
return B
