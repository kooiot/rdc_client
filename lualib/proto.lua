local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

handshake 1 {
	response {
		msg 0  : string
	}
}

data 10 {
	request {
		channel 0 : string
		data 1 : binary
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

create 2 {
	request {
		type 0 : string
		param 1 : string 
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

list 5 {
	request {
		type 0 : string
	}
	response {
		results 0 : *string
	}
}

data 10 {
	request {
		channel 0 : string
		data 1 : binary
	}
}

]]

return proto
