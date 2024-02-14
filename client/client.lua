local framework = GetResourceState('es_extended') == 'started' and 'esx' or GetResourceState('qb-core') == 'started' and 'qbcore' or 'other'
if framework == "esx" then
    ESX = exports["es_extended"]:getSharedObject()
elseif framework == "qbcore" then
    QBCore = exports['qb-core']:GetCoreObject()
end

local uiOpen = false
local userData = {
    lastClaimed = 0,
    canClaim = false,
}

function TimeToDate(time)
	local day = math.floor(time / 86400)
	local hour = math.floor(time / 60 / 60) % 24
	local minute = math.floor(time / 60) % 60
	local second = time % 60

	return day, hour, minute, second
end

function DateToTime(day, hour, minute, second)
	return day * 86400 + hour * 3600 + minute * 60 + second
end

local timeToClaim = DateToTime(0, Config.TimeToClaim['hours'], Config.TimeToClaim['minutes'], Config.TimeToClaim['seconds']) 

local function loadData(data)
    for k, v in pairs(data) do
        userData[k] = v
        SendNUIMessage(
            { 
                type = "dailyBonus",
                action = "setData",
                data = k, 
                value = v
            }
        )
    end
end

local function saveData()
    SetResourceKvp('complete_daily_bonus', json.encode(userData))
end

local function initializeUi()
    local data = GetResourceKvpString('complete_daily_bonus')
    if data then loadData(json.decode(data)) end
    
    Citizen.Wait(500)
    
    local rouletteData = Config.RouletteData
    local finalRouletteData = {}

    for k, v in pairs(rouletteData) do
        table.insert(finalRouletteData, rouletteData[k])
    end

    SendNUIMessage(
        {
            type = "dailyBonus",
            action = "initialize",
            data = userData,
            rouletteData = json.encode(finalRouletteData),
            probability = Config.RarityProbability,
            animationDuration = Config.AnimationDuration,
        }
    )

    Config.Notify(Config.Text['initialized'], 'success')
end

RegisterCommand(Config.OpenCommand, function()
    if not uiOpen then
        SendNUIMessage(
            {
                type = "dailyBonus",
                action = "open"
            }
        )
        SetNuiFocus(true, true)
        uiOpen = true
    end
end)

AddEventHandler('onClientResourceStart', function (resourceName)
    if(GetCurrentResourceName() ~= resourceName) then return end

    Wait(1000)

    initializeUi()
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)

        if not userData.canClaim then
            local year, month, day, hour, minute, second = GetLocalTime()
            local currentTime = DateToTime(day, hour, minute, second)
            local lastClaimed = userData.lastClaimed
            
            local timeDifference = lastClaimed - currentTime + timeToClaim
            local day, hour, minute, second = TimeToDate(timeDifference)

            if timeDifference <= 0 then
                userData.canClaim = true
                SendNUIMessage({
                    type = "dailyBonus",
                    action = "setData",
                    data = 'canClaim',
                    value = true
                })
                saveData()
            else
                local day, hour, minute, second = TimeToDate(timeDifference)
    
                if hour < 10 then hour = '0' .. hour end
                if minute < 10 then minute = '0' .. minute end
                if second < 10 then second = '0' .. second end
    
                SendNUIMessage({
                    type = "dailyBonus",
                    action = "setData",
                    data = 'lastClaimed',
                    value = hour .. ':' .. minute .. ':' .. second
                })
            end
        end
    end
end)

RegisterNUICallback('claim', function(data, cb)
    userData.canClaim = false
    local year, month, day, hour, minute, second = GetLocalTime()
    userData.lastClaimed = DateToTime(day, hour, minute, second)
    SendNUIMessage({
        type = "dailyBonus",
        action = "setData",
        data = 'canClaim',
        value = false
    })
    saveData()
    cb('ok')
end)

RegisterNUICallback('reward', function(data, cb)
    local reward = Config.RouletteData[data.id]
    if reward.type == 'vehicle' then
        TriggerServerEvent('complete_daily_bonus:giveVehicle', reward.model)
    elseif reward.type == 'item' then
        TriggerServerEvent('complete_daily_bonus:giveItem', reward.model, reward.quantity)
    elseif reward.type == 'cash' then
        TriggerServerEvent('complete_daily_bonus:giveCash', reward.model)
    elseif reward.type == 'bank' then
        TriggerServerEvent('complete_daily_bonus:giveBank', reward.model)
    elseif reward.type == 'weapon' then
        TriggerServerEvent('complete_daily_bonus:giveWeapon', reward.model)
    end
    Config.Notify(Config.Text['item_collected'] .. ' ' .. reward.name, 'success')
    cb('ok')
end)

RegisterNUICallback('sell', function(data, cb)
    local reward = Config.RouletteData[data.id].sell
    TriggerServerEvent('complete_daily_bonus:sellReward', reward)
    Config.Notify(Config.Text['item_sold'] .. reward, 'success')
    cb('ok')
end)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    uiOpen = false
    cb('ok')
end)
