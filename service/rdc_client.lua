local skynet = require 'skynet'
local socket = require 'skynet.socket'
local crypt = require 'skynet.crypt'
local log = require 'utils.log'

local TIMEOUT = 100 * 5 -- five seconds
local HB_TIMEOUT = 10 * 3 -- heartbeat timeout
local last_hb = 0

local function load_token()
	return skynet.call("CFG", "lua", "get", "RDC.Cient.token") or {
		server = 'sample',
		user = 'changch84@163.com',
		passwd = 'pa88word'
	}
end

local function load_server()
	return skynet.call("CFG", "lua", "get", "RDC.Client.server") or {
		ip = '127.0.0.1',
		login = 8001,
		gate = 8888,
	}
end

local function make_sock(fd)
	local fd = fd
	return {
		send = function(self, data)
			return socket.write(fd, data)
		end,
		recv = function(self)
			--return socket.read(fd)
			return assert(socket.read(fd))
		end,
	}
end

local handler = {
	heartbeat = function(args)
		last_hb = os.time()
	end,
	create = function(args)
		print(args)
		return {
			result = true,
			channel = 'xxxxx',
		}
	end,
}

local start_work
local function start_gate_conn(login, server, subid, secret, index)
	local token = load_token()

	----- connect to game server
	local function unpack_package(text)
		local size = #text
		if size < 2 then
			return nil, text
		end
		local s = text:byte(1) * 256 + text:byte(2)
		if size < s+2 then
			return nil, text
		end

		return text:sub(3,2+s), text:sub(3+s)
	end


	local function send_package(fd, pack)
		local package = string.pack(">s2", pack)
		socket.write(fd, package)
	end

	local text = "echo"
	local index = index or 1

	local fd = socket.open(server.ip, server.gate)
	if not fd then
		log.warning("Connecting to RDC Gate Server failed, retry in 5 seconds!")
		return skynet.timeout(TIMEOUT, start_work)
	end
	local readpackage = login.unpacker(make_sock(fd), unpack_package)

	local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server),crypt.base64encode(subid) , index)
	local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)

	send_package(fd, handshake .. ":" .. crypt.base64encode(hmac))

	local status = readpackage()
	if tonumber(status:sub(1, 3)) ~= 200 then
		socket.close(fd)
		log.error("Connect to gate failed", status)
		skynet.fork(start_work)
		return
	end

	local gate_client = require 'client.gate':new(make_sock(fd), handler)
	gate_client:send_request("handshake")
	last_hb = os.time()
	local fd_ok = true
	local err = nil
	while fd_ok do
		fd_ok, err = pcall(gate_client.dispatch_package, gate_client)
		if not fd_ok then
			log.trace(err)
		end
		if last_hb - os.time() > HB_TIMEOUT then
			assert(false, "Heartbeat Timeout")
		end
	end

	log.warning("disconnect")
	socket.close(fd)

	return skynet.timeout(TIMEOUT, function() 
		return start_gate_conn(login, server, subid, secret, index + 1) 
	end)
end

start_work = function()
	local token = load_token()
	local server = load_server()
	log.info("Connecting to RDC Server:", server.ip, server.login)
	local fd = socket.open(server.ip, server.login)
	if not fd then
		log.warning("Connecting to RDC Server failed, retry in 5 seconds!")
		return skynet.timeout(TIMEOUT, start_work)
	end

	local login = require("client.login"):new(make_sock(fd))

	local r, subid, secret = login:login(token.server, token.user, token.passwd)
	socket.close(fd)
	if not r then
		log.error("Login failed", subid)
		return skynet.timeout(TIMEOUT * 6, start_work)
	end

	log.debug("login ok, subid=", subid)

	return start_gate_conn(login, server, subid, secret)
end

skynet.start(function()
	skynet.fork(start_work)
end)
