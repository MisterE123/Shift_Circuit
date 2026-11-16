-- World annotations stay behind interface panels; the owner marker stays above tags.
local W={owner=-250}
function W.sort(tags,eye)
 for _,q in ipairs(tags)do local p=q.pos;q.distance=(p.x-eye.x)^2+(p.y-eye.y)^2+(p.z-eye.z)^2 end
 table.sort(tags,function(a,b)if a.distance~=b.distance then return a.distance<b.distance end;return a.id<b.id end)
 for i,q in ipairs(tags)do q.z=-260-i end
 return tags
end
return W
