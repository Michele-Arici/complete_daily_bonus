local uiOpen = false
local userData = {
    lastClaimed = {
        year = 0,
        month = 0,
        day = 0,
        hour = 0,
        minute = 0,
        second = 0
    },
}


local function initializeUi()
    local data = GetResourceKvpString('complete_daily_bonus')
    if data then loadData(json.decode(data)) end
    
    Citizen.Wait(500)
    
    local rouletteData = Config.RouletteData
    local finalRouletteData = {}

    for k, v in pairs(rouletteData) do
        rouletteData[k].reward = nil
        table.insert(finalRouletteData, rouletteData[k].data)
    end

    SendNUIMessage(
        {
            type = "dailyBonus",
            action = "initialize",
            data = userData,
            rouletteData = json.encode(finalRouletteData),
            probability = Config.RarityProbability
        }
    )
end

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

RegisterCommand(Config.OpenCommand, function()
    if not uiOpen then
        SendNUIMessage(
            {
                type = "dailyBonus",
                action = "open"
            }
        )
        SetNuiFocus(true, true)
        settingsOpen = true
    end
end)

AddEventHandler('onClientResourceStart', function (resourceName)
    if(GetCurrentResourceName() ~= resourceName) then return end

    Wait(1000)

    initializeUi()

    local year, month, day, hour, minute, second = GetLocalTime()
end)