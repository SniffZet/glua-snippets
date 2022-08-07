quicknet = quicknet or {}
quicknet.stored = quicknet.stored or {}

do -- TODO: Replace JSON to pon or custom library.
	local Format, Start, WriteData, WriteString, type, TableToJSON, setmetatable, SendToServer = string.format, net.Start, net.WriteData, net.WriteString, type, util.TableToJSON, setmetatable, net.SendToServer

	local mt = {}
	mt.__index = mt
	mt.__tostring = function(self)
		return Format('NET[%s]', self.Name)
	end

	function mt:Hook( cb )
		self.Callback = cb
		return self
	end

	function mt:call(p, d)
		self.Callback(SERVER && p || d, SERVER && d)
	end

	if SERVER then
		function mt:Send( rec, ... )
			Start('en')
			WriteString(self.Name)
			WriteString( TableToJSON({...}) )
			net[ type(rec) == 'Player' and 'Send' or 'Broadcast' ](rec)
			return self
		end
	else
		function mt:Send( ... )
			Start('en')
			WriteString(self.Name)
			WriteString( TableToJSON({...}) )
			SendToServer()
			return self
		end
	end

	function quicknet.Get(name)
		quicknet.stored[name] = {Name = name}

		return setmetatable(quicknet.stored[name], mt)
	end
end

do
	local AddReceiver, ReadString, ReadData, JSONToTable, unpack = net.Receive, net.ReadString, net.ReadData, util.JSONToTable, unpack

	if(SERVER) then
		util.AddNetworkString 'en'
	end

	AddReceiver('en', function(_,ply)
		local n, dat = ReadString(), JSONToTable(ReadString())
		local el = quicknet.stored[n]
		assert(el, 'Unregistered NET-Message')

		el:call( ply, dat )
	end)
end

