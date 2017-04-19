local skynet = require 'skynet'

return {
	get = function(req, res)
		local user = lwf.ctx.user
		if not user then
			return res:redirect('/user/login')
		end

		local myapps = {}
		local applist = {}
		local devlist = {}

	--	local cfg = skynet.call("CFG", "lua", "get", "starter")

		res:ltp('index.html', {app=app, lwf=lwf, devlist=devlist, applist=applist, myapps=myapps})
	end
}
