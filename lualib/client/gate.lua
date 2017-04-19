local proto = require "proto"
local sproto = require "sproto"
local class = require 'middleclass'

local host = sproto.new(proto.s2c):host "package"
local request = host:attach(sproto.new(proto.c2s))

local spclass = class("SprotoClient")

local function send_package(sock, pack)
	local package = string.pack(">s2", pack)
	sock:send(package)
end

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

local function recv_package(sock, last)
	local result
	result, last = unpack_package(last)
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
	return unpack_package(last .. r)
end

function spclass:initialize(sock)
	self._sock = sock
	self._session = 0
	self._last = ""
end

function spclass:send_request(name, args)
	self._session = self._session + 1
	local str = request(name, args, self._session)
	send_package(self._sock, str)
	print("Request:", self._session)
end

local function print_request(name, args)
	print("REQUEST", name)
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
end

local function print_response(session, args)
	print("RESPONSE", session)
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
end

local function print_package(t, ...)
	if t == "REQUEST" then
		print_request(...)
	else
		assert(t == "RESPONSE")
		print_response(...)
	end
end

function spclass:dispatch_package()
	while true do
		local v
		v, self._last = recv_package(self._sock, self._last)
		if not v then
			break
		end

		print_package(host:dispatch(v))
	end
end

return spclass
