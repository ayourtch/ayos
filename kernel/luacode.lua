local bnot = bit.bnot
local band, bor, bxor, tohex = bit.band, bit.bor, bit.bxor, bit.tohex
local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol

local outw = hw.outw
local outl = hw.outl
local outb = hw.outb
local inb = hw.inb
local inl = hw.inl
local poke = hw.poke
local peek = hw.peek

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

function key2char(key, shiftstate, ctrlstate) 
  local char = nil
  if ctrlstate then
  else
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

function setvideoreg(idx, val)
  outw(0x3d4, idx)
  outw(0x3d5, val)
end

function hwcursor(cx, cy)
  local offs = cx + 80*cy
  setvideoreg(0xe, rshift(offs, 8)) -- loc hi
  setvideoreg(0xf, band(0xff, offs)) -- loc lo
end

function pciwrite_any(addr, val)
  outl(0xCF8, addr)
  outl(0xCFC, val)
end

function pciread_any(addr)
  outl(0xCF8, addr)
  return inl(0xCFC)
end

function pciread_any_b(addr)
  outl(0xCF8, addr)
  return inb(0xCFC)
end


function pciaddr(bus, device, func, offs)
  return bor(0x80000000, lshift(bus, 16), lshift(device, 11), lshift(func, 8), offs)
end

function pciread(bus, device, func, offs)
  return pciread_any(pciaddr(bus, device, func, offs))
end

function pcireadb(bus, device, func, offs)
  return pciread_any_b(pciaddr(bus, device, func, offs))
end

local nics = {}
local num_nics = 0

function check_8139_dev(bus, dev, func)
  local Config1 = 0x52
  local MAC0 = 0

  local id = bit.tohex(pciread(bus, dev, func, 0x0))
  local mac = ""
  if not (id == "813910ec") then
    return nil
  end
  local irq = pcireadb(bus, dev, func, 0x3c)
  local ioaddr = band(pciread(bus, dev, func, 0x10), 0xFFFFFFFE)
  -- get out of low power mode
  outb(ioaddr+Config1, 00)
  for i=0,5 do
    local delim = ":"
    if i == 0 then
      delim = ""
    end
    mac = mac .. delim .. string.format("%02x", (inb(ioaddr+ MAC0 + i)))
  end
  print("Eth irq:" .. tostring(irq) .. " io: " .. tohex(ioaddr) .. " MAC: " ..mac)
  num_nics = num_nics + 1
  nics[num_nics] = {}
  nics[num_nics].irq = irq
  nics[num_nics].ioaddr = ioaddr
  nics[num_nics].mac = mac 
  nics[num_nics].rxbuf = 0x90000 -- FIXME !
  nics[num_nics].cur_rx = 0
  return num_nics
end

local CmdReset = 0x10
local ChipCmd = 0x37
local TX_BUF_SIZE = 1536
local NUM_TX_DESC = 4
local TX_FIFO_THRESH = 256
local RX_BUF_LEN_IDX = 3
local RX_BUF_LEN = lshift(8192, RX_BUF_LEN_IDX)
local RX_FIFO_THRESH = 4
local RX_DMA_BURST = 4 -- 4 is 256 bytes
local TX_DMA_BURST = 4
local CmdRxEnb = 0x08
local CmdTxEnb = 0x04
local CmdReset = 0x10
local RxBufEmpty = 0x01
local IntrMask = 0x3c
local RxConfig = 0x44
local TxConfig = 0x40
local Cfg9346 = 0x50
local Config1 = 0x52
local RxBuf = 0x30
local RxBufPtr = 0x38
local RxMissed = 0x4c

local PCIErr = 0x8000
local PCSTimeout = 0x4000
local RxFIFOOver = 0x40
local RxUnderrun = 0x20
local RxOverflow = 0x10
local TxErr = 0x08
local TxOK = 0x04
local RxErr = 0x02
local RxOK = 0x01



function open_nic(num)
  local ioaddr = nics[num].ioaddr
  local irq = nics[num].irq

  local rxbuf = nics[num].rxbuf
  outb(ioaddr + ChipCmd, 0)
  -- Reset the chip
  outb(ioaddr + ChipCmd, CmdReset)
  for i=1,1000 do
    local val = inb(ioaddr + ChipCmd)
    if 0 == band(CmdReset, val) then
      print("Reset finished at " .. tostring(i) .. " cycles, inb: " .. string.format("%02x", val))
      break
    end
  end
  outb(ioaddr + ChipCmd, bor(CmdRxEnb, CmdTxEnb))
  outl(ioaddr + RxConfig, bor(lshift(RX_FIFO_THRESH, 13),
                              lshift(RX_BUF_LEN_IDX, 11),
                              lshift(RX_DMA_BURST, 8), 0x0f) )
  outl(ioaddr + TxConfig, lshift(TX_DMA_BURST, 8))

  outb(ioaddr + Cfg9346, 0xc0)
  outb(ioaddr + Config1, 0x60) -- full-duplex
  -- outb(ioaddr + Config1, 0x20) -- half-duplex
  outb(ioaddr + Cfg9346, 0x00)

  outl(ioaddr + RxBuf, rxbuf)
  -- start Tx and Rx process
  outl(ioaddr + RxMissed, 0)
  -- set RX mode
  -- outb(ioaddr + RxConfig, 0x0f) -- promisc

  outb(ioaddr + ChipCmd, bor(CmdRxEnb, CmdTxEnb))

  outw(ioaddr + IntrMask, 
       bor(PCIErr, PCSTimeout, RxUnderrun, RxOverflow, 
           RxFIFOOver, TxErr, TxOK, RxErr, RxOK))
end

function has_packet(num)
  local ioaddr = nics[num].ioaddr
  local irq = nics[num].irq
  return not (band(inb(ioaddr + ChipCmd), RxBufEmpty))
end

function get_packet(num)
  local cur_rx = nics[num].cur_rx
  local ioaddr = nics[num].ioaddr
  local irq = nics[num].irq
  if not(band(inb(ioaddr + ChipCmd), 1) == 0) then
    return nil
  end
  local ring_offset = cur_rx % RX_BUF_LEN
  local p = ring_offset + nics[num].rxbuf
  local rx_status = peek(p) + 256*(peek(p+1) + 256 * (peek(p+2) + 256 * peek(p+3)))
  local rx_size = rshift(rx_status, 16)
  local out = ""
  p = p + 4
  -- print("Packet size: " .. tostring(rx_size))
  if(ring_offset + rx_size + 4 > RX_BUF_LEN) then
    -- copy packet in two halves
  else 
    -- copy whole packet
  end
  -- FIXME for now let's just make this way, rather buggy.
  for i=0,rx_size-1 do
    out = out .. string.char(peek(p))
    p = p + 1
  end

  cur_rx = cur_rx + rx_size + 4
  cur_rx = band(cur_rx + 3, 0xfffffffc)
  outw(ioaddr + RxBufPtr, cur_rx - 16)
  nics[num].cur_rx = cur_rx
  return out
end

function pciscan()
  for bus=0,3 do
    for dev=0,31 do
      for func=0,7 do
        local devid = tohex(pciread(bus, dev, func, 0))
        if not (devid == 'ffffffff') then
          say(tohex(bus) .. ":" .. tohex(dev) .. ":" .. tohex(func) .. " : " .. devid)
          local nic = check_8139_dev(bus, dev, func)
          if nic then
            open_nic(nic)
          end
        end
      end
    end
  end
end


function showcursor()
  -- write_bg(lcx, lcy, cursor_x)
  hwcursor(lcx, lcy)
end

function hidecursor()
  -- write_bg(lcx, lcy, bg_color)
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


function writeat(cx, cy, s)
  local scx, scy = lcx, lcy
  lcx, lcy = cx, cy
  for i=1,#s do
    write_b(string.byte(s, i))
  end
  lcx, lcy = scx, scy
  hwcursor(lcx, lcy)
end


local timer_tick = 0

function tick(t)
  timer_tick = timer_tick + 1
  if(0 == timer_tick % 100) then
    if cursor_x == cursor_a then
      cursor_x = cursor_b
      -- showcursor()
    else
      cursor_x = cursor_a
      -- showcursor()
    end
  end
  -- say(tostring(t))
end

function movecursor(dx, dy)
  hidecursor()
  lcx = lcx + dx
  lcy = lcy + dy
  showcursor()
end

function dostring (data)
  local f = assert(loadstring(data))
  return f()
end

function run_current_line()
 local acc = ''
 for x=0,79 do
   local addr = 0xb8000 + 2*(x + 80*lcy)
   local data = peek(addr)
   if not (data == 0) then
     acc = acc .. string.char(data)
   end
 end
 dostring(acc)
end

local buffers = { {}, {}, {}, {} }
local curr_screen = 1

function save_screen(num)
  for off = 0, 80*25*2 do
    buffers[num][off] = peek(0xb8000 + off)
  end
  buffers[num].cx = lcx
  buffers[num].cy = lcy
end

function restore_screen(num)
  for off = 0, 80*25*2 do
    local val = buffers[num][off]
    if val then
      poke(0xb8000 + off, buffers[num][off])
    else
      if off % 2 == 1 then
        poke(0xb8000 + off, 0x7)
      else
        poke(0xb8000 + off, 0)
      end
    end
  end
  lcx, lcy = buffers[num].cx, buffers[num].cy
  if not lcx then 
    lcx = 0
  end
  if not lcy then
    lcy = 1
  end 
  hwcursor(lcx, lcy)
end

function set_screen(num)
  save_screen(curr_screen)
  curr_screen = num
  restore_screen(curr_screen)
end

function shift_text_right()
  for x=79,lcx+1,-1 do
    local addr_d = 0xb8000 + 2*(x + 80*lcy)
    local addr_s = 0xb8000 + 2*(x-1 + 80*lcy)
    poke(addr_d, peek(addr_s))
  end
end

function shift_text_left()
  for x=lcx+1, 79 do
    local addr_s = 0xb8000 + 2*(x + 80*lcy)
    local addr_d = 0xb8000 + 2*(x-1 + 80*lcy)
    poke(addr_d, peek(addr_s))
  end
end

function clear_till_eol()
  for x=lcx+1, 79 do
    local addr_d = 0xb8000 + 2*(x-1 + 80*lcy)
    poke(addr_d, 0)
  end
end

function goto_line_start()
  lcx = 0
  hwcursor(lcx, lcy)
end

function keypress(code)
 if code < 128 then
   if code < #scancodes then
     local key = scancodes[code+1]
     local shiftstate = keypressed["KB_LSHIFT"]
     local ctrlstate = keypressed["KB_LCNTRL"]
     keypressed[key] = true
     local char = key2char(key, shiftstate, false)
     if char and not ctrlstate then 
       shift_text_right()
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
       elseif key == "KB_BACKSPACE" then
         movecursor(-1,0)
         shift_text_left()
       elseif key == "KB_ENTER" then
         run_current_line()
       elseif key == "KB_1" then
         set_screen(1)
       elseif key == "KB_2" then
         set_screen(2)
       elseif key == "KB_3" then
         set_screen(3)
       elseif key == "KB_4" then
         set_screen(4)
       elseif key == "a" then
         goto_line_start()
       elseif key == "k" then
         clear_till_eol() 
       elseif key == "KB_ESC" then
         clrscr()
       elseif key == "KB_TAB" then
         local pkt = get_packet(1)
         if(pkt) then
           print("Got packet: " .. tostring(#pkt) .. " bytes")
           local out = ""
           for i=1,#pkt do
             out = out .. string.format("%02x ", string.byte(pkt, i))
           end
           print(out)
         end
       end
       writeat(40, 0, "                  ")
       writeat(40, 0, tostring(key))
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
pciscan()


