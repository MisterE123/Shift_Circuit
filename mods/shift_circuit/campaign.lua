local C={}
C.missions={
  {title='01 / Wake-up shift',brief='Bring the line online. One maintenance drone is still hostile.',enemies={{8,6,2}}},
  {title='02 / Cross traffic',brief='Two patrol machines guard the route. Collect the phase module to jump gaps.',enemies={{7,5,2},{9,8,3}}},
  {title='03 / Lockdown',brief='The foreman and two guards control the factory. Reach all three stations.',enemies={{6,9,2},{9,5,3},{5,7,1}}},
}
function C.setup(R,level,mode,board)
  local s=R.arena(); s.level=level; s.mode=mode; s.pickups={}
  s.pushers={{x=3,z=6,dir=1,parity=1},{x=10,z=7,dir=3,parity=0}}
  s.lasers={{x=0,z=5,dir=1,power=1},{x=12,z=8,dir=3,power=2},{x=6,z=12,dir=2,power=3}}
  s.walls[R.edge(8,8,1)]=true
  for _,key in ipairs({'3,4','4,4','7,4','8,4','8,5','8,6'}) do s.board[key].speed=2 end
  s.board['5,8']={kind='rotator',turn=1};s.board['10,4']={kind='rotator',turn=3}
  for _,p in ipairs({{3,3,'shield'},{5,3,'cell'},{2,4,'blink'},{9,4,'range'},{10,8,'shield'},{3,7,'cell'},{4,3,'cache'},{7,7,'jammer'},{10,10,'cache'}}) do s.pickups[R.key(p[1],p[2])]=p[3] end
  if mode=='campaign' and level>=2 then
    s.board['5,5']={kind='pit'}; s.overhead['5,8']={kind='crusher'};s.overhead['6,7']={kind='crusher'}
    if level==3 then s.overhead['10,6']={kind='crusher'}; s.board['4,4']={kind='pit'} end
  end
  s.pickups['4,2']='repair';s.board['2,5']={kind='repair'}
  s.spawners={['5,2']={item='double_laser',rounds={1,4,7}},['3,5']={item='mechanical_arm',first=2,every=4},['9,7']={item='turret_gearbox',first=2,every=4},['10,5']={item='tractor_beam',first=3,every=4}}
  s.board_id=board or 1
  if s.board_id==2 then
    s.walls[R.edge(5,4,1)]=true;s.walls[R.edge(8,6,0)]=true
    s.board['4,5']={kind='belt',dir=0,speed=2};s.board['4,6']={kind='belt',entry=0,dir=1,speed=2};s.board['5,6']={kind='belt',dir=1}
    s.board['7,7']={kind='rotator',turn=3};s.pickups['7,7']=nil
  elseif s.board_id==3 then
    s.board['5,6']={kind='floor'};s.board['6,6']={kind='rotator',turn=1}
    s.lasers={{x=0,z=6,dir=1,power=2},{x=12,z=7,dir=3,power=1}}
    s.overhead['6,7']=nil;s.overhead['7,8']={kind='crusher'}
    s.pickups['5,6']='shield';s.pickups['6,3']='cell'
  end
  if mode=='tutorial' then
    s.walls={};s.overhead={};s.pushers={};s.lasers={};s.spawners={};s.pickups={['3,4']='shield'}
    for k in pairs(s.board)do s.board[k]={kind='floor'}end
    for _,q in ipairs({{2,4,1},{4,4,2},{4,6,3}})do s.board[R.key(q[1],q[2])]={kind='station',number=q[3]}end
    s.objective='1: Drive forward to the first flag.  2: Turn right and collect the shield.  3: Turn left to finish.'
  end
  return s
end
-- Draw from the same round deck so IDs remain globally unique.
function C.reset_hand(s,b,random)
 random=random or math.random
 if b.ready or b.down or b.finished then return false,'Reset unavailable now'end
 if ((b.parts or {}).reset_button or 0)<1 then return false,'Collect a Reset Button first'end
 if s.puzzle and ((s.puzzle.hands or {})[tostring(s.round)]or (s.puzzle.hands or {})[s.round])then return false,'This puzzle uses a fixed hand'end
 local slots={};local candidates={}
 for i,c in ipairs(b.hand or {})do if c~='BLINK'then slots[#slots+1]=i end end
 for i,c in ipairs(s.draw_pile or {})do if c.command~='BLINK'then candidates[#candidates+1]=i end end
 if #slots==0 or #candidates<#slots then return false,'No replacement hand available'end
 for i=#candidates,2,-1 do local j=random(i);candidates[i],candidates[j]=candidates[j],candidates[i]end
 local removed={};local returned={}
 for n,index in ipairs(slots)do
  local at=candidates[n];local card=s.draw_pile[at];removed[at]=true
  returned[#returned+1]={command=b.hand[index],id=b.hand_ids[index]}
  b.hand[index]=card.command;b.hand_ids[index]=card.id
 end
 local deck={};for i,c in ipairs(s.draw_pile)do if not removed[i]then deck[#deck+1]=c end end
 for _,c in ipairs(returned)do deck[#deck+1]=c end;s.draw_pile=deck
 b.parts.reset_button=b.parts.reset_button-1;b.selected={};b.program={};b.program_ids={};b.keep={};b.keep_ids={};b.retained_count=0
 return true,'Hand reset / One Reset Button consumed'
end
function C.deal(b,random) C.deal_round({bots={b}},random)end
-- Build the whole round's weighted deck, number it, shuffle it, then deal.
-- Disk reservations consume cards from this same deck; they do not add draws.
function C.deal_round(s,random)
 random=random or math.random
 local recipients={};local deck={}
 for _,b in ipairs(s.bots)do if not b.finished and not b.pattern then
  b.blink=b.blink or ((b.parts or {}).blink or 0)>0;b.blink_left=b.blink and 1 or 0
  b.draw_bonus=math.min(3,(b.parts or {}).cache and 2*b.parts.cache or b.draw_bonus or 0)
  b.last_penalty=b.disruption or 0;b.disruption=0
  b.hull_penalty=math.max(0,(b.max_hp or 5)-(b.hp or b.max_hp or 5))
  b.allowance=math.max(5,math.min(12,9+(b.draw_bonus or 0)-b.hull_penalty-b.last_penalty))
  local retained={};local seen={};for _,index in ipairs(b.keep or {})do local card=(b.hand or {})[index]
   if card and card~='BLINK'and not seen[index]and #retained<math.min(b.allowance,(b.parts or {}).hard_disk or 0)then retained[#retained+1]=card;seen[index]=true end
  end
  b.start_direction_available=s.round==1
  if s.round~=1 then b.start_direction=nil end
  b.hand=retained;b.retained_count=#retained;b.keep={};b.selected={};b.program={};b.program_ids={};b.hand_ids={};b.ready=false;b.remote_from=nil;b.remote_slots=nil
  if b.enabled then b.enabled.gyro_stabilizer=false end
  recipients[#recipients+1]=b
  for _,entry in ipairs({{'STEP',7},{'DASH',4},{'MOVE3',2},{'BACK',3},{'BACK2',1},{'LEFT',4},{'RIGHT',4},{'UTURN',2},{'WAIT',3}})do
   for _=1,entry[2]do deck[#deck+1]={command=entry[1],id=#deck+1}end
  end
  if b.blink then deck[#deck+1]={command='BLINK',id=#deck+1,owner=b.id or b}end
 end end
 -- Shuffle ID assignment too, so identical moves can have any relative priority.
 for i=#deck,2,-1 do local j=random(i);deck[i].id,deck[j].id=deck[j].id,deck[i].id end
 for _,b in ipairs(recipients)do
  local keep={};for i=1,b.retained_count do keep[#keep+1]=b.hand[i]end
  b.hand={};b.hand_ids={}
  if b.blink then for i,card in ipairs(deck)do if card.command=='BLINK'and card.owner==(b.id or b)then b.hand[1]='BLINK';b.hand_ids[1]=card.id;table.remove(deck,i);break end end end
  for _,command in ipairs(keep)do for i,card in ipairs(deck)do if card.command==command and #b.hand<b.allowance then
   b.hand[#b.hand+1]=command;b.hand_ids[#b.hand_ids+1]=card.id;table.remove(deck,i);break
  end end end
 end
 for i=#deck,2,-1 do local j=random(i);deck[i],deck[j]=deck[j],deck[i]end
 -- Round-robin distribution; phase cards are only usable with a Blink module.
 for draw=1,12 do for _,b in ipairs(recipients)do if #b.hand<b.allowance then
  for i,card in ipairs(deck)do if card.command~='BLINK'then
   b.hand[#b.hand+1]=card.command;b.hand_ids[#b.hand_ids+1]=card.id;table.remove(deck,i);break
  end end
 end end end
 if s.puzzle then local hand=(s.puzzle.hands or {})[tostring(s.round)]or (s.puzzle.hands or {})[s.round]
  if hand then local id=0;for _,b in ipairs(s.bots)do for _,n in ipairs(b.hand_ids or {})do id=math.max(id,n)end end;for _,card in ipairs(deck)do id=math.max(id,card.id)end
   for _,b in ipairs(recipients)do if not b.enemy then b.hand={};b.hand_ids={};b.retained_count=0;b.allowance=#hand;for i,c in ipairs(hand)do id=id+1;b.hand[i]=c;b.hand_ids[i]=id end end end
  end
 end
 s.draw_pile=deck
end
function C.enemies(s,R)
 if s.mode=='tutorial'then return end
 -- Safe spawn candidates are derived from this board, not fixed coordinates.
 local safe={};local start=s.start or {x=2,z=2};local taken={}
 for _,b in ipairs(s.bots)do taken[b.x..','..b.z]=true end
 for z=2,s.size-1 do for x=2,s.size-1 do local key=x..','..z;local t=s.board[key]
  if t and (t.kind=='floor'or t.kind=='repair')and not (s.overhead or {})[key]and not taken[key]and math.abs(x-start.x)+math.abs(z-start.z)>=3 then
   local exits=0;for i,d in ipairs({{0,1},{1,0},{0,-1},{-1,0}})do local next=s.board[(x+d[1])..','..(z+d[2])];if next and next.kind~='pit'and next.kind~='wall'and not (R and R.blocked(s,x,z,i-1))then exits=exits+1 end end
   local exposed=false;for _,q in ipairs(s.lasers or {})do local d=({{0,1},{1,0},{0,-1},{-1,0}})[q.dir+1];local forward=(x-q.x)*d[1]+(z-q.z)*d[2];local side=(x-q.x)*d[2]-(z-q.z)*d[1]
    if side==0 and forward>=0 and forward<=(R and R.wall_ray(s,q.x,q.z,q.dir,R.fixed_laser_range(s,q))or s.size)then exposed=true end
   end
   if exits>=3 and not exposed then safe[#safe+1]={x,z}end
  end
 end end
 local function spawn_site(fallback)
  local best,score
  for i,p in ipairs(safe)do local distance=math.abs(p[1]-start.x)+math.abs(p[2]-start.z)
   for key in pairs(taken)do local x,z=key:match('(%d+),(%d+)');distance=math.min(distance,math.abs(p[1]-tonumber(x))+math.abs(p[2]-tonumber(z)))end
   if not score or distance>score then best=i;score=distance end
  end
  if best then local p=table.remove(safe,best);taken[p[1]..','..p[2]]=true;p[3]=0;return p end
  -- A tiny custom board may have fewer safe enemy seats than requested.
  return nil
 end
 local positions={{8,6,2},{9,8,3},{6,9,2},{5,7,1},{9,6,3},{7,9,0},{10,3,2},{2,10,0}}
 local hunters=s.enemy_count
 if hunters==nil then hunters=s.mode=='campaign' and #C.missions[s.level].enemies or 0 end
 local racers=s.racer_count
 if racers==nil then racers=s.mode=='race' and (s.ai_count or 0) or (s.ai_mode=='racer' and hunters or 0);if s.ai_mode=='racer' then hunters=0 end end
 local available=math.max(0,8-#s.bots)
 hunters=math.min(available,math.max(0,math.floor(hunters)));racers=math.min(available-hunters,math.max(0,math.floor(racers)))
 s.enemy_count=hunters;s.racer_count=racers
 for i=1,hunters+racers do
  local racer=i>hunters;local p=racer and {start.x,start.z,start.dir or 0}or spawn_site(positions[i]);local kind=racer and 'racer' or (s.campaign_puzzle and i==1 and 'patrol' or 'hunter')
  if p then
  local pattern=(i%2==1) and {'STEP','RIGHT','WAIT','RIGHT','STEP'} or {'LEFT','WAIT','RIGHT','WAIT','WAIT'}
  s.bots[#s.bots+1]={id=(racer and 'RACER-' or (kind=='patrol' and 'PATROL-' or 'HUNTER-'))..i,enemy=true,kind=kind,racing=racer,
   x=p[1],z=p[2],dir=p[3],hp=5,max_hp=5,energy=4,range=4,shield=0,next=racer and 1 or 99,damage=0,program={},
   difficulty=racer and (s.racer_difficulty or s.difficulty or 2) or (s.difficulty or 2),hunt_radius=6,pattern=kind=='patrol' and pattern or nil,home={x=p[1],z=p[2],dir=p[3]}}
  end
 end
end
-- Predict public motion from the previous round; never inspect the user's queued cards.
local function copy(t) if type(t)~='table' then return t end local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r end
local function find(s,id)for _,b in ipairs(s.bots)do if b.id==id then return b end end end
local function distance(R,s,b,tx,tz)
 local q={{b.x,b.z,0}};local seen={[R.key(b.x,b.z)]=true};local n=1
 while q[n]do local p=q[n];n=n+1;if p[1]==tx and p[2]==tz then return p[3]end
  for dir=0,3 do local d=R.dirs[dir+1];local x,z=p[1]+d.x,p[2]+d.z;local k=R.key(x,z);local t=R.tile(s,x,z)
   if not seen[k] and t.kind~='pit' and t.kind~='wall' and not R.blocked(s,p[1],p[2],dir)then seen[k]=true;q[#q+1]={x,z,p[3]+1}end
  end
 end;return 50
end
function C.plan(R,s,b,yield_step)
 if b.pattern then local p={};for i,c in ipairs(b.pattern)do p[i]=c end;return p end
 local difficulty=b.difficulty or s.difficulty or 2;local width=({1,3,6})[difficulty] or 3
 local targets={};local patrol
 if not b.racing then
  local post=b.home or b
  for _,p in ipairs(s.bots)do if (not p.enemy or p.racing)and not p.down and not p.finished and math.abs(p.x-post.x)+math.abs(p.z-post.z)<=(b.hunt_radius or 6)then targets[p.id]=true end end
  if not next(targets)then
   local candidates={};local home=b.home or b
   for z=1,s.size do for x=1,s.size do local t=R.tile(s,x,z);local d=math.abs(x-home.x)+math.abs(z-home.z)
    if d>=1 and d<=3 and (t.kind=='floor'or t.kind=='repair')and not (s.overhead or {})[R.key(x,z)]and distance(R,s,b,x,z)<50 then candidates[#candidates+1]={x=x,z=z}end
   end end
   patrol=#candidates>0 and candidates[((s.round or 1)-1)%#candidates+1]or home
  end
 end
 if not b.hand then C.deal(b)end
 local base=copy(s);for _,p in ipairs(base.bots)do if not p.enemy then p.program=copy(difficulty==1 and {'WAIT','WAIT','WAIT','WAIT','WAIT'} or (p.last_program or {'STEP','WAIT','STEP','WAIT','WAIT'}))end end
 local indices={};for i in ipairs(b.hand)do indices[#indices+1]=i end
 table.sort(indices,function(a,c)return ((b.hand_ids or {})[a]or 0)>((b.hand_ids or {})[c]or 0)end)
 local beam={{s=base,program={},used={},score=0}};local initial={}
 if s.round==1 and not b.start_direction_applied then
  beam={}
  for _,choice in ipairs({'FORWARD','LEFT','RIGHT','UTURN'})do
   local oriented=copy(base);local me=find(oriented,b.id);me.start_direction=choice;R.start_facing(oriented,me)
   beam[#beam+1]={s=oriented,program={start_direction=choice},used={},score=0}
  end
 end
 for _,p in ipairs(s.bots)do initial[p.id]={hp=p.hp or 5,shield=p.shield or 0,next=p.next or 1}end
 for pulse=1,5 do
  local candidates={}
  for _,branch in ipairs(beam)do local kinds={}
   for _,index in ipairs(indices)do local card=b.hand[index];if not branch.used[index] and not kinds[card] then kinds[card]=true
    if yield_step then yield_step()end
    local sim=copy(branch.s);sim.shots={};sim.collections={};local me=find(sim,b.id)
    me.program_ids=me.program_ids or {};me.program_ids[pulse]=(b.hand_ids or {})[index]
    sim.register=pulse;for _,p in ipairs(R.program_order(sim,pulse))do R.command(sim,p,p.id==b.id and card or (not p.enemy and p.program[pulse] or 'WAIT'))end
    R.ghosts(sim);R.collect_phase(sim);R.arms(sim);R.belts(sim);R.pushers(sim,pulse);R.plates(sim);R.collect_phase(sim);R.rotators(sim);R.robot_weapons(sim,pulse);R.collect_phase(sim);R.lasers(sim);R.hazards(sim,pulse);R.register_repairs(sim);R.ghosts(sim,true);if pulse==5 then R.repairs(sim)end
    local score=(me.hp or 0)*5+(me.shield or 0)*2-(me.down and 150 or 0)
    if b.racing then
      score=score+((me.next or 1)-1)*120
      for _,other in ipairs(sim.bots)do if other.id~=b.id and (not other.enemy or other.racing) then local urgency=(other.next or 1)>=me.next and 2 or 1;score=score+(initial[other.id].hp-(other.hp or 0))*4*urgency+(other.down and 12*urgency or 0) end end
      for k,t in pairs(sim.board)do if t.kind=='station' and t.number==me.next then local x,z=k:match('(%d+),(%d+)');score=score-distance(R,sim,me,tonumber(x),tonumber(z))*3 end end
      if sim.winner==b.id then score=score+1000 end
    else
      local nearest=50
      for _,p in ipairs(sim.bots)do if targets[p.id]then
        score=score+(initial[p.id].hp-(p.hp or 0))*30+(initial[p.id].shield-(p.shield or 0))*10+(p.down and 60 or 0)
        if not p.down then nearest=math.min(nearest,distance(R,sim,me,p.x,p.z));local _,target=R.trace(sim,me.x,me.z,me.dir,me.range or 4,me);if target==p then score=score+12 end end
      end end;if patrol then score=score-distance(R,sim,me,patrol.x,patrol.z)*5 else score=score-nearest end
      local home=b.home or b;score=score-math.max(0,math.abs(me.x-home.x)+math.abs(me.z-home.z)-(b.hunt_radius or 6))*100
    end
    local program=copy(branch.program);program[#program+1]=card;local used=copy(branch.used);used[index]=true
    candidates[#candidates+1]={s=sim,program=program,used=used,score=score,death=branch.death or (me.down and pulse or nil)}
   end end
  end
  table.sort(candidates,function(a,b)
   if not a.death and b.death then return true elseif a.death and not b.death then return false end
   if a.death and b.death and a.death~=b.death then return a.death>b.death end
   return a.score>b.score
  end);beam={};for i=1,math.min(width,#candidates)do beam[i]=candidates[i]end
 end
 return beam[1] and beam[1].program or {'WAIT','WAIT','WAIT','WAIT','WAIT'}
end
-- Fill only empty registers, drawing without replacement from the dealt hand.
function C.autofill(b)
 if b.ready then return end
 local used={};for _,i in ipairs(b.selected) do used[i]=true end
 local remaining={};for i in ipairs(b.hand) do if not used[i] then remaining[#remaining+1]=i end end
 while #b.program<5 and #remaining>0 do
   local at=math.random(#remaining);local i=table.remove(remaining,at)
   b.selected[#b.selected+1]=i;b.program[#b.program+1]=b.hand[i];b.program_ids=b.program_ids or {};b.program_ids[#b.program]=(b.hand_ids or {})[i]
 end
 if b.start_direction_available then b.start_direction=b.start_direction or 'FORWARD'end
 b.ready=#b.program==5
end
return C
