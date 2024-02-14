-- /////////////// ----------- //////////////
-- This are examples with ESX and QBCore but you can use any other framework, just replace the ESX and QBCore functions with the ones from your framework 
-- /////////////// ----------- //////////////

local framework = GetResourceState('es_extended') == 'started' and 'esx' or GetResourceState('qb-core') == 'started' and 'qbcore' or 'other'
if framework == "esx" then
    ESX = exports["es_extended"]:getSharedObject()
elseif framework == "qbcore" then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- Plate generation functions

-- ///////////// QBCORE VEHICLESHOP CODE //////////////
local function GenerateQbPlate()
    local plate = QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(2)
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', { plate })
    if result then
        return GeneratePlate()
    else
        return plate:upper()
    end
end
-- ///////////// ---------------------- //////////////

-- ///////////// ESX VEHICLESHOP CODE //////////////
local NumberCharset = {}
local Charset = {}

for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end

for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

function GenerateEsxPlate()
	math.randomseed(GetGameTimer())
    
    -- 3 letters - space - 3 numbers
	local plate = string.upper(GetRandomLetter(3) .. (true and ' ' or '') .. GetRandomNumber(3))

	local result = MySQL.scalar.await('SELECT plate FROM owned_vehicles WHERE plate = ?', { plate })
    if result then
        return GenerateEsxPlate()
    else
        return plate
    end
end

function GetRandomNumber(length)
	Wait(0)
	return length > 0 and GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)] or ''
end

function GetRandomLetter(length)
	Wait(0)
	return length > 0 and GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)] or ''
end
-- ///////////// ------------------- //////////////

RegisterNetEvent("complete_daily_bonus:sellReward", function(reward)
    local _source = source

    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(_source)
        xPlayer.addAccountMoney(Config.SellType, reward)
    elseif framework == 'qbcore' then
        local xPlayer = QBCore.Functions.GetPlayer(_source)
        xPlayer.Functions.AddMoney(Config.SellType, reward, 'Daily bonus item sold')
    end
end)

-- complete_daily_bonus:giveVehicle
RegisterNetEvent("complete_daily_bonus:giveVehicle", function(vehicle)
    local _source = source
    
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(_source)
        local plate = GenerateEsxPlate()

        MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle, stored, parking) VALUES (?, ?, ?, ?, ?)', {
            xPlayer.identifier,
            plate,
            json.encode({model = joaat(vehicle), plate = plate}),
            1,
            Config.CarParkingSpawn
        })
    elseif framework == 'qbcore' then
        local xPlayer = QBCore.Functions.GetPlayer(_source)
        local plate = GenerateQbPlate()
        
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state, balance, paymentamount, paymentsleft, financetime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            xPlayer.PlayerData.license,
            xPlayer.PlayerData.citizenid,
            vehicle,
            GetHashKey(vehicle),
            '{}',
            plate,
            'pillboxgarage',
            0,
            0,
            0,
            0,
            0
        })
    end
end)

-- complete_daily_bonus:giveItem
RegisterNetEvent("complete_daily_bonus:giveItem", function(item, quantity)
    local _source = source
    
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(_source)
        xPlayer.addInventoryItem(item, quantity)
    elseif framework == 'qbcore' then
        local xPlayer = QBCore.Functions.GetPlayer(_source)
        xPlayer.Functions.AddItem(item, quantity)
    end
end)

-- complete_daily_bonus:giveCash
RegisterNetEvent("complete_daily_bonus:giveCash", function(cash)
    local _source = source
    
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(_source)
        xPlayer.addMoney(cash)
    elseif framework == 'qbcore' then
        local xPlayer = QBCore.Functions.GetPlayer(_source)
        xPlayer.Functions.AddMoney('cash', cash, 'Daily bonus reward')
    end
end)

-- complete_daily_bonus:giveBank
RegisterNetEvent("complete_daily_bonus:giveBank", function(bank)
    local _source = source
    
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(_source)
        xPlayer.addAccountMoney('bank', bank)
    elseif framework == 'qbcore' then
        local xPlayer = QBCore.Functions.GetPlayer(_source)
        xPlayer.Functions.AddMoney('bank', bank, 'Daily bonus reward')
    end
end)

-- complete_daily_bonus:giveWeapon
RegisterNetEvent("complete_daily_bonus:giveWeapon", function(weapon)
    local _source = source
    
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(_source)
        xPlayer.addWeapon(weapon, Config.WeaponAmmo)
    elseif framework == 'qbcore' then
        local xPlayer = QBCore.Functions.GetPlayer(_source)
        xPlayer.Functions.AddItem(weapon, Config.WeaponAmmo)
    end
end)

