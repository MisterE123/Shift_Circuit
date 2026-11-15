-- Small, short-lived effects communicate distinct events without hiding the board.
return function(core)
 local P={}
 local styles={fall={8,'dust',.55,.35,.3,-4,2},armor={20,'metal',.7,1.5,2,-6,4},control={12,'phase',.6,.4,1.2,.3,10},pull={10,'shield',.45,.25,.7,-.5,9},push={12,'spark',.35,.8,1.2,0,9},repair={8,'repair',.6,.3,1.5,1,8},damage={10,'spark',.35,1.4,1.8,-7,8},shield={14,'shield',.4,1.3,1,0,10},blink={16,'phase',.45,.8,1.6,1,9},
  reboot={18,'phase',.7,.7,2,1,8},pickup={7,'mote',.55,.3,1.2,1,6},checkpoint={12,'mote',.8,.8,2,1,8},
  destroy={24,'spark',.55,2,2.5,-6,9},crush={18,'dust',.6,1.8,.6,-2,2},impact={5,'spark',.22,.6,.8,-3,6}}
 function P.emit(kind,p)
  local s=styles[kind];if not s or not core.add_particlespawner then return end
  core.add_particlespawner({amount=s[1],time=.08,minpos={x=p.x-.2,y=p.y+.25,z=p.z-.2},maxpos={x=p.x+.2,y=p.y+.6,z=p.z+.2},
   minvel={x=-s[4],y=.2,z=-s[4]},maxvel={x=s[4],y=s[5],z=s[4]},minacc={x=0,y=s[6],z=0},maxacc={x=0,y=s[6],z=0},
   minexptime=s[3]*.6,maxexptime=s[3],minsize=.5,maxsize=kind=='crush' and 2.5 or 1.6,texture='sc_fx_'..s[2]..'.png',glow=s[7],collisiondetection=false})
 end
 return P
end

