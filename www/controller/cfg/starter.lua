local skynet = require 'skynet'
local snax = require 'snax'
local lfs = require 'lfs'

local get_info = function(req, res, path, err)
	if not lwf.ctx.user then
		res:redirect('/')
	end

	local conf_list = {}
	for filename in lfs.dir('./28181/lualib/conf/') do
		if filename ~= '.' and filename ~= '..' then
			local conf = filename:match('(.+)%.lua$')
			if conf then
				conf_list[#conf_list + 1] = conf
			end
		end
	end

	local cfg = skynet.call("CFG", "lua", "get", "starter") or {}
	local starter = snax.queryservice('starter')
	local run_cfg = starter.req.get_run_cfg()

	local uptime = skynet.now() // 100

	res:ltp('cfg/starter.html', {lwf=lwf, app=app, cfg=cfg, run_cfg=run_cfg, conf_list=conf_list, err=err, uptime=uptime })
end

local function save_conf(args)
	local mode = args['mode'] or 'None'
	local conf = args['conf'] or 'none'

	skynet.call("CFG", "lua", "set", "starter", { mode=mode, conf=conf })
	skynet.call("CFG", "lua", "save")
end

local post_info = function(req, res)
	req:read_body()
	if lwf.ctx.user then
		save_conf(req.post_args) 
		get_info(req, res)
	else
		res:redirect('/user/login')
	end
end

return {
	get = get_info,
	post = post_info,
}
