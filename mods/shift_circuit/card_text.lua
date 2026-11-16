-- Shared player-facing command wording; card IDs remain stable in saved programs.
local C={names={MOVE3='MOVE 3',BACK2='BACK 2',UTURN='U-TURN'},descriptions={
 STEP='Move forward 1 square.',
 DASH='Move forward 2 squares.',
 MOVE3='Move forward 3 squares.',
 BACK='Move backward 1 square; keep facing.',
 BACK2='Move backward 2 squares; keep facing.',
 LEFT='Turn left 90 degrees; stay on your square.',
 RIGHT='Turn right 90 degrees; stay on your square.',
 UTURN='Turn around 180 degrees; stay on your square.',
 WAIT='Stay on your square; keep facing.',
 BLINK='Jump forward 2 squares; skip the middle square.',
 PULSE='Fire 1 beam; spend 1 power.',
}}
function C.title(card)return C.names[card]or card end
function C.tooltip(card)
 local text=C.title(card)..' / '..(C.descriptions[card]or '')
 if card=='BLINK'then return text..'\nSpend 1 power and consume 1 Blink. Landing must be safe and unblocked.' end
 if ({STEP=true,DASH=true,MOVE3=true,BACK=true,BACK2=true})[card]then
  text=text..'\nWalls stop movement. Pits destroy your robot. Ghosts pass through other robots.'
 end
 return text
end
return C
