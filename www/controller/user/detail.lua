return {
	get = function(req, res, username)
		if not lwf.ctx.user then
			res:redirect('/user/login')
		end

		local username = username or req:get_arg('username')
		if not username then
			res:redirect('/')
			return
		end

		res:ltp('user/detail.html', {lwf=lwf, app=app, username=username})
	end
}
