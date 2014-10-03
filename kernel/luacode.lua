function vidmem_ch(x, y, ch)
  vmem = 753664
  poke(vmem+ 2*(x+80*y), ch)
end

cx = 0
cy = 0

function keypress(code)
 vidmem_ch(cx, cy, code)
 cx = cx + 1
end

