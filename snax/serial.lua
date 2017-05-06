local skynet = require 'skynet'
local driver = require 'serialdriver'

local port = nil

local function start_work(port_name, ...)
	skynet.error("SNAX.SERIAL open", port_name, ...)
	port = assert(driver:new(port_name))
	port:open()
	port:start(function(data, err)
		print('RECV', port:fd(), data, err)
	end)
end

function response.write(data)
	return port:write(data)
end

function init(port, ...)
	skynet.fork(start_work, port, ...)
	skynet.error("Serial service started!")
end

function exit(...)
	port:stop()
end
