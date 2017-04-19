local skynet = require 'skynet'
local cjson = require 'cjson'

local function load_json(name)
	local f = io.open(name, 'r')
	if f then
		local s = f:read('*a')
		return cjson.decode(s)
	end
end

return {
	get = function(req, res)
		local user = lwf.ctx.user
		if not user then
			return res:redirect('/user/login')
		end

		local devices = skynet.call("CFG", "lua", "get", "devices") or {}
		for k,v in pairs(devices) do
			if not v.Status or string.len(v.Status) then
				v.Status = v.Status or 'ON'
			end
		end
		res:ltp('devices.html', {app=app, lwf=lwf, devices=devices})

	end
}
