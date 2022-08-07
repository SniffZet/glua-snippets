do
	local IsExists, CreateDir, cachedMats, Fetch, CRC, Write, Read, format, sub = file.Exists, file.CreateDir, {}, http.Fetch, util.CRC, file.Write, file.Read, string.format, string.sub

	local _PATH, PATH, Material = 'data/surfTextures/%s.png', 'GAME', Material

	CreateDir 'surfTextures'

	local function checkRel(link, aSum)
		local uName = format(_PATH, aSum)
		local dat = Read(uName, PATH) or ''
		Fetch(link, function(res)
			local crcRes = CRC(res)
			local oldRes = CRC(dat)
			if crcRes ~= oldRes then
				Write( sub(uName,6), res)
				print( format('EM > CheckSum Updated (%s, %s)', crcRes, oldRes) )
			end
			local mat = Material(uName)
			cachedMats[link] = mat
			return mat
		end)
	end

	local ERROR = Material 'error'
	function surface.GetWeb( link )
		if cachedMats[link] then return cachedMats[link] end

		local checkSum = CRC(link)
		return checkRel(link, checkSum) or ERROR
	end

	function surface.GetWebCache()
		return cachedMats
	end
end
