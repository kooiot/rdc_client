local skynet = require 'skynet'

return {
	get = function(req, res)
		local user = lwf.ctx.user
		if not user then
			return res:redirect('/user/login')
		end

		local cfg = skynet.call("CFG", "lua", "get", "starter")

		local uptime = skynet.now() // 100
		local upday = uptime // (24 * 60 * 60)
		local upyear = upday // 365
		local uptime_str = string.format("%d Year %d Day %s",  upyear, upday, os.date("!%H:%M:%S", uptime))

		local fmt = '%Y-%m-%d %H:%M:%S'
		local env = {
			KOOWEB = {
				--VERSION = lwf.version or "UNKNOWN",
			},
			SKYNET = {
				--VERSION = "UNKNOWN",
				LUA_VERSION = _VERSION,
				TIME = os.date(fmt, math.tointeger(skynet.time())),
				START_TIME = os.date(fmt, skynet.starttime()),
				UPTIME = uptime_str,
			},
		}

		res:ltp('about.html', {app=app, lwf=lwf, cfg=cfg, env=env})
	end
}
