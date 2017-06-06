local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local table = table
local string = string

local mode = ...

if mode == "agent" then

package.path = SERVICE_PATH.."/../lwf/?.lua;"..SERVICE_PATH.."/../lwf/?/init.lua;"..package.path

if not skynet.getenv("LWF_HOME") then
	skynet.setenv("LWF_HOME", SERVICE_PATH.."/../lwf")
	skynet.setenv("LWF_APP_NAME", "skynet")
	skynet.setenv("LWF_APP_PATH", SERVICE_PATH.."/../www")
end

local app = require "skynet_app"

local function response(id, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		skynet.error(string.format("fd = %d, %s", id, err))
	end
end

local function dump(url, header, body)
	local tmp = {}
	if header.host then
	table.insert(tmp, string.format("host: %s", header.host))
	end
	local path, query = urllib.parse(url)
	table.insert(tmp, string.format("path: %s", path))
	if query then
	local q = urllib.parse_query(query)
	for k, v in pairs(q) do
	table.insert(tmp, string.format("query: %s= %s", k,v))
	end
	end
	table.insert(tmp, "-----header----")
	for k,v in pairs(header) do
	table.insert(tmp, string.format("%s = %s",k,v))
	end
	table.insert(tmp, "-----body----\n" .. body)
	print(table.concat(tmp,"\n"))
end

skynet.start(function()
	skynet.dispatch("lua", function (_,_,id)
		socket.start(id)

		-- limit request body size to 8192 (you can pass nil to unlimit)
		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
		if code then
			if code ~= 200 then
				response(id, code)
			else
				--dump(url, header, body)
				--print(urllib.parse(url))
				local path, query = urllib.parse(url)
				local env = {
					method = method,
					host = header.host,
					url = url,
					path = path,
					query = query,
					header = header,
					body_data = body,
				}
				app(env, function(...) 
					response(id, ...) 
				end)
			end
		else
			if url == sockethelper.socket_error then
				--skynet.error("socket closed")
			else
				skynet.error(url)
			end
		end
		socket.close(id)
	end)
end)

else
local arg = table.pack(...)
assert(arg.n <= 2)

skynet.start(function()
	local ip = (arg.n == 2 and arg[1] or "0.0.0.0")
	local port = tonumber(arg[arg.n] or 8090)

	local agent = {}
	for i= 1, 4 do
		agent[i] = skynet.newservice(SERVICE_NAME, "agent")
	end
	local balance = 1
	local id = socket.listen(ip, port)
	skynet.error("Web listen on:", port)
	socket.start(id , function(id, addr)
		--skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
		skynet.send(agent[balance], "lua", id)
		balance = balance + 1
		if balance > #agent then
			balance = 1
		end
	end)
end)

end
