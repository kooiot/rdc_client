local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

.net_peer {
	host 0 : string
	port 1 : integer
}

.net_channel {
	protocol 0 : string
	remote 1 : net_peer
	local 2 : net_peer
}

.serial_channel {
	port 0 : string
	baudrate 1 : integer
	bytesize 2 : integer
	parity 3 : string
	stopbits 4 : string
	flowcontrol 5 : string
}

.plugin_channel {
	plugin 0 : string
	config 1 : string
}

handshake 1 {
	response {
		msg 0  : string
	}
}

create 2 {
	request {
		type 0 : string
		data 1 : binary
	}
	response {
		result 0 : boolean
		channel 1 : string
		message 2 : string
	}
}

destroy 3 {
	request {
		type 0 : string
		channel 1 : string
	}
}

data 10 {
	request {
		channel 0 : string
		data 1 : binary
	}
}

list 5 {
	request {
		type 0 : string
	}
	response {
		results 0 : *string
	}
}

quit 99 {}

]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

heartbeat 1 {}

data 10 {
	request {
		channel 0 : string
		data 1 : binary
	}
}

]]

return proto
