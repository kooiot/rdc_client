local skynet = require 'skynet'
local rs232 = require 'rs232'

local port_map = {}
local thread_map = {}
local serial = {}

skynet.PTYPE_SERIAL = 99

skynet.register_protocol({
	name = "serial",
	id = skynet.PTYPE_SERIAL,
})

seiral.open = function(port, baudrate, bytesize, parity, stopbits, flowcontrol)
	assert(port, "Port is requried")
	local opts = {
		baud = '_'..(baudrate or 9600),
		data_bits = '_'..(bytesize or 8),
		parity = string.upper(parity or "NONE"),
		stop_bits = '_'..(stopbits or 1),
		flow_control = string.upper(flowcontrol or "OFF")
	}

	local p, err = rs232.port(port, opts)
	if not p then
		return nil, err
	end

	local fd = p:fd()
	assert(not port_map[fd])
	port_map[fd] = p
	return fd
end

local function bind_func(serial, name)
	serial[name] = function(fd, ...)
		local port = port_map[fd]
		assert(port, "port does not exits")
		return port[name](port, ...)
	end
end

bind_func(serial, "close")
bind_func(serial, "write")
--bind_func(serial, "read")
bind_func(serial, "flush")
bind_func(serial, "in_queue_clear")
bind_func(serial, "in_queue")
bind_func(serial, "device")
bind_func(serial, "fd")
bind_func(serial, "set_baud_rate")
bind_func(serial, "baud_rate")
bind_func(serial, "set_data_bits")
bind_func(serial, "data_bits")
bind_func(serial, "set_parity")
bind_func(serial, "parity")
bind_func(serial, "set_flow_control")
bind_func(serial, "flow_control")
bind_func(serial, "set_dtr")
bind_func(serial, "dtr")
bind_func(serial, "set_rts")
bind_func(serial, "rts")

serial.start = function(fd)
	local fd = fd
	local port = port_map[fd]
	local address = skynet.self()
	assert(port)
	if not thread_map[fd] then
		skynet.fork(function()
			thread_map[fd] = address
			while true do
				local data, err = port:read(100, 100)	
				if not data then
					break
				end
				skynet.send(address, "serial", fd, data, err)
			end
			thread_map[fd] = nil
		end)
	end
end

return serial
