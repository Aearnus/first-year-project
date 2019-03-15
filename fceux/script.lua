function memcallback(address, size, value)
   -- each line of the dump has the following format:      "<framenum>:<addressnum>:<valuenum>"
   -- or, in the case of the frame being unchanged:        "<addressnum>:<valuenum>"
   -- or, in the case of the address also being unchanged: "<valuenum>"
   if address then
	  local frame = emu.framecount()
	  if frame == prev_frame then
		 if address == prev_address then
			diff_file:write(string.format("%x\n", value))
		 else
			diff_file:write(string.format("%x:%x\n", address, value))
		 end
	  else
		 diff_file:write(string.format("%x:%x:%x\n", frame, address, value))
	  end
	  prev_frame = frame
	  prev_address = address
   end
end

function dumpinitial()
   local file = io.open("initial.dump", "w+b")
   for i=0,0xFFFF do
	  file:write(string.char(memory.readbyte(i)))
   end
   file:close()
end

function init()
   print("initializing dump...")
   diff_file = io.open("diff.dump", "w+b")
   is_dumping = true
   emu.frameadvance()
   dumpinitial()
   memory.register(0x0, 0xFFFF, memcallback)
end

emu.registerexit(function ()
   print("deinitializing dump...")
   is_dumping = false
   diff_file:close()
   memory.register(0x0, 0xFFFF, nil)
end)

init()

while true do
   if is_dumping then
	  gui.text(5, 10, "dump in progress")
   end
   
   emu.frameadvance()
end
