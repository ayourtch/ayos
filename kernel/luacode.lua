local lcx = 0
local lcy = 0


function tick(t)
  -- say(tostring(t))
end

function keypress(code)
 local addr = 753664+ (1024/256 - 2)*lcx
 poke(addr, code)
 lcx = lcx + 1
 if lcx > 10  then
  lcx = 0
 end
end

