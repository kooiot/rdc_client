local skynet = require 'skynet'
local snax = require 'skynet.snax'
local cjson = require 'cjson'

local CMD =  {}
function CMD.add(server)
	if string.len(server.host) < 8 then
		return nil, "Incorrect IP"
	end
	if tonumber(server.port) == nil then
		return nil, "Incorrect Port"
	end
	if string.len(server.srvid) < 18 then
		return nil, "ID too short"
	end
	if string.len(server.srvid) > 20 then
		return nil, "ID too long"
	end
	if string.len(server.srvrealm) ~= 10 then
		return nil, "Realm length error"
	end
	if string.len(server.passwd) == 0 then
		return nil, "Password must be set!"
	end

	local s = snax.queryservice("28181_server")
	if s then
		return s.req.add_server({
			ssid = server.type..':0:'..server.host..':'..server.port,
			srvid = server.srvid,
			srvrealm = server.srvrealm,
			passwd = server.passwd,
		})
	end

	return true
end

function CMD.modify(server)
	return CMD.add(server)
end

function CMD.remove(server)
	local s = snax.queryservice("28181_server")
	if s then
		return s.req.delete_server(server)
	end

	return false, "Canont find 28181_server service"
end

return {
	get = function(req, res)
		local user = lwf.ctx.user
		if not user then
			return res:redirect('/user/login')
		end

		local conns = {}
		local s = snax.queryservice("28181_server")
		if s then
			conns = s.req.connections()
		end

		local servers = s.req.list_servers() or {}
		for _,v in ipairs(servers) do
			local host, port = v.ssid:match("([^:]+):(%d+)$")
			v.type = v.ssid:sub(1,3)
			v.host = host
			v.port = port
			v.status = conns[v.srvid].status or 'N/A'
		end
		res:ltp('cfg/servers.html', {app=app, lwf=lwf, servers=servers})
	end,
	post = function(req, res)
		if lwf.ctx.user then
			local action = req.post_args['action']
			local server = {}
			for k,v in pairs(req.post_args) do
				if k:sub(1, 7) == 'server_' then
					server[k:sub(8)] = v
				end
			end
			local r, err = CMD[action](server)
			if not r then
				res:write(err)
				return lwf.set_status(403)
			end
		end
	end
}
