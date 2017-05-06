local skynet = require 'skynet'

local chnmap = {}
local cfgmap = {}

local create_handler = {
	serial = function(name, cfg)
	end
	tcp = function(name, cfg)
	end
	udp = function(name, cfg)
	end
}

function response.create(name, cfg)
	if chnmap[name] then
		return nil, "Channel name "..name.." is used already"
	end
	local handler = create_handler[cfg['type']]
	if not handler then
		return nil, "Type "..type_name.." is not supported"
	end
	local port, err = handler(cfg)
	if port then
		chnmap[name] = port
		cfgmap[name] = cfg
	end
	return port, err
end

function response.destroy(name)
	local channel = chnmap[name]
	if not channel then
		return nil, "Channel "..name.." does not exits!"
	end
	channel:stop()
	chnmap[name] = nil
	cfgmap[name] = nil
	return true
end

function response.list()
	return cfgmap
end

function init(port, ...)
end

function exit(...)
	for k,v in chnmap do
		v:stop()
	end
	chnmap = {}
	cfgmap = {}
end
