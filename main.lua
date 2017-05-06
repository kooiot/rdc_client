local skynet = require "skynet"
local snax = require "snax"
local sprotoloader = require "sprotoloader"

local is_windows = package.config:sub(1,1) == '\\'

skynet.start(function()
	skynet.error("Skynet RDC Client Start")
	skynet.uniqueservice("protoloader")
	if not is_windows and not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",7001)
	skynet.newservice("cfg")
	skynet.newservice("adminweb", "0.0.0.0", 8091)
	--skynet.newservice("rdc_client")
	local serial = snax.newservice("serial", "/tmp/ttyS10")
	local r, err = serial.req.open()
	if r then
		serial.req.write("AABBCC")
	else
		skynet.error("Open Serial Failed With Error", err)
	end
	skynet.exit()
end)
