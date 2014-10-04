local bnot = bit.bnot
local band, bor, bxor = bit.band, bit.bor, bit.bxor
local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol

local lcx = 0
local lcy = 0

local keypressed = {}

local scancodes = {
  "KB_ZERO",
  "KB_ESC",
  "KB_1", "KB_2", "KB_3", "KB_4", "KB_5", "KB_6", "KB_7", "KB_8", "KB_9", "KB_0",
  "KB_MINUS", "KB_EQUAL", "KB_BACKSPACE",
  "KB_TAB", "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "KB_OPEN_BR", "KB_CLOSE_BR",
  "KB_ENTER", "KB_LCNTRL", 
  "a", "s", "d", "f", "g", "h", "j", "k", "l", "KB_SEMICOLON", "KB_QUOTE",
  "KB_TILDE", "KB_LSHIFT", "KB_BACKSLASH", 
  "z", "x", "c", "v", "b", "n", "m", "KB_COMMA", "KB_DOT", "KB_SLASH", "KB_RSHIFT", 
  "KB_KP_MULT", "KB_LALT", " ", "KB_CAPS", 
  "KB_F1", "KB_F2", "KB_F3", "KB_F4", "KB_F5", "KB_F6", "KB_F7", "KB_F8", "KB_F9", "KB_F10", 
  "KB_NUMLOCK", "KB_SCROLLLOCK", "KB_KP_HOME", "KB_KP_UP", "KB_KP_PGUP", 
  "KB_KP_MINUS",
  "KB_KP_LEFT", "KB_KP_5", "KB_KP_RIGHT", "KB_KP_PLUS", 
  "KB_KP_END", "KB_KP_DOWN", "KB_KP_PGDN", "KB_KP_0", 
  "KB_KP_DEL", "KB_KP_SYSRQ", "KB_F11X", "KB_UNLABEL", 
  "KB_F11", "KB_F12" }

local key2lowerchar = { KB_MINUS = "-", KB_EQUAL = "=", 
                        KB_1 = "1", KB_2 = "2", KB_3 = "3", KB_4 = "4", KB_5 = "5", 
                        KB_6 = "6", KB_7 = "7", KB_8 = "8", KB_9 = "9", KB_0 = "0",
                        KB_OPEN_BR = "[", KB_CLOSE_BR = "]",
                        KB_SEMICOLON = ";", KB_QUOTE = "'", KB_TILDE = "`", KB_BACKSLASH = "\\",
                        KB_COMMA = ",", KB_DOT = ".", KB_SLASH = "/"
                      }

local key2upperchar = { KB_MINUS = "_", KB_EQUAL = "+",  
                        KB_1 = "!", KB_2 = "@", KB_3 = "#", KB_4 = "$", KB_5 = "%", 
                        KB_6 = "^", KB_7 = "&", KB_8 = "*", KB_9 = "(", KB_0 = ")",
                        KB_OPEN_BR = "{", KB_CLOSE_BR = "}",
                        KB_SEMICOLON = ":", KB_QUOTE = '"', KB_TILDE = "~", KB_BACKSLASH = "|",
                        KB_COMMA = "<", KB_DOT = ">", KB_SLASH = "?"
                      }

function key2char(key, shiftstate) 
  local char = nil
  if(#key == 1) then
    if shiftstate then
      char = string.upper(key)
    else
      char = key
    end
  else
    if shiftstate then
      char = key2upperchar[key]
    else
      char = key2lowerchar[key]
    end
  end
  return char
end

local bg_color = 0x07
local cursor_a = 0x10
local cursor_b = 0x20
local cursor_x = cursor_a

function write_bg(cx, cy, bg)
 local addr = 0xb8000 + 1+ 2*(cx + 80*cy)
 poke(addr, bg)
end

function clrscr()
  for cx = 0,79 do
    for cy = 0,24 do
      local addr = 0xb8000 + 2*(cx + 80*cy)
      poke(addr, 0)
      poke(1+addr, bg_color)
    end
  end
end 

function showcursor()
  write_bg(lcx, lcy, cursor_x)
end

function hidecursor()
  write_bg(lcx, lcy, bg_color)
end

function write_b(b)
 local addr = 0xb8000 + 2*(lcx + 80*lcy)
 hidecursor()
 poke(addr, b)
 poke(addr+1, bg_color)
 lcx = lcx + 1
 if lcx > 79  then
  lcx = 0
  lcy = lcy + 1 
  if lcy > 24 then
    lcy = 0
  end
 end
  showcursor()
end

function write(s)
  for i=1,#s do
    write_b(string.byte(s, i))
  end
end




local timer_tick = 0

function tick(t)
  timer_tick = timer_tick + 1
  if(0 == timer_tick % 100) then
    if cursor_x == cursor_a then
      cursor_x = cursor_b
      showcursor()
    else
      cursor_x = cursor_a
      showcursor()
    end
  end
  -- say(tostring(t))
end

function setvideoreg(idx, val)
  outw(0x3d4, idx)
  outw(0x3d5, val)
end

function movecursor(dx, dy)
  hidecursor()
  lcx = lcx + dx
  lcy = lcy + dy
  local offs = lcx + 80*lcy
  setvideoreg(0xe, rshift(offs, 8)) -- loc hi
  setvideoreg(0xf, band(0xff, offs)) -- loc lo
  showcursor()
end

function keypress(code)
 if code < 128 then
   if code < #scancodes then
     local key = scancodes[code+1]
     keypressed[key] = true
     local char = key2char(key, keypressed["KB_LSHIFT"])
     if (char) then 
       write(char)
     else
       if key == "KB_KP_LEFT" then
         movecursor(-1,0)
       elseif key == "KB_KP_RIGHT" then
         movecursor(1,0)
       elseif key == "KB_KP_UP" then
         movecursor(0, -1)
       elseif key == "KB_KP_DOWN" then
         movecursor(0, 1)
       end
     end
     -- say(tostring(code) .. " : " .. tostring(scancodes[code+1]))
   end
 else
   code = code - 128
   if code < #scancodes then
     local key = scancodes[code+1]
     keypressed[key] = false
     -- say(tostring(code) .. " : " .. tostring(scancodes[code+1]) .. " released")
   end
 end
end

clrscr()
setvideoreg(0xe, 0) -- loc hi
setvideoreg(0xf, 0) -- loc lo
