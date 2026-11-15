local V={}
V.list={{id='robot',title='Courier',description='Classic tracked delivery robot.'},{id='robot_scout',title='Scout',description='Slim chassis and wide sensor visor.'},{id='robot_loader',title='Loader',description='Heavy tracks and reinforced shoulders.'},{id='robot_walker',title='Walker',description='Twin feet and a compact round-edged body.'}}
V.list[#V.list+1]={id="robot_rivet",title="Rivet",description="Rugged walker with riveted shoulder plates."}
V.list[#V.list+1]={id="robot_surveyor",title="Surveyor",description="Wide optical bar on four compact wheels."}
V.list[#V.list+1]={id="robot_mantis",title="Mantis",description="Long-legged chassis with folded side arms."}
V.list[#V.list+1]={id="robot_dynamo",title="Dynamo",description="Tracked generator with stacked cooling fins."}
V.list[#V.list+1]={id="robot_porter",title="Porter",description="Small wheeled cab with a tall cargo pack."}
V.list[#V.list+1]={id="robot_beacon",title="Beacon",description="Light tower with a single broad track base."}
V.list[#V.list+1]={id="robot_crate",title="Crate",description="Boxy utility robot with reinforced corners."}
V.list[#V.list+1]={id="robot_skitter",title="Skitter",description="Four splayed feet around a squat sensor body."}
V.list[#V.list+1]={id="robot_sentry",title="Sentry",description="Armored walker with a narrow central eye."}
V.list[#V.list+1]={id="robot_spindle",title="Spindle",description="Tall narrow frame over twin broad wheels."}
V.list[#V.list+1]={id="robot_beetle",title="Beetle",description="Low tracked shell with bright paired eyes."}
V.list[#V.list+1]={id="robot_relay",title="Relay",description="Communications walker with side antenna fins."}

function V.valid(id)for _,q in ipairs(V.list)do if q.id==id then return true end end;return false end
function V.get(store,n)local id=store:get_string('robot_style:'..n);return V.valid(id)and id or 'robot'end
function V.model(b)return b.kind=='hunter'and 'hunter'or (V.valid(b.robot_style)and b.robot_style or 'robot')end
return V
