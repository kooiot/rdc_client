local skynet = require 'skynet'
local driver = require 'serialdriver'

local function start_work()
	local port = driver.open("/tmp/ttyS10")
	driver.start(port)
	print(driver.write(port, "AAAAAAA"))
end

skynet.PTYPE_SERIAL = 99
skynet.register_protocol {
	name = "serial",
	id = skynet.PTYPE_SERIAL,
	pack = function(...)
		print("PACK: ", ...)
		return skynet.pack(...)
	end,
	unpack = skynet.unpack,
	dispatch = function(...)
		print(...)
	end
}

skynet.start(function()
	skynet.fork(start_work)
	skynet.dispatch("lua", function(...) print(...) end)
end)
