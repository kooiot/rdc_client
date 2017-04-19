local proto = require "proto"
local sproto = require "sproto"
local class = require 'middleclass'
local log = require 'utils.log'

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

function spclass:initialize(sock, handler)
	self._sock = sock
	self._session = 0
	self._last = ""
	self._handler = handler
	self._cbs = {}
end

function spclass:send_request(name, args, response_callback)
	self._session = self._session + 1
	local str = request(name, args, self._session)
	send_package(self._sock, str)
	log.debug("Request:", self._session)
	if response_callback then
		self._cbs[self._session] = response_callback
	end
end

function spclass:__handle_request(name, args)
	log.trace("REQUEST", name)
	if args then
		for k,v in pairs(args) do
			log.trace(k,v)
		end
	end
	
	local h = self._handler[string.lower(name)] or function(args)
		log.warning('COMMAND has no handler', name)
	end
	h(args)
end

function spclass:__handle_response(session, args)
	log.trace("RESPONSE", session)
	if args then
		for k,v in pairs(args) do
			log.trace(k,v)
		end
	end

	if self._cbs[session] then
		self._cbs[session](args)
		self._cbs[session] = nil
	end
end

function spclass:__handle_package(t, ...)
	if t == "REQUEST" then
		self:__handle_request(...)
	else
		assert(t == "RESPONSE")
		self:__handle_response(...)
	end
end

function spclass:dispatch_package()
	while true do
		local v
		v, self._last = recv_package(self._sock, self._last)
		if not v then
			break
		end

		self:__handle_package(host:dispatch(v))
	end
end

return spclass
