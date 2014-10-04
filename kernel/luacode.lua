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

function tick(t)
  -- say(tostring(t))
end

function write_b(b)
 local addr = 0xb8000 + 2*(lcx + 80*lcy)
 poke(addr, b)
 lcx = lcx + 1
 if lcx > 79  then
  lcx = 0
  lcy = lcy + 1 
  if lcy > 24 then
    lcy = 0
  end
 end
end

function write(s)
  for i=1,#s do
    write_b(string.byte(s, i))
  end
end


function keypress(code)
 if code < 128 then
   if code < #scancodes then
     local key = scancodes[code+1]
     keypressed[key] = true
     local char = key2char(key, keypressed["KB_LSHIFT"])
     if (char) then 
       write(char)
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

