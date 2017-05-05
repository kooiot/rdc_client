local skynet = require 'skynet'
local driver = require 'serialdriver'

local function start_work()
	local port = assert(driver.open("/tmp/ttyS10"))
	driver.start(port, function(port, data, err)
		print('RECV', driver.fd(port), data, err)
	end)
	driver.write(port, "AAAAAAA")
end

skynet.start(function()
	skynet.fork(start_work)
	skynet.dispatch("lua", function(...) print(...) end)
	skynet.error("Serial service started!")
end)
