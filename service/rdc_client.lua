local skynet = require 'skynet'
local socket = require 'socket'
local crypt = require 'crypt'


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
		port = 8001
	}
end

local function test()
	local token = load_token()
	local server = load_server()
	local fd = socket.open(server.ip, server.port)

	local function make_sock(fd)
		local fd = fd
		return {
			send = function(self, data)
				return socket.write(fd, data)
			end,
			recv = function(self)
				return socket.read(fd)
			end,
		}
	end

	local login = require("client.login"):new(make_sock(fd))

	local r, subid, secret = assert(login:login(token.server, token.user, token.passwd))
	socket.close(fd)

	print("login ok, subid=", subid)

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
	local index = 1

	print("connect")
	local fd = assert(socket.open("127.0.0.1", 8888))
	local readpackage = login.unpacker(make_sock(fd), unpack_package)

	local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server),crypt.base64encode(subid) , index)
	local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)

	send_package(fd, handshake .. ":" .. crypt.base64encode(hmac))

	print(readpackage())

	print("disconnect")
	socket.close(fd)

	index = index + 1

	print("connect again")
	fd = assert(socket.open("127.0.0.1", 8888))
	readpackage = login.unpacker(make_sock(fd), unpack_package)

	local gate_client = require 'client.gate':new(make_sock(fd))

	local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server),crypt.base64encode(subid) , index)
	local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)

	send_package(fd, handshake .. ":" .. crypt.base64encode(hmac))

	print(readpackage())

	gate_client:send_request("handshake")
	while true do
		gate_client:dispatch_package()
	end

	print("disconnect")
	socket.close(fd)
end

skynet.start(function()
	skynet.fork(test)
end)
