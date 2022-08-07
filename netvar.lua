networking = {}
networking.vars = {}

if CLIENT then
	local Receive, ReadUInt, ReadString, ReadType, Call = net.Receive, net.ReadUInt, net.ReadString, net.ReadType, hook.Call
	Receive('net:sync', function()
		local syncer = ReadUInt(32)
		local key = ReadString()
		local data = ReadType()

		if !networking.vars[syncer] then networking.vars[syncer] = {} end
		networking.vars[syncer][key] = { v = data }

		Call('NetVarReceived', GM, key, data)
	end)
	Receive('net:removeent', function()
		networking.vars[ReadUInt(32)] = nil
	end)
else
	util.AddNetworkString('net:sync')
	util.AddNetworkString('net:removeent')

	local Start, WriteUInt, WriteString, WriteType, Broadcast, hook, Entity, pairs = net.Start, net.WriteUInt, net.WriteString, net.WriteType, net.Broadcast, hook.Add, Entity, pairs

	local function Sync(ent, key, value, recipient)
		local uID = ent:EntIndex()
		if !networking.vars[uID][key] then return end

		Start('net:sync')
		WriteUInt(uID, 32)
		WriteString(key)
		WriteType(value)
		net[recipient and 'Send' or 'Broadcast'](recipient)
	end

	function ENTITY:SetNetVar(key, value, recipient)
		local uID = self:EntIndex()
		if !networking.vars[uID] then networking.vars[uID] = {} end

		networking.vars[uID][key] = { v = value, r = recipient }
		Sync(self, key, value, recipient)
 	end

 	hook("PlayerInitialSpawn", 'netvar_sync', function(ply)
 		for entindex,var_value in pairs(networking.vars) do 
 			for var_name,tb in pairs(var_value) do -- боже прости меня за это
 				if tb.r then continue end

 				Sync(Entity(entindex), var_name, tb.v, ply)
 			end
 		end
 	end)

 	hook("EntityRemoved", 'netvar_remove', function(ent)
 		if networking.vars[ent:EntIndex()] then
 			networking.vars[ent:EntIndex()] = nil

 			Start('net:removeent')
 			WriteUInt(ent:EntIndex(), 32)
 			Broadcast()
 		end
 	end)
end

function ENTITY:GetNetVar(key, def)
	return networking.vars[self:EntIndex()] and networking.vars[self:EntIndex()][key].v or def
end
