local skynet = require 'skynet'

local chnmap = nil

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
	return handler(cfg)
end

function response.destroy(name)
end

function init(port, ...)
	chnmap = {}
end

function exit(...)
	for k,v in chnmap do
		v:stop()
	end
end
