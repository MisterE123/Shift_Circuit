local V={}
V.list={{id='robot',title='Courier',description='Classic tracked delivery robot.'},{id='robot_scout',title='Scout',description='Slim chassis and wide sensor visor.'},{id='robot_loader',title='Loader',description='Heavy tracks and reinforced shoulders.'},{id='robot_walker',title='Walker',description='Twin feet and a compact round-edged body.'}}
V.list[#V.list+1]={id="robot_rivet",title="Rivet",description="Broad knuckle-walker with oversized industrial fists."}
V.list[#V.list+1]={id="robot_surveyor",title="Surveyor",description="Tripod survey instrument with a wide binocular head."}
V.list[#V.list+1]={id="robot_mantis",title="Mantis",description="Six-legged insect chassis with raised pincer arms."}
V.list[#V.list+1]={id="robot_dynamo",title="Dynamo",description="Single-wheel reactor with a ribbed barrel body."}
V.list[#V.list+1]={id="robot_porter",title="Porter",description="Forklift carrier with forward prongs and a rear counterweight."}
V.list[#V.list+1]={id="robot_beacon",title="Beacon",description="Tall signal tower on four wide stabilizer feet."}
V.list[#V.list+1]={id="robot_crate",title="Crate",description="Walking cargo safe: a huge square shell on tiny feet."}
V.list[#V.list+1]={id="robot_skitter",title="Skitter",description="Wide crab chassis with side claws and four outriggers."}
V.list[#V.list+1]={id="robot_sentry",title="Bastion",description="Stepped armored pyramid with broad twin treads."}
V.list[#V.list+1]={id="robot_spindle",title="Spindle",description="Giant central wheel held in a narrow balancing fork."}
V.list[#V.list+1]={id="robot_beetle",title="Beetle",description="Heavy domed crawler with a broad segmented shell."}
V.list[#V.list+1]={id="robot_relay",title="Relay",description="Dish-headed receiver with a broad open antenna frame."}

function V.valid(id)for _,q in ipairs(V.list)do if q.id==id then return true end end;return false end
function V.get(store,n)local id=store:get_string('robot_style:'..n);return V.valid(id)and id or 'robot'end
function V.model(b)if b.scripted then return 'enemy_'..b.kind end;return b.kind=='hunter'and 'hunter'or (V.valid(b.robot_style)and b.robot_style or 'robot')end
-- Draw cosmetic bodies without repeats; preserve chosen bodies across rebuilds/reboots.
function V.assign_racers(bots,random)
 local used={};for _,b in ipairs(bots)do if V.valid(b.robot_style)then used[b.robot_style]=true end end
 local available={};for _,q in ipairs(V.list)do if not used[q.id]then available[#available+1]=q.id end end
 for _,b in ipairs(bots)do if b.enemy and b.racing and not b.scripted and not V.valid(b.robot_style)then
  if #available==0 then for _,q in ipairs(V.list)do available[#available+1]=q.id end end
  b.robot_style=table.remove(available,(random or math.random)(1,#available))
 end end
end
return V
