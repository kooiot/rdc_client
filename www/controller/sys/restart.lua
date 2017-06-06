local skynet = require 'skynet.manager'
local snax = require 'skynet.snax'

return {
	get = function(req, res)
		local user = lwf.ctx.user
		if not user then
			return res:redirect('/user/login')
		end

		res:ltp('sys/restart.html', {app=app, lwf=lwf})
	end,
	post = function(req, res)
		local passwd = req.post_args['password']
		if passwd == "admin" then
			local starter = snax.queryservice("starter")
			starter.post.stop()
			skynet.timeout(300, function()
				skynet.abort()
			end)
			res:write('DONE')
		else
			res:write('Need correct password')
		end
	end,
}


