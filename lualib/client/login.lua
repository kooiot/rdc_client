local crypt = require "crypt"
local class = require "middleclass"

local loginclass = class("LoginClass")

local function writeline(sock, text)
	sock:send(text .. "\n")
end

local function unpack_line(text)
	local from = text:find("\n", 1, true)
	if from then
		return text:sub(1, from-1), text:sub(from+1)
	end
	return nil, text
end

local function encode_token(token)
	return string.format("%s@%s:%s",
						crypt.base64encode(token.user),
						crypt.base64encode(token.server),
						crypt.base64encode(token.passwd))
end

local function unpacker(sock, f)
	local last = ""

	local function unpack_f(sock, f)

		local function try_recv(sock, last)
			local result
			result, last = f(last)
			if result then
				return result, last
			end
			local r = sock:recv()
			if not r then
				return nil, last
			end
			if r == "" then
				error "Server closed"
			end
			return f(last .. r)
		end

		local sock = sock
		return function()
			while true do
				local result
				result, last = try_recv(sock, last)
				if result then
					return result
				end
			end
		end
	end

	return unpack_f(sock, f)
end



local function do_login(sock, server, user, passwd)
	--local fd = assert(socket.connect(ip, port))

	local readline = unpacker(sock, unpack_line)

	local challenge = crypt.base64decode(readline())

	local clientkey = crypt.randomkey()
	writeline(sock, crypt.base64encode(crypt.dhexchange(clientkey)))
	local secret = crypt.dhsecret(crypt.base64decode(readline()), clientkey)

	print("sceret is ", crypt.hexencode(secret))

	local hmac = crypt.hmac64(challenge, secret)
	writeline(sock, crypt.base64encode(hmac))

	local token = {
		server = server,
		user = user,
		passwd = passwd, 
	}

	local etoken = crypt.desencode(secret, encode_token(token))
	local b = crypt.base64encode(etoken)
	writeline(sock, crypt.base64encode(etoken))

	local result = readline()
	local code = tonumber(string.sub(result, 1, 3))
	assert(code == 200, result)

	local subid = crypt.base64decode(string.sub(result, 5))

	print("login ok, subid=", subid)

	return subid, secret
end


function loginclass:initialize(sock)
	self._sock = sock
	self.unpacker = unpacker
end

function loginclass:login(server, user, passwd)
	return pcall(do_login, self._sock, server, user, passwd)
end

return loginclass
