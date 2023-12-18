QBCore = exports[Config.QBCoreName]:GetCoreObject()
local server_music_queue = {}
local xSound = exports.xsound

if Config.ItemUsable then
    QBCore.Functions.CreateUseableItem('carplay', function(source, item)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player.Functions.GetItemByName(item.name) then return end
        TriggerClientEvent('complete_carplay:carplayItem', source)
    end)
end

QBCore.Functions.CreateCallback(
    "complete_carplay:getContacts",
    function(source, cb, vehicle)
        local xPlayer = QBCore.Functions.GetPlayer(source)
        local identifier = xPlayer.PlayerData.citizenid
        local owner = nil
        
        if Config.NoInstall then
            cb(getContacts(identifier))
        else
            MySQL.Async.fetchAll('SELECT citizenid FROM player_vehicles WHERE plate = @plate',
            {
                ['@plate'] = vehicle.plate
            },
            function(result)
                if result then
                    for _, v in ipairs(result) do
                        owner = v.citizenid
                    end
                    cb(getContacts(owner))
                end
            end)
        end
    end
)

function getContacts(owner)
    if Config.PhoneType == "qbphone" then
        local result = MySQL.Sync.fetchAll("SELECT * FROM player_contacts WHERE citizenid = @identifier ORDER BY name ASC", {
            ['@identifier'] = owner
        })
        return result
    elseif Config.PhoneType == "quasar" then
        local xPlayer = QBCore.Functions.GetPlayerByCitizenId(owner)
        local phone = xPlayer.PlayerData.charinfo.phone
        local result = MySQL.Sync.fetchAll("SELECT * FROM player_contacts WHERE identifier = @identifier ORDER BY name ASC", {
            ['@identifier'] = phone
        })
        return result
    elseif Config.PhoneType == "gksphone" then
        local result = MySQL.Sync.fetchAll("SELECT * FROM gksphone_users_contacts WHERE identifier = @identifier ORDER BY display ASC", {
            ['@identifier'] = owner
        })
        return result
    elseif Config.PhoneType == "highphone" then
        local result = MySQL.Sync.fetchAll("SELECT * FROM phone_contacts WHERE owner = @owner ORDER BY name ASC", {
            ['@owner'] = owner
        })
        return result
    elseif Config.PhoneType == "npwd" then
        local result = MySQL.Sync.fetchAll("SELECT * FROM npwd_phone_contacts WHERE identifier = @identifier", {
            ['@identifier'] = owner
        })
        return result
    elseif Config.PhoneType == "roadphone" then
        local result = MySQL.Sync.fetchAll("SELECT * FROM roadphone_contacts WHERE identifier = @identifier", {
            ['@identifier'] = owner
        })
        return result
    elseif Config.PhoneType == "lbphone" then
        local phone_number = exports["lb-phone"]:GetEquippedPhoneNumber(owner)
        local result = MySQL.Sync.fetchAll("SELECT * FROM phone_phone_contacts WHERE phone_number = @phone_number ORDER BY firstname ASC", {
            ['@phone_number'] = phone_number
        })
        return result
    end
end

QBCore.Functions.CreateCallback(
    "complete_carplay:getSettings",
    function(source, cb, vehicle)
        MySQL.Async.fetchAll('SELECT * FROM complete_carplay WHERE carPlate = @carPlate', 
        {
            ['@carPlate'] = vehicle.plate
        },
        function(result)
            if result then
                local settings_data = {}
                for _, v in ipairs(result) do
                    table.insert(
                        settings_data,
                        {
                            headlight = v.headlight,
                            interior = v.interior,
                            windows = v.windows,
                            trunk = v.trunk,
                            door1 = v.door1,
                            door2 = v.door2,
                            door3 = v.door3,
                            door4 = v.door4,
                            lock = v.lock,
                            cruise = v.cruise,
                            hColor = v.hColor
                        }
                    )
                end
                cb(settings_data)
            end
        end)
    end
)

QBCore.Functions.CreateCallback(
    "complete_carplay:getSavedSongs",
    function(source, cb, vehicle)
        local saved_songs = nil

        MySQL.Async.fetchAll('SELECT savedSongs FROM complete_carplay WHERE carPlate = @carPlate LIMIT 1',
        {
            ['@carPlate'] = vehicle.plate
        },
        function(result)
            if result then
                for _, v in ipairs(result) do
                    saved_songs = json.decode(v.savedSongs)
                end
                cb(saved_songs)
            end
        end)
    end
)

RegisterServerEvent('complete_carplay:saveSong')
AddEventHandler('complete_carplay:saveSong', function(song, vehicle)
    local saved_songs = nil
    local unpacked = {}

    MySQL.Async.fetchAll('SELECT savedSongs FROM complete_carplay WHERE carPlate = @carPlate LIMIT 1',
    {
        ['@carPlate'] = vehicle.plate
    },
    function(result)
        if result then
            for _, v in ipairs(result) do
                saved_songs = json.decode(v.savedSongs)
            end

            if saved_songs == nil then
                table.insert(unpacked, song)
            else
                unpacked = saved_songs
                table.insert(unpacked, song)
            end

            MySQL.Sync.execute("UPDATE complete_carplay SET savedSongs = @saved_songs WHERE carPlate = @carPlate", {
                ['@saved_songs'] = json.encode(unpacked),
                ['@carPlate'] = vehicle.plate
            })
        end
    end)
end)

RegisterServerEvent('complete_carplay:removeSavedSong')
AddEventHandler('complete_carplay:removeSavedSong', function(song, vehicle)
    local saved_songs = nil

    MySQL.Async.fetchAll('SELECT savedSongs FROM complete_carplay WHERE carPlate = @carPlate LIMIT 1',
    {
        ['@carPlate'] = vehicle.plate
    },
    function(result)
        if result then
            for _, v in ipairs(result) do
                saved_songs = json.decode(v.savedSongs)
            end
            -- get the array savedSongs and remove the song from it
            for i=1,#saved_songs do
                if saved_songs[i] == song then
                    table.remove(saved_songs, i)
                end
            end

            MySQL.Sync.execute("UPDATE complete_carplay SET savedSongs = @saved_songs WHERE carPlate = @carPlate", {
                ['@saved_songs'] = json.encode(saved_songs),
                ['@carPlate'] = vehicle.plate
            })
        end
    end)
end)

QBCore.Functions.CreateCallback(
    "complete_carplay:checkCarplay",
    function(source, cb, vehicle)
        local xPlayer = QBCore.Functions.GetPlayer(source)
        local identifier = xPlayer.PlayerData.citizenid
        
        if Config.NoInstall then
            cb(true)
        else
            MySQL.Async.fetchAll('SELECT carplayID FROM complete_carplay WHERE carPlate = @carPlate', 
            {
                ['@carPlate'] = vehicle.plate
            },
            function(result)
                if result then
                    local carplay_id = nil
                    for _, v in ipairs(result) do
                        carplay_id = v.carplayID
                    end

                    if carplay_id then
                        MySQL.Async.fetchAll('SELECT citizenid FROM player_vehicles WHERE carplayID = @carplayID',
                        {
                            ['@carplayID'] = carplay_id
                        },
                        function(result2)
                            if result2 then
                                local owner = nil
                                for _, v in ipairs(result2) do
                                    owner = v.citizenid
                                end

                                if Config.NeedPhoneItem then
                                    if owner == identifier then
                                        local found = false

                                        for i,v in ipairs(Config.PhoneItemName) do
                                            local phone_found = xPlayer.Functions.GetItemByName(v)
                                            if phone_found and phone_found.amount > 0 then
                                                found = true
                                            end
                                        end

                                        if found then
                                            cb(true)
                                        else
                                            TriggerClientEvent('QBCore:Notify', source, Config.Text['no_phone'], "error")
                                            cb(false)
                                        end
                                    else
                                        TriggerClientEvent('QBCore:Notify', source, Config.Text['not_owner'], "error")
                                        cb(false)
                                    end
                                else
                                    if owner == identifier then
                                        cb(true)
                                    else
                                        TriggerClientEvent('QBCore:Notify', source, Config.Text['not_owner'], "error")
                                        cb(false)
                                    end
                                end
                            end
                        end)
                    else
                        TriggerClientEvent('QBCore:Notify', source, Config.Text['no_carplay'], "error")
                        cb(false)
                    end
                else
                    TriggerClientEvent('QBCore:Notify', source, Config.Text['no_carplay'], "error")
                    cb(false)
                end
            end)
        end
    end
)

RegisterServerEvent('complete_carplay:sendMessageQuasar')
AddEventHandler('complete_carplay:sendMessageQuasar', function(receiver, message)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    local phone = xPlayer.PlayerData.charinfo.phone
    local cid = xPlayer.PlayerData.citizenid
    MySQL.Async.fetchAll("SELECT * FROM phone_messages WHERE phone = @phone AND number = @number", 
    {
        ['@phone'] = phone,
        ['@number'] = receiver
    },
    function(result)
        if result then
            local id = nil
            for _, v in ipairs(result) do
                id = v.id
            end
            if id then
                local temp_string = v.messages
                --local temp_string = '[{"message":"Yes","read":0,"created":"2022-08-08 05:35:18","owner":"553633909","type":"message"},{"message":"f","type":"message","read":0,"owner":"553633909","created":"2022-08-08 05:35:24"}]'
                local full_date = os.date("%y-%m-%d %X", os.time())
                local string_add = ',{"message": "'..message..'","read":0,"created": "'..full_date..'","owner":"'..phone..'","type":"message"}'
                local final = string.sub(temp_string, 1, string.find(temp_string, "]")-1) .. string_add
                --local decode2 = json.decode(final)
                MySQL.Sync.execute("UPDATE phone_messages SET `messages` = @messages WHERE id = @id", {
                    ['@messages'] = final,
                    ['@id'] = id
                })
            else
                local full_date = os.date("%y-%m-%d %X", os.time())
                local final_message = '[{"message": "'..message..'","read":0,"created": "'..full_date..'","owner":"'..phone..'","type":"message"}]'
                MySQL.Sync.execute(
                    "INSERT INTO `phone_messages`(`citizenid`,`phone`,`number`,`owner`,`messages`,`type`,`read`,`created`) VALUES (@cid, @transmitter, @receiver, NULL, @message, NULL, NULL, @full_date)",
                    {["@cid"] = cid, ["@transmitter"] = phone, ["@receiver"] = receiver, ["@message"] = final_message, ["@full_date"] = full_date}
                )
            end
        end
    end)
end)

RegisterServerEvent('complete_carplay:sendMessageGks')
AddEventHandler('complete_carplay:sendMessageGks', function(receiver, message)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    local phone = xPlayer.PlayerData.charinfo.phone

    local full_date = os.date("%y-%m-%d %X", os.time())
    MySQL.Sync.execute(
        "INSERT INTO `gksphone_messages`(`transmitter`,`receiver`,`message`,`time`,`isRead`,`owner`) VALUES (@transmitter, @receiver, @message, @full_date, 0, 0)",
        {["@transmitter"] = phone, ["@receiver"] = receiver, ["@message"] = message, ["@full_date"] = full_date}
    )
end)

RegisterServerEvent('complete_carplay:sendMessageHigh')
AddEventHandler('complete_carplay:sendMessageHigh', function(receiver, message)
    --local phoneNumber = exports.high_phone:getPlayerPhoneNumber(source)
    
    --[[
    local full_date = os.date("%d/%m/%y %H:%M", os.time())
    MySQL.Sync.execute(
        "INSERT INTO `phone_messages`(`from`,`to`,`message`,`attachments`,`time`) VALUES (@sender, @receiver, @message, '[]', @full_date)",
        {["@sender"] = phone, ["@receiver"] = receiver, ["@message"] = message, ["@full_date"] = full_date}
    )]]
end)

RegisterServerEvent('complete_carplay:sendMessageNpwd')
AddEventHandler('complete_carplay:sendMessageNpwd', function(receiver, message)
    local phone_number = exports.npwd:getPhoneNumber(source)
    exports.npwd:emitMessage({
        senderNumber = phone_number,
        targetNumber = receiver,
        message = message,
        embed = {}
    })
end)

RegisterServerEvent('complete_carplay:sendMessageRoadphone')
AddEventHandler('complete_carplay:sendMessageRoadphone', function(receiver, message)
    exports['roadphone']:sendMessage(receiver, message, false, false, nil)
end)

RegisterServerEvent('complete_carplay:sendMessageLBphone')
AddEventHandler('complete_carplay:sendMessageLBphone', function(receiver, message)
    local from = exports["lb-phone"]:GetEquippedPhoneNumber(source)
    exports["lb-phone"]:SendMessage(from, receiver, message, nil, nil, nil)
end)

QBCore.Functions.CreateCallback(
    "complete_carplay:installCarplay",
    function(source, cb, vehicle)
        local xPlayer = QBCore.Functions.GetPlayer(source)
        local carplay_quantity = xPlayer.Functions.GetItemByName('carplay')

        if carplay_quantity ~= nil and carplay_quantity.amount >= 1 then
            xPlayer.Functions.RemoveItem('carplay', 1)
            MySQL.Async.fetchAll("SELECT id FROM player_vehicles WHERE plate = @plate", 
            {
                ['@plate'] = vehicle.plate
            },
            function(result)
                if result then
                    MySQL.Sync.execute(
                        "INSERT INTO `complete_carplay`(`carplayID`,`carPlate`,`headlight`,`interior`,`windows`,`trunk`,`door1`,`door2`,`door3`,`door4`,`lock`,`cruise`) VALUES (NULL, @carPlate, @headlight, @interior, @windows, @trunk, @door1, @door2, @door3, @door4, @lock, @cruise)",
                        {["@carPlate"] = vehicle.plate, ["@headlight"] = false, ["@interior"] = false, ["@windows"] = false, ["@trunk"] = false, ["@door1"] = false, ["@door2"] = false, ["@door3"] = false, ["@door4"] = false, ["@lock"] = false, ["@cruise"] = false}
                    )
                    MySQL.Async.fetchAll("SELECT carplayID FROM complete_carplay WHERE carPlate = @plate", 
                    {
                        ['@plate'] = vehicle.plate
                    },
                    function(result2)
                        if result2 then
                            local carplay_id = nil
                            for _, v in ipairs(result2) do
                                carplay_id = v.carplayID
                            end
        
                            MySQL.Sync.execute("UPDATE player_vehicles SET carplayID = @carplayID WHERE plate = @plate", {
                                ['@carplayID'] = carplay_id,
                                ['@plate'] = vehicle.plate
                            })
                            
                            TriggerClientEvent('QBCore:Notify', source, Config.Text['carplay_installed'], "success")
                            cb(true)
                        end
                    end)
                end
            end)
        else
            TriggerClientEvent('QBCore:Notify', source, Config.Text['no_item'], "error")
            cb(false)
        end
    end
)

RegisterServerEvent('complete_carplay:setSetting')
AddEventHandler('complete_carplay:setSetting', function(setting, bool, vehicle)
    MySQL.Sync.execute("UPDATE complete_carplay SET `".. setting .."` = @bool WHERE carPlate = @plate", {
        ['@bool'] = bool,
        ['@plate'] = vehicle.plate
    })
end)

RegisterServerEvent('complete_carplay:setQueue')
AddEventHandler('complete_carplay:setQueue', function(plate, queue)
    server_music_queue[plate] = queue
end)

RegisterNetEvent("complete_carplay:soundStatus")
AddEventHandler("complete_carplay:soundStatus", function(type, musicId, data)
    TriggerClientEvent("complete_carplay:soundStatus", -1, type, musicId, data)
end)

QBCore.Functions.CreateCallback(
    "complete_carplay:getQueue",
    function(source, cb, plate)
        cb(server_music_queue[plate])
    end
)

QBCore.Functions.CreateCallback(
    "complete_carplay:getDate",
    function(source, cb)
        local temp = os.date("*t", os.time())
        
        cb(os.date("%d-%m-%y", os.time{year=temp['year'], month=temp['month'] - 1, day=temp['day']}))
    end
)

QBCore.Functions.CreateCallback(
    "complete_carplay:getTime",
    function(source, cb)
        cb(os.date("%H:%M"))
    end
)

local server_music_zones = {}

Citizen.CreateThread(function()
	while true do
        for i = 1, #server_music_zones do
            local v = server_music_zones[i]
            local name = v.name
            if NetworkGetEntityFromNetworkId(v.popo) == 0 or NetworkGetEntityFromNetworkId(v.popo) == nil then
                table.remove(server_music_zones, i)
                TriggerClientEvent("complete_carplay:RemovePlayer", -1, name)
            end
        end
		Citizen.Wait(1000)
	end
end)

RegisterNetEvent("complete_carplay:GetData")
AddEventHandler("complete_carplay:GetData", function(type, data)
    TriggerClientEvent("complete_carplay:SendData", math.floor(-1), server_music_zones)
end)

RegisterNetEvent("complete_carplay:ModifyURL")
AddEventHandler("complete_carplay:ModifyURL", function(data)
	local _data = data
	local zena = false
	for i = 1, #server_music_zones do
		local v = server_music_zones[i]
		if _data.name == v.name then
			v.deflink = _data.link
			if _data.popo then
				v.popo = _data.popo
			end
			v.deftime = 0
			v.isplaying = true
			v.queue = _data.queue
			zena = v
		end
	end
	if zena then
		TriggerClientEvent("complete_carplay:ModifyURL", -1, zena)
	end
end)

RegisterNetEvent('complete_carplay:AddVehicle')
AddEventHandler("complete_carplay:AddVehicle", function(vehdata)
    local Data = {}
    Data.name = vehdata.plate
    Data.coords = vehdata.coords
    Data.range = vehdata.volume * 30
    Data.volume = vehdata.volume
    Data.deflink = vehdata.link
    Data.isplaying = true
    Data.queue = vehdata.queue
    Data.deftime = 0
    Data.popo = vehdata.popo
    table.insert(server_music_zones, Data)
    TriggerClientEvent('complete_carplay:AddVehicle', -1, server_music_zones[#server_music_zones])
end)

RegisterNetEvent("complete_carplay:ChangeState")
AddEventHandler("complete_carplay:ChangeState", function(type, nome)
	for i = 1, #server_music_zones do
		local v = server_music_zones[i]
		if nome == v.name then
			v.isplaying = type
		end
	end
	TriggerClientEvent("complete_carplay:ChangeState", -1, type, nome)
end)

RegisterNetEvent("complete_carplay:ChangeVolume")
AddEventHandler("complete_carplay:ChangeVolume", function(vol, nome)
    local somafter = false
    local rangeafter = false
    for i = 1, #server_music_zones do
        local v = server_music_zones[i]
        if nome == v.name then
            local vadi = v.volume + vol
            if vadi <= 1.01 and vadi >= -0.001 then
				if vadi < 0.005 then
					vadi = 0.0
				end
                if v.popo then
                    v.range = (v.volume * 30)
                else
					if vadi >= 0.05 then
						v.range = (vadi * v.range) / v.volume
					end
                end
                v.volume = vadi
                somafter = v.volume
                rangeafter = v.range
            end
        end
    end
    if somafter and rangeafter then
        TriggerClientEvent("complete_carplay:ChangeVolume", -1, somafter, rangeafter, nome)
    end
end)

RegisterNetEvent("complete_carplay:ChangePosition")
AddEventHandler("complete_carplay:ChangePosition", function(quanti, nome, timestamp)
	for i = 1, #server_music_zones do
		local v = server_music_zones[i]
		if nome == v.name then
			v.deftime = timestamp + quanti
			if v.deftime < 0 then
				v.deftime = 0
			end
		end
	end
	TriggerClientEvent("complete_carplay:ChangePosition", -1, quanti, nome)
end)

RegisterNetEvent("complete_carplay:AddToQueue")
AddEventHandler("complete_carplay:AddToQueue", function(nome, url)
	for i = 1, #server_music_zones do
		local v = server_music_zones[i]
		if nome == v.name then
			table.insert(v.queue, url)
		end
	end
	TriggerClientEvent("complete_carplay:AddToQueue", -1, nome, url)
end)

RegisterNetEvent("complete_carplay:SetQueue")
AddEventHandler("complete_carplay:SetQueue", function(nome, queue, url)
	for i = 1, #server_music_zones do
		local v = server_music_zones[i]
		if nome == v.name then
            if Config.Debug then
                print("[DEBUG] setting queue")
                print('[DEBUG] queue: ' .. json.encode(queue))
            end
            
			v.queue = queue
		end
	end
	TriggerClientEvent("complete_carplay:SetQueue", -1, nome, queue, url)
end)

RegisterNetEvent("complete_carplay:RemovePlayer")
AddEventHandler("complete_carplay:RemovePlayer", function(nome)
	for i = 1, #server_music_zones do
		local v = server_music_zones[i]
		if nome == v.name then
			table.remove(server_music_zones, i)
		end
	end
	TriggerClientEvent("complete_carplay:RemovePlayer", -1, nome)
end)

QBCore.Functions.CreateCallback(
    "complete_carplay:getQueue",
    function(source, cb, nome)
        for i = 1, #server_music_zones do
            local v = server_music_zones[i]
            if nome == v.name then
                cb(v.queue)
            end
        end
    end
)

QBCore.Functions.CreateCallback(
    "complete_carplay:getPlaying",
    function(source, cb, nome)
        for i = 1, #server_music_zones do
            local v = server_music_zones[i]
            if nome == v.name then
                cb(v.isplaying)
            end
        end
        cb(false)
    end
)




