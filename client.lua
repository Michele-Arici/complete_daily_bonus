QBCore = exports[Config.QBCoreName]:GetCoreObject()
local xSound = exports.xsound
local coords = nil
local player = nil
local job = nil
local vehicle_plate = nil
local vehicle_opened = nil
local ui_open = false
local url = nil
local playing = false
local music_queue = {}
local cruise_active = false
local cruise_speed = nil
local trunk_camera = false
local cam = nil
local radio_playing = false
local radio_name = "OFF"
local player_deleted = true
local navigator_start_position = nil
local navigator_start_time = nil
local waypoint_km_travelled = nil
local waypoint_time_travelled = nil

local music_zones = {}
local SoundsPlaying = {}
local datasoundinfo = {}
xSound = exports.xsound

local current_focus = false

local headlight_color = 0

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore.Functions.GetPlayerData(function(PlayerData)
        job = PlayerData.job.name

        SendNUIMessage(
            {
                type = "set_position",
                position = Config.NavigatorPosition
            }
        )

        SendNUIMessage(
            {
                type = "setCStreetWaypoint",
                bool = Config.DisplayCurrentStreet
            }
        )

        SendNUIMessage(
            {
                type = "useKm",
                bool = Config.Km
            }
        )

        SendNUIMessage(
            {
                type = "setApps",
                apps = json.encode(Config.Apps),
                blacklist = Config.BlackListSongs,
                draggable = Config.Draggable,
                draggable_key = Config.RemoveFocusKey
            }
        )

    end)
end)

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() == resource then
        job = QBCore.Functions.GetPlayerData().job
        Wait(10)

        SendNUIMessage(
            {
                type = "set_position",
                position = Config.NavigatorPosition
            }
        )

        SendNUIMessage(
            {
                type = "setCStreetWaypoint",
                bool = Config.DisplayCurrentStreet
            }
        )

        SendNUIMessage(
            {
                type = "useKm",
                bool = Config.Km
            }
        )

        SendNUIMessage(
            {
                type = "setApps",
                apps = json.encode(Config.Apps),
                blacklist = Config.BlackListSongs,
                draggable = Config.Draggable,
                draggable_key = Config.RemoveFocusKey
            }
        )

        TriggerServerEvent("complete_carplay:GetData")
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    job = JobInfo.name
end)

Citizen.CreateThread(function()
	while true do
        veh = GetVehiclePedIsIn(PlayerPedId(), true)
        Citizen.Wait(100)
	end
end)

RegisterCommand(Config.MechanicInstallCommand, function()
    if Config.RequireMechanic then
        for _, job_name in ipairs(Config.MechanicJobName) do
            if job == job_name then
                InstallCarplay()
            end
        end
    else
        InstallCarplay()
    end
end)

function InstallCarplay()
    local player_ped = PlayerPedId()
    if IsPedInAnyVehicle(player_ped, false) then
        local vehicle = GetVehiclePedIsIn(player_ped, false)
        local car = QBCore.Functions.GetVehicleProperties(vehicle)
        
        QBCore.Functions.TriggerCallback(
            "complete_carplay:installCarplay",
            function(result)
                if result then
                    while (not HasAnimDictLoaded("random@mugging4")) do
                        RequestAnimDict("random@mugging4")
                        Citizen.Wait(5)
                    end
                    TaskPlayAnim(player_ped, 'random@mugging4', 'struggle_loop_b_thief', 2.0, 2.0, Config.InstallTime, 51, 0, false, false, false)
                    Wait(Config.InstallTime)
                    ClearPedTasks(player_ped , true)
                    TaskLeaveVehicle(player_ped, vehicle, 1)
                end
            end,
            car
        )
    end
end

RegisterNetEvent("complete_carplay:carplayItem")
AddEventHandler("complete_carplay:carplayItem",
    function()
        if Config.RequireMechanic then
            for _, job_name in ipairs(Config.MechanicJobName) do
                if job == job_name then
                    InstallCarplay()
                end
            end
        else
            InstallCarplay()
        end
    end
)

RegisterKeyMapping(Config.OpenUICommand, 'Open carplay key', 'keyboard', Config.OpenUIKey)

RegisterCommand(Config.OpenUICommand, function()
    if not ui_open then
        CheckCarplay()
    end
end)

RegisterKeyMapping(Config.ReturnFocusCommand, 'Enable carplay focus', 'keyboard', Config.ReturnFocusKey)

RegisterCommand(Config.ReturnFocusCommand, function()
    if not current_focus and ui_open then
        current_focus = true
        while true do
            Wait(10)
            if not current_focus then
                break
            end
            SetNuiFocus(true, true)
        end
    end
end)

RegisterNUICallback(
    "removeFocus",
    function(data)
        SetNuiFocus(false, false)
        current_focus = false
    end
)

function CheckCarplay()
    if IsPedInAnyVehicle(PlayerPedId(), false) and not IsPlayerDead(PlayerPedId()) and GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        vehicle_opened = vehicle
        local car = QBCore.Functions.GetVehicleProperties(vehicle)

        QBCore.Functions.TriggerCallback(
            "complete_carplay:checkCarplay",
            function(result)
                if result then
                    OpenUI()
                end
            end,
            car
        )
    end
end

function OpenUI()
    local car = QBCore.Functions.GetVehicleProperties(vehicle_opened)
    if car.plate and car.plate ~= vehicle_plate then
        ui_open = false
        url = nil
        playing = false
        player_deleted = true
        music_queue = {}
        cruise_active = false
        cruise_speed = nil
        cam = nil
        radio_playing = false
        radio_name = "OFF"
    end
    vehicle_plate = car.plate

    datasoundinfo = {volume = 0.5, queue = {}}
    local linkurl
    local isplaying
    local v_plate = GetVehicleNumberPlateText(vehicle_opened)
    if not Config.High3DSound then
        if xSound:soundExists(v_plate) then
            datasoundinfo.volume = xSound:getVolume(v_plate)
            QBCore.Functions.TriggerCallback(
                "complete_carplay:getQueue", 
                function (queue)
                    if queue then
                        datasoundinfo.queue = queue
                    end
                end,
                v_plate
            )
            QBCore.Functions.TriggerCallback(
                "complete_carplay:getPlaying", 
                function (bool)
                    isplaying = bool
                end,
                v_plate
            )
            if xSound:isPlaying(v_plate) then
                linkurl = xSound:getLink(v_plate)
            end
        end
    else
        local sound = exports["high_3dsounds"]:getSound(v_plate)
        if sound then
            datasoundinfo.volume = exports["high_3dsounds"]:getSoundData(v_plate, "volume")
            QBCore.Functions.TriggerCallback(
                "complete_carplay:getQueue", 
                function (queue)
                    if queue then
                        datasoundinfo.queue = queue
                    end
                end,
                v_plate
            )
            QBCore.Functions.TriggerCallback(
                "complete_carplay:getPlaying", 
                function (bool)
                    isplaying = bool
                end,
                v_plate
            )
            if exports["high_3dsounds"]:getSoundData(v_plate, "playing") then
                linkurl = exports["high_3dsounds"]:getSoundData(v_plate, "url")
            end
        end
    end

    SetVehicleRadioEnabled(vehicle_opened, true)

    if trunk_camera then
        TrunkCameraEvent()
    end

    QBCore.Functions.TriggerCallback(
        "complete_carplay:getContacts",
        function(contacts_data)
            QBCore.Functions.TriggerCallback(
                "complete_carplay:getSavedSongs",
                function(saved_songs_data)
                    QBCore.Functions.TriggerCallback(
                        "complete_carplay:getSettings",
                        function(settings_data)
                            headlight_color = settings_data.hColor
                            for k,v in ipairs(settings_data) do
                                for name, bool in pairs(v) do
                                    SetSetting(name, bool)
                                end
                            end
                            ui_open = true
                            if radio_playing == false and GetRadioStationName(GetPlayerRadioStationIndex()) ~= "OFF" then
                                radio_name = GetRadioStationName(GetPlayerRadioStationIndex())
                                SetVehRadioStation(vehicle_opened, radio_name)
                                radio_playing = true
                            end

                            local tank_healt = (GetVehiclePetrolTankHealth(vehi) / 1000) * 100
                            local blip = GetFirstBlipInfoId(8)
                            local blipX = 0.0
                            local blipY = 0.0
                            if (blip ~= 0) then
                                local coord = GetBlipCoords(blip)
                                blipX = coord.x
                                blipY = coord.y
                            end

                            current_focus = true
                            SetNuiFocus(true, true)
                            SendNUIMessage(
                                {
                                    type = "carplay",
                                    settings = json.encode(settings_data),
                                    contacts = json.encode(contacts_data),
                                    phone_type = Config.PhoneType,
                                    max_speed = GetVehicleEstimatedMaxSpeed(vehicle_opened) * 3.6,
                                    radio_name = radio_name,
                                    radio_playing = radio_playing,
                                    url = linkurl,
                                    playing = isplaying,
                                    music_queue = json.encode(datasoundinfo.queue),
                                    hour = GetClockHours(),
                                    minutes = GetClockMinutes(),
                                    weather = GetNextWeatherTypeHashName(),
                                    coords = GetEntityCoords(PlayerPedId()),
                                    model_name = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle_opened)),
                                    saved_songs = json.encode(saved_songs_data),
                                    tank_healt = (math.floor(tank_healt * 10) / 10),
                                    current_waypoint = {blipX, blipY}
                                }
                            )
                        end,
                        car
                    )
                end,
                car
            )
        end,
        car
    )
end

RegisterNUICallback(
    "setNavigator",
    function(data)
        if Config.Debug then
            print('[DEBUG] setNavigator ' .. data['lat'] .. ' ' .. data['lng'])
        end
        SetNewWaypoint(tonumber(data['lng']), tonumber(data['lat']))
    end
)

RegisterNUICallback(
    "saveSong",
    function(data)
        local car = QBCore.Functions.GetVehicleProperties(vehicle_opened)
        TriggerServerEvent("complete_carplay:saveSong", data['song'], car)
        Citizen.Wait(1000)
        QBCore.Functions.TriggerCallback(
            "complete_carplay:getSavedSongs",
            function(saved_songs_data)
                SendNUIMessage(
                    {
                        type = "updateSavedSongs",
                        saved_songs = json.encode(saved_songs_data)
                    }
                )
            end,
            car
        )
    end
)

RegisterNUICallback(
    "removeSavedSong",
    function(data)
        local car = QBCore.Functions.GetVehicleProperties(vehicle_opened)
        TriggerServerEvent("complete_carplay:removeSavedSong", data['soung_url'], car)
        Citizen.Wait(1000)
        QBCore.Functions.TriggerCallback(
            "complete_carplay:getSavedSongs",
            function(saved_songs_data)
                SendNUIMessage(
                    {
                        type = "updateSavedSongs",
                        saved_songs = json.encode(saved_songs_data)
                    }
                )
            end,
            car
        )
    end
)

RegisterNUICallback(
    "playSound",
    function(data)
        url = data['url']
        if Config.Debug then
            print('[DEBUG] Play sound: ' .. url)
        end
        for i,b_song in ipairs(Config.BlackListSongs) do
            if url == b_song then
                QBCore.Functions.Notify("You can't play that song", 'error', 5000)
                return
            end
        end
        local nameid = nil
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            local vehi = GetVehiclePedIsIn(PlayerPedId(),false)
            local plate = GetVehicleNumberPlateText(vehi)
            nameid = plate
        end

        SetUrl(url, nameid)
    end
)

RegisterNUICallback(
    "setQueue",
    function(data)
        if Config.Debug then
            print('[DEBUG] Setting queue')
        end
        local vehi = GetVehiclePedIsIn(PlayerPedId(),false)
        local v_plate = GetVehicleNumberPlateText(vehi)
        TriggerServerEvent("complete_carplay:SetQueue", v_plate, data['queue'], data['url'])
    end
)

RegisterNUICallback(
    "addToQueue",
    function(data)
        if Config.Debug then
            print('[DEBUG] added to queue ' .. data['url'])
        end
        for i,b_song in ipairs(Config.BlackListSongs) do
            if data['url'] == b_song then
                QBCore.Functions.Notify("You can't play that song", 'error', 5000)
                return
            end
        end
        local vehi = GetVehiclePedIsIn(PlayerPedId(),false)
        local v_plate = GetVehicleNumberPlateText(vehi)
        TriggerServerEvent("complete_carplay:AddToQueue", v_plate, data['url'])
    end
)

RegisterNUICallback(
    "volumeSound",
    function(data)
        local vehi = GetVehiclePedIsIn(PlayerPedId(),false)
        local v_plate = GetVehicleNumberPlateText(vehi)
        if data['change'] == 'up'then
            ApplySound(0.1, v_plate)
        elseif data['change'] == 'down'then
            ApplySound(-0.1, v_plate)
        end
    end
)

RegisterNUICallback(
    "changeTime",
    function(data)
        local vehi = GetVehiclePedIsIn(PlayerPedId(),false)
        local v_plate = GetVehicleNumberPlateText(vehi)
        if data['change'] == 'forw' then
            if not Config.High3DSound then
                if xSound:soundExists(v_plate) then
                    local timestamp = xSound:getTimeStamp(v_plate)
                    TriggerServerEvent("complete_carplay:ChangePosition", 10, v_plate, timestamp)
                end
            else
                local sound = exports["high_3dsounds"]:getSound(v_plate)
                if sound then
                    local timestamp = exports["high_3dsounds"]:getSoundData(v_plate, "timeStamp")
                    TriggerServerEvent("complete_carplay:ChangePosition", 10, v_plate, timestamp)
                end
            end
        elseif data['change'] == 'prev' then
            if not Config.High3DSound then
                if xSound:soundExists(v_plate) then
                    local timestamp = xSound:getTimeStamp(v_plate)
                    TriggerServerEvent("complete_carplay:ChangePosition", -10, v_plate, timestamp)
                end
            else
                local sound = exports["high_3dsounds"]:getSound(v_plate)
                if sound then
                    local timestamp = exports["high_3dsounds"]:getSoundData(v_plate, "timeStamp")
                    TriggerServerEvent("complete_carplay:ChangePosition", -10, v_plate, timestamp)
                end
            end
        end
    end
)

RegisterNUICallback(
    "resumeSound",
    function(data)
        local vehi = GetVehiclePedIsIn(PlayerPedId(),false)
        local v_plate = GetVehicleNumberPlateText(vehi)
        if not Config.High3DSound then
            if xSound:soundExists(v_plate) then
                if xSound:isPaused(v_plate) then
                    TriggerServerEvent("complete_carplay:ChangeState", true, v_plate)
                end
            end
        else
            local sound = exports["high_3dsounds"]:getSound(v_plate)
            if sound then
                if not exports["high_3dsounds"]:getSoundData(v_plate, "playing") then
                    TriggerServerEvent("complete_carplay:ChangeState", true, v_plate)
                end
            end
        end
    end
)

RegisterNUICallback(
    "stopSound",
    function(data)
        local vehi = GetVehiclePedIsIn(PlayerPedId(),false)
        local v_plate = GetVehicleNumberPlateText(vehi)
        if not Config.High3DSound then
            if xSound:soundExists(v_plate) then
                if not xSound:isPaused(v_plate) then
                    TriggerServerEvent("complete_carplay:ChangeState", false, v_plate)
                end
            end
        else
            local sound = exports["high_3dsounds"]:getSound(v_plate)
            if sound then
                if exports["high_3dsounds"]:getSoundData(v_plate, "playing") then
                    TriggerServerEvent("complete_carplay:ChangeState", false, v_plate)
                end
            end
        end
    end
)

RegisterNUICallback(
    "close",
    function(data)
        ui_open = false
        TriggerScreenblurFadeOut(1000)
        SetNuiFocus(false, false)
        current_focus = false
    end
)

RegisterNUICallback(
    "send_message",
    function(data)
        if Config.PhoneType == 'qbphone' then
            QBCore.Functions.TriggerCallback(
                "complete_carplay:getDate",
                function(date)
                    local curr_date = date
                    QBCore.Functions.TriggerCallback(
                        "complete_carplay:getTime",
                        function(hour)
                            local curr_hour = hour
                            exports["qb-phone"]:SendMessage(data["message"], curr_date, data["receiver"], curr_hour, "message")
                        end
                    )
                end
            )
        elseif Config.PhoneType == 'quasar' then
            TriggerServerEvent('complete_carplay:sendMessageQuasar', data["receiver"], data["message"])
        elseif Config.PhoneType == 'gksphone' then
            TriggerServerEvent('gksphone:gksc:sendMessage', data["receiver"], data["message"])
            --TriggerServerEvent('complete_carplay:sendMessageGks', data["receiver"], data["message"])
        elseif Config.PhoneType == 'highphone' then
            TriggerServerEvent("high_phone:sendMessage", data["receiver"], data["message"], "[]")
        elseif Config.PhoneType == 'npwd' then
            TriggerServerEvent("complete_carplay:sendMessageNpwd", data["receiver"], data["message"])
        elseif Config.PhoneType == 'roadphone' then
            TriggerServerEvent("complete_carplay:sendMessageRoadphone", data["receiver"], data["message"])
        elseif Config.PhoneType == 'lbphone' then
            TriggerServerEvent("complete_carplay:sendMessageLBphone", data["receiver"], data["message"])
        end
    end
)

Citizen.CreateThread(function()
	if Config.Km then
        while true do
            if ui_open then
                SendNUIMessage(
                    {
                        type = "speed",
                        speed = math.ceil(GetEntitySpeed(vehicle_opened) * 3.6)
                    }
                )
            end
            Citizen.Wait(100)
        end
    else
        while true do
            if ui_open then
                SendNUIMessage(
                    {
                        type = "speed",
                        speed = math.ceil(GetEntitySpeed(vehicle_opened) * 2.236936)
                    }
                )
            end
            Citizen.Wait(100)
        end
    end
end)

Citizen.CreateThread(function()
	while true do
        local vehi = GetVehiclePedIsUsing(PlayerPedId())

        if vehi ~= 0 then     
            SetVehicleOilLevel(vehi, 0.05)       
            local tank_healt = (GetVehiclePetrolTankHealth(vehi) / 1000) * 100
            local oil_temp = (GetVehicleOilLevel(vehi)) * 100
            local engine_temp = GetVehicleEngineTemperature(vehi)
            local wheel_healt_1 = IsVehicleTyreBurst(vehi, 0)
            local wheel_healt_2 = IsVehicleTyreBurst(vehi, 1)
            local wheel_healt_3 = IsVehicleTyreBurst(vehi, 4)
            local wheel_healt_4 = IsVehicleTyreBurst(vehi, 5)
            local body_healt = (GetVehicleBodyHealth(vehi) / 1000) * 100
            local dirt_level = (GetVehicleDirtLevel(vehi) / 15) * 100
            
            if wheel_healt_1 or wheel_healt_2 or wheel_healt_3 or wheel_healt_4 then
                lowest_wheel = "YES"
            else
                lowest_wheel = "NO"
            end
            
            SendNUIMessage(
                {
                    type = "updateStatus",
                    status_engine_temp = (math.floor(engine_temp * 10) / 10),
                    status_oil_temp = (math.floor(oil_temp)),
                    status_tank_healt = (math.floor(tank_healt * 10) / 10),
                    status_body_healt = math.floor(body_healt),
                    status_lowest_wheel = lowest_wheel,
                    status_dirt_level = math.floor(dirt_level)
                }
            )
        end
        
        if ui_open then
            Citizen.Wait(10000)
        else
            Citizen.Wait(500)
        end
	end
end)

Citizen.CreateThread(function()
	while true do
        if ui_open then
            local vehi = GetVehiclePedIsIn(PlayerPedId(),false)
            local v_plate = GetVehicleNumberPlateText(vehi)
            if not Config.High3DSound then
                if xSound:soundExists(v_plate) then
                    if xSound:isPlaying(v_plate) then
                        SendNUIMessage(
                            {
                                type = "refresh_timestamp",
                                time = xSound:getTimeStamp(v_plate),
                                max_time = xSound:getMaxDuration(v_plate)
                            }
                        )
                        --[[
    
                            if GetVehicleDoorAngleRatio(vehicle_opened, 0) == 0 and GetVehicleDoorAngleRatio(vehicle_opened, 1) == 0 and GetVehicleDoorAngleRatio(vehicle_opened, 2) == 0 and GetVehicleDoorAngleRatio(vehicle_opened, 3) == 0 then
                                xSound:Distance(vehicle_plate, 3)
                            else
                                xSound:Distance(vehicle_plate, 10)
                            end
                        ]]
                    else
                        SendNUIMessage(
                            {
                                type = "refresh_timestamp",
                                time = 0,
                                max_time = 0
                            }
                        )
                    end
                else
                    SendNUIMessage(
                        {
                            type = "refresh_timestamp",
                            time = 0,
                            max_time = 0
                        }
                    )
                end
            else
                local sound = exports["high_3dsounds"]:getSound(v_plate)
                if sound then
                    if exports["high_3dsounds"]:getSoundData(v_plate, "playing") then
                        SendNUIMessage(
                            {
                                type = "refresh_timestamp",
                                time = exports["high_3dsounds"]:getSoundData(v_plate, "timeStamp"),
                                max_time = exports["high_3dsounds"]:getSoundData(v_plate, "duration")
                            }
                        )
                    else
                        SendNUIMessage(
                            {
                                type = "refresh_timestamp",
                                time = 0,
                                max_time = 0
                            }
                        )
                    end
                else
                    SendNUIMessage(
                        {
                            type = "refresh_timestamp",
                            time = 0,
                            max_time = 0
                        }
                    )
                end
            end
            if vehi ~= vehicle_opened then
                ui_open = false
                TriggerScreenblurFadeOut(1000)
                SetNuiFocus(false, false)
                current_focus = false
            end
        end
        
		Citizen.Wait(1000)
	end
end)

Citizen.CreateThread(function()
    if Config.EnableNavigator then
        while true do
            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
                local waypoint_street_name, waypoint_crossing_road, waypoint_distance, waypoint_time, current_time, average_time, average_speed = nil
                local veh_coords = GetEntityCoords(veh)
                local hours = GetClockHours()
                local minutes = GetClockMinutes()
                if hours < 10 then
                    current_time = '0' .. hours .. ':'
                else
                    current_time = hours .. ':'
                end
                
                if minutes < 10 then
                    current_time = current_time .. '0' .. minutes
                else
                    current_time = current_time .. minutes
                end
                
                if GetFirstBlipInfoId( 8 ) ~= 0 then
                    local waypointBlip = GetFirstBlipInfoId( 8 ) 
                    local coord = GetBlipInfoIdCoord(waypointBlip)
                    local x  = coord.x
                    local y = coord.y
                    local z = coord.z
                    waypoint_street_name, waypoint_crossing_road = GetStreetNameAtCoord(x, y, z)
                    waypoint_distance = (CalculateTravelDistanceBetweenPoints(veh_coords.x, veh_coords.y, veh_coords.z, x, y, z)) / 1000
                    
                    if waypoint_distance then
                        waypoint_distance = math.floor(waypoint_distance * 10) / 10
                    end

                    if not navigator_start_position and not navigator_start_time then
                        navigator_start_position = veh_coords
                        navigator_start_time = GetGameTimer()
                    else
                        waypoint_km_travelled = (CalculateTravelDistanceBetweenPoints(veh_coords.x, veh_coords.y, veh_coords.z, navigator_start_position.x, navigator_start_position.y, navigator_start_position.z)) / 1000
                        date_seconds = GetGameTimer()
                        waypoint_time_travelled = (date_seconds - navigator_start_time) / 1000
                        waypoint_time_travelled = (waypoint_time_travelled / 3600)
                        average_speed = waypoint_km_travelled / waypoint_time_travelled
                        average_time = (waypoint_distance / average_speed) * 60
                    end
                else
                    navigator_start_position = nil
                    navigator_start_time = nil
                end 

                if average_time == math.huge then
                    average_time = 0
                end

                SendNUIMessage(
                    {
                        type = "refresh_main",
                        current_fuel = GetVehicleFuelLevel(veh),
                        waypoint_street = GetStreetNameFromHashKey(waypoint_street_name),
                        waypoint_distance = waypoint_distance,
                        waypoint_time = average_time,
                        waypoint_avg = average_speed,
                        current_time = current_time,
                        ui_open = ui_open
                    }
                )
            end
    
            Citizen.Wait(2000)
        end
    else
        while true do
            if ui_open and veh ~= 0 and GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
                local waypoint_street_name, waypoint_crossing_road, waypoint_distance, waypoint_time, current_time, average_time, average_speed = nil
                local veh_coords = GetEntityCoords(veh)
                local hours = GetClockHours()
                local minutes = GetClockMinutes()
                if hours < 10 then
                    current_time = '0' .. hours .. ':'
                else
                    current_time = hours .. ':'
                end
                
                if minutes < 10 then
                    current_time = current_time .. '0' .. minutes
                else
                    current_time = current_time .. minutes
                end
                
                if GetFirstBlipInfoId( 8 ) ~= 0 then
                    local waypointBlip = GetFirstBlipInfoId( 8 ) 
                    local coord = GetBlipInfoIdCoord(waypointBlip)
                    local x  = coord.x
                    local y = coord.y
                    local z = coord.z
                    waypoint_street_name, waypoint_crossing_road = GetStreetNameAtCoord(x, y, z)
                    waypoint_distance = (CalculateTravelDistanceBetweenPoints(veh_coords.x, veh_coords.y, veh_coords.z, x, y, z)) / 1000
                    
                    if waypoint_distance then
                        waypoint_distance = math.floor(waypoint_distance * 10) / 10
                    end

                    if not navigator_start_position and not navigator_start_time then
                        navigator_start_position = veh_coords
                        navigator_start_time = GetGameTimer()
                    else
                        waypoint_km_travelled = (CalculateTravelDistanceBetweenPoints(veh_coords.x, veh_coords.y, veh_coords.z, navigator_start_position.x, navigator_start_position.y, navigator_start_position.z)) / 1000
                        date_seconds = GetGameTimer()
                        waypoint_time_travelled = (date_seconds - navigator_start_time) / 1000
                        waypoint_time_travelled = (waypoint_time_travelled / 3600)
                        average_speed = waypoint_km_travelled / waypoint_time_travelled
                        average_time = (waypoint_distance / average_speed) * 60
                    end
                else
                    navigator_start_position = nil
                    navigator_start_time = nil
                end 
        
                if average_time == math.huge then
                    average_time = 0
                end

                SendNUIMessage(
                    {
                        type = "refresh_main",
                        current_fuel = GetVehicleFuelLevel(veh),
                        waypoint_street = GetStreetNameFromHashKey(waypoint_street_name),
                        waypoint_distance = waypoint_distance,
                        waypoint_time = average_time,
                        waypoint_avg = average_speed,
                        current_time = current_time,
                        ui_open = true
                    }
                )
            end
    
            Citizen.Wait(2000)
        end
    end
end)

Citizen.CreateThread(function()
    if Config.DisplayCurrentStreet then
        while true do
            local veh_in = GetVehiclePedIsIn(PlayerPedId(), false)
            if veh_in ~= 0 then
                if GetPedInVehicleSeat(veh_in, -1) == PlayerPedId() then
                    local waypoint_dir = nil
                    local veh_coords = GetEntityCoords(veh_in)
                    local street_name, crossing_road = GetStreetNameAtCoord(veh_coords.x, veh_coords.y, veh_coords.z)
                    
                    if GetFirstBlipInfoId( 8 ) ~= 0 then
                        local waypointBlip = GetFirstBlipInfoId( 8 ) 
                        local coord = GetBlipInfoIdCoord(waypointBlip)
                        local x  = coord.x
                        local y = coord.y
                        local z = coord.z
        
                        local retval, direction, vehicle, distToNxJunction = GenerateDirectionsToCoord(x, y, z, 0)
                        waypoint_dir = direction
                    end
                    SendNUIMessage(
                        {
                            type = "setCStreetWaypoint",
                            bool = true
                        }
                    )
                    SendNUIMessage(
                        {
                            type = "refresh_direction",
                            current_street = GetStreetNameFromHashKey(street_name),
                            waypoint_direction = waypoint_dir,
                            ui_open = ui_open
                        }
                    )
                else
                    SendNUIMessage(
                        {
                            type = "setCStreetWaypoint",
                            bool = false
                        }
                    )
                    SendNUIMessage(
                        {
                            type = "hideNavigator",
                            bool = true
                        }
                    )
                    if trunk_camera then
                        RemoveTrunkCamera()
                    end
                end
            else
                SendNUIMessage(
                    {
                        type = "setCStreetWaypoint",
                        bool = false
                    }
                )
                SendNUIMessage(
                    {
                        type = "hideNavigator",
                        bool = true
                    }
                )
                if trunk_camera then
                    RemoveTrunkCamera()
                end
            end
    
            Citizen.Wait(500)
        end
    else
        while true do
            local veh_in = GetVehiclePedIsIn(PlayerPedId(), false)
            if veh_in ~= 0 then
                if GetPedInVehicleSeat(veh_in, -1) == PlayerPedId() then
                    if ui_open then
                        local waypoint_dir = nil
                        local veh_coords = GetEntityCoords(veh_in)
                        local street_name, crossing_road = GetStreetNameAtCoord(veh_coords.x, veh_coords.y, veh_coords.z)
            
                        SendNUIMessage(
                            {
                                type = "refresh_direction",
                                current_street = GetStreetNameFromHashKey(street_name),
                                waypoint_direction = waypoint_dir,
                                ui_open = true
                            }
                        )
                    end
                else
                    SendNUIMessage(
                        {
                            type = "setCStreetWaypoint",
                            bool = false
                        }
                    )
                    SendNUIMessage(
                        {
                            type = "hideNavigator",
                            bool = true
                        }
                    )
                    if trunk_camera then
                        RemoveTrunkCamera()
                    end
                end
            else
                SendNUIMessage(
                    {
                        type = "setCStreetWaypoint",
                        bool = false
                    }
                )
                SendNUIMessage(
                    {
                        type = "hideNavigator",
                        bool = true
                    }
                )
                local v_plate = GetVehicleNumberPlateText(veh_in)
                if trunk_camera then
                    RemoveTrunkCamera()
                end
            end
    
            Citizen.Wait(500)
        end
    end
end)

RegisterNUICallback(
    "setRadio",
    function(data)
        local radio_index = GetPlayerRadioStationIndex()
        if data['change'] == 'next' then
            if radio_name == 'OFF' then
                radio_name = 'RADIO_01_CLASS_ROCK'
                radio_playing = true
            else
                radio_name = GetRadioStationName(GetPlayerRadioStationIndex() + 1)
            end
            SetVehRadioStation(vehicle_opened, radio_name)
        else
            radio_name = GetRadioStationName(radio_index - 1)
            if radio_name == 'OFF' then
                radio_playing = false
            end
            SetVehRadioStation(vehicle_opened, radio_name)
        end
        SendNUIMessage(
            {
                type = "refresh_radio",
                radio_name = radio_name,
                radio_playing = radio_playing
            }
        )
    end
)

RegisterNUICallback(
    "playPauseRadio",
    function(data)
        if data['change'] == 'play' then
            if radio_name == 'OFF' then
                radio_name = 'RADIO_01_CLASS_ROCK'
            end
            SetVehRadioStation(vehicle_opened, radio_name)
            radio_playing = true
        else
            SetVehRadioStation(vehicle_opened, 'OFF')
            radio_playing = false
        end
        SendNUIMessage(
            {
                type = "refresh_radio",
                radio_name = radio_name,
                radio_playing = radio_playing
            }
        )
    end
)

RegisterNUICallback(
    "setSetting",
    function(data)
        local setting = data["setting"]
        local bool = data["bool"]
        local car = QBCore.Functions.GetVehicleProperties(vehicle_opened)
        if setting == "seat1" or setting == "seat2" or setting == "seat3" or setting == "seat4" then
            SetSetting(setting, bool)
        else
            TriggerServerEvent('complete_carplay:setSetting', setting, bool, car)
            SetSetting(setting, bool)
            if Config.Debug then
                print('[DEBUG] Set setting: ' .. setting .. ' to ', bool)
            end
            Citizen.Wait(1000)
            QBCore.Functions.TriggerCallback(
                "complete_carplay:getSettings",
                function(settings_data)
                    SendNUIMessage(
                        {
                            type = "updateSettings",
                            settings = json.encode(settings_data)
                        }
                    )
                end,
                car
            )
        end
    end
)

function SetSetting(setting, bool)
    if setting == "headlight" then
        if bool then
            SetVehicleLights(vehicle_opened, 2)
        else
            SetVehicleLights(vehicle_opened, 1)
            ToggleVehicleMod(vehicle_opened, 22, true)
        end
    elseif setting == "interior" then
        if bool then
            SetVehicleInteriorlight(vehicle_opened, true)
        else
            SetVehicleInteriorlight(vehicle_opened, false)
        end
    elseif setting == "windows" then
        if bool then
            RollDownWindow(vehicle_opened, 0)
            RollDownWindow(vehicle_opened, 1)
            RollDownWindow(vehicle_opened, 2)
            RollDownWindow(vehicle_opened, 3)
        else
            RollUpWindow(vehicle_opened, 0)
            RollUpWindow(vehicle_opened, 1)
            RollUpWindow(vehicle_opened, 2)
            RollUpWindow(vehicle_opened, 3)
        end
    elseif setting == "trunk" then
        if bool then
            SetVehicleDoorOpen(vehicle_opened, 5, false)
        else
            SetVehicleDoorShut(vehicle_opened, 5, false)
        end
    elseif setting == "door1" then
        if bool then
            SetVehicleDoorOpen(vehicle_opened, 0, false)
        else
            if GetVehicleDoorAngleRatio(vehicle_opened, 0) > 0 then
                SetVehicleDoorShut(vehicle_opened, 0, false)
            end
        end
    elseif setting == "door2" then
        if bool then
            SetVehicleDoorOpen(vehicle_opened, 1, false)
        else
            if GetVehicleDoorAngleRatio(vehicle_opened, 1) > 0 then
                SetVehicleDoorShut(vehicle_opened, 1, false)
            end
        end
    elseif setting == "door3" then
        if bool then
            SetVehicleDoorOpen(vehicle_opened, 2, false)
        else
            if GetVehicleDoorAngleRatio(vehicle_opened, 2) > 0 then
                SetVehicleDoorShut(vehicle_opened, 2, false)
            end
        end
    elseif setting == "door4" then
        if bool then
            SetVehicleDoorOpen(vehicle_opened, 3, false)
        else
            if GetVehicleDoorAngleRatio(vehicle_opened, 3) > 0 then
                SetVehicleDoorShut(vehicle_opened, 3, false)
            end
        end
    elseif setting == "lock" then
        if bool then
            SetVehicleDoorsLocked(vehicle_opened, 4)
        else
            SetVehicleDoorsLocked(vehicle_opened, 0)
        end
    elseif setting == "cruise" then
        if bool then
            cruise_active = true
            if not cruise_speed then
                cruise_speed = GetEntitySpeed(vehicle_opened)
            end
        else
            SetVehicleMaxSpeed(vehicle_opened, 0.0)
            cruise_speed = nil
            cruise_active = false
        end
    elseif setting == "seat1" then
        if IsVehicleSeatFree(vehicle_opened, -1) then
            SetPedIntoVehicle(PlayerPedId(), vehicle_opened, -1)
        end
    elseif setting == "seat2" then
        if IsVehicleSeatFree(vehicle_opened, 0) then
            SetPedIntoVehicle(PlayerPedId(), vehicle_opened, 0)
        end
    elseif setting == "seat3" then
        if IsVehicleSeatFree(vehicle_opened, 1) then
            SetPedIntoVehicle(PlayerPedId(), vehicle_opened, 1)
        end
    elseif setting == "seat4" then
        if IsVehicleSeatFree(vehicle_opened, 2) then
            SetPedIntoVehicle(PlayerPedId(), vehicle_opened, 2)
        end
    elseif setting == "hColor" then
        ToggleVehicleMod(vehicle_opened, 22, true)
        SetVehicleXenonLightsColour(vehicle_opened, tonumber(bool))
        headlight_color = bool
    end
end

Citizen.CreateThread(function()
	while true do
        if cruise_active then
            SetVehicleMaxSpeed(vehicle_opened, cruise_speed)
        end
		Citizen.Wait(10)
	end
end)

function RemoveTrunkCamera()
    SetNuiFocus(false, false)
    current_focus = false
    SendNUIMessage(
        {
            type = "trunk_camera",
            open = false
        }
    )
    
    ClearFocus()
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam, false)
    cam = nil
    trunk_camera = false
end

function TrunkCameraEvent()
    if trunk_camera then
        RemoveTrunkCamera()
    else
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        vehicle_opened = vehicle
        SetNuiFocus(false, false)
        current_focus = false
        SendNUIMessage(
            {
                type = "trunk_camera",
                open = true
            }
        )
        trunk_camera = true

        local player = PlayerPedId()
        cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", GetEntityCoords(player), 0, 0, 0, 120.0)
        if GetEntityBoneIndexByName(vehicle_opened, 'platelight') == -1 then
            AttachCamToVehicleBone(cam, vehicle_opened, GetEntityBoneIndexByName(vehicle_opened, 'exhaust'), false, 5, 0, 0, 0, 0, 0, false)
        else
            AttachCamToVehicleBone(cam, vehicle_opened, GetEntityBoneIndexByName(vehicle_opened, 'platelight'), false, 5, 0, 0, 0, 0, 0, false)
        end
        SetCamActive(cam, true)
        RenderScriptCams(true, true, 100, true, false)
        local cam_coord = GetWorldPositionOfEntityBone(vehicle_opened, GetEntityBoneIndexByName(vehicle_opened, 'platelight'))
        local cam_rot = GetEntityRotation(vehicle_opened)
        while true do
            SetCamRot(cam, cam_rot.x, cam_rot.y, GetEntityHeading(player) - 180 , 2)
            Citizen.Wait(13)
        end
    end
end

RegisterKeyMapping(Config.OpenTrunkCameraCommand, 'Open trunk camera key', 'keyboard', Config.OpenTrunkCameraKey)

RegisterCommand(Config.OpenTrunkCameraCommand, function()
    local get_veh_in = GetVehiclePedIsIn(PlayerPedId(), false)
    if get_veh_in and GetPedInVehicleSeat(get_veh_in, -1) == PlayerPedId() then
        local car = QBCore.Functions.GetVehicleProperties(get_veh_in)
        
        if not Config.NoInstall then
            QBCore.Functions.TriggerCallback(
                "complete_carplay:checkCarplay",
                function(result)
                    if result then
                        TrunkCameraEvent()
                    end
                end,
                car
            )
        else
            TrunkCameraEvent()
        end
    end
end)

RegisterNUICallback(
    "trunkCamera",
    function(data)
        ui_open = false
        TrunkCameraEvent()
    end
)


/*
=========================================================================




                                AUDIO




=========================================================================
*/

RegisterNetEvent("complete_carplay:SendData")
AddEventHandler("complete_carplay:SendData", function(data)
    music_zones = data
    for i = 1, #music_zones do
		local v = music_zones[i]
		if v.isplaying then
            if not Config.High3DSound then
                if xSound:soundExists(v.name) then
                    xSound:Destroy(v.name)
                end
                xSound:PlayUrlPos(v.name, v.deflink, v.volume, v.coords, false,
                {
                    onPlayStart = function(event)
                        if xSound:soundExists(v.name) then
                            xSound:setTimeStamp(v.name, v.deftime)
                            xSound:Distance(v.name, v.range)
                        end
                    end,
                    onPlayEnd = function(event)
                        if #v.queue > 0 then
                            local next_url = v.queue[1]
                            table.remove(v.queue, 1)
                            local vehi = GetVehiclePedIsIn(PlayerPedId(),false)
                            local v_plate = GetVehicleNumberPlateText(vehi)
                            TriggerServerEvent("complete_carplay:SetQueue", v.name, v.queue, next_url)
                        end
                    end,
                })
            else
                local sound = exports["high_3dsounds"]:getSound(v.name)
                if sound then
                    sound.destroy()
                end
                sound = exports["high_3dsounds"]:Play3DPos(
                    v.name, -- uniqueId
                    v.coords, -- position
                    10.0, -- distance
                    v.deflink, -- sound URL/file name
                    v.volume, -- volume
                    false -- looped
                )
                sound.addEventListener("onPlay", function()
                    sound.modify("timeStamp", v.deftime)
                    sound.modify("distance", v.range)
                end)
                sound.addEventListener("onFinished", function()
                    if #v.queue > 0 then
                        local next_url = v.queue[1]
                        table.remove(v.queue, 1)
                        local vehi = GetVehiclePedIsIn(PlayerPedId(),false)
                        local v_plate = GetVehicleNumberPlateText(vehi)
                        TriggerServerEvent("complete_carplay:SetQueue", v.name, v.queue, next_url)
                    end
                end)
            end
			if v.popo then
				table.insert(SoundsPlaying, i)
				StartMusicLoop(i)
			end
		end
    end
end)

function SetUrl(url, nid)
	local nome = nid
	if url then
		local encontrad = false
		for i = 1, #music_zones do
			local v = music_zones[i]
			if v.name == nome then
				encontrad = true
			end
		end
		if encontrad then
			local vehdata = {}
			vehdata.name = nome
			vehdata.link = url
			vehdata.queue = datasoundinfo.queue
			if IsPedInAnyVehicle(PlayerPedId(), false) then
				vehdata.popo = NetworkGetNetworkIdFromEntity(GetVehiclePedIsIn(PlayerPedId(),false))
			end
			TriggerServerEvent("complete_carplay:ModifyURL", vehdata)
		else
			if IsPedInAnyVehicle(PlayerPedId(), false) then
				local veh = GetVehiclePedIsIn(PlayerPedId(),false)
				local cordsveh = GetEntityCoords(veh)
				local netid = NetworkGetNetworkIdFromEntity(veh)
				local vehdata = {}
				vehdata.plate = nome
				vehdata.coords = cordsveh
				vehdata.link = url
				vehdata.popo = netid
				vehdata.volume = datasoundinfo.volume
				vehdata.queue = datasoundinfo.queue
				TriggerServerEvent("complete_carplay:AddVehicle", vehdata)
			end
		end
	end
end

RegisterNetEvent("complete_carplay:AddVehicle")
AddEventHandler("complete_carplay:AddVehicle", function(data)
	table.insert(music_zones, data)
	local v = data
    if not Config.High3DSound then
        if xSound:soundExists(v.name) then
            xSound:Destroy(v.name)
        end
    
        xSound:PlayUrlPos(v.name, v.deflink, v.volume, v.coords, false, {
            onPlayStart = function(event)
                if xSound:soundExists(v.name) then
                    xSound:setTimeStamp(v.name, v.deftime)
                    xSound:Distance(v.name, v.range)
                end
            end,
            onPlayEnd = function(event)
                if #v.queue > 0 then
                    local next_url = v.queue[1]
                    table.remove(v.queue, 1)
                    local vehi = GetVehiclePedIsIn(PlayerPedId(),false)
                    local v_plate = GetVehicleNumberPlateText(vehi)
                    TriggerServerEvent("complete_carplay:SetQueue", v.name, v.queue, next_url)
                end
            end,
        })
    else
        local sound = exports["high_3dsounds"]:getSound(v.name)
        if sound then
            sound.destroy()
        end
        sound = exports["high_3dsounds"]:Play3DPos(
            v.name, -- uniqueId
            v.coords, -- position
            10.0, -- distance
            v.deflink, -- sound URL/file name
            v.volume, -- volume
            false -- looped
        )
        sound.addEventListener("onPlay", function()
            sound.modify("timeStamp", v.deftime)
            sound.modify("distance", v.range)
        end)
        sound.addEventListener("onFinished", function()
            if #v.queue > 0 then
                local next_url = v.queue[1]
                table.remove(v.queue, 1)
                local vehi = GetVehiclePedIsIn(PlayerPedId(),false)
                local v_plate = GetVehicleNumberPlateText(vehi)
                TriggerServerEvent("complete_carplay:SetQueue", v.name, v.queue, next_url)
            end
        end)
    end
	table.insert(SoundsPlaying, #music_zones)
	StartMusicLoop(#music_zones)
end)

local plpedloop
local pploop
local coordsped

Citizen.CreateThread(function()
	local poschanged = true
	while true do
		Wait(10)
		plpedloop = PlayerPedId()
		pploop = GetVehiclePedIsIn(plpedloop,false)
		coordsped = GetEntityCoords(plpedloop)
	end
end)

function StartMusicLoop(i)
    if not Config.High3DSound then
        while not xSound:soundExists(music_zones[i].name) do
            Wait(10)
        end
    else
        while not exports["high_3dsounds"]:getSound(music_zones[i].name) do
            Wait(10)
        end
    end
	Citizen.CreateThread(function()
		local poschanged = true
		while true do
			local sleep = 2
			local v = music_zones[i]
			if v == nil then
				return
			end
            if not Config.High3DSound then
                if v.isplaying and xSound:soundExists(v.name) then
                    local carrofound = false
                    if NetworkDoesEntityExistWithNetworkId(v.popo) then
                        local carro = NetworkGetEntityFromNetworkId(v.popo)
                        if GetEntityType(carro) == 2 then
                            if GetVehicleNumberPlateText(carro) == v.name then
                                carrofound = true
                                local cordsveh = GetEntityCoords(carro)
                                local geraldist = #(cordsveh - coordsped)
                                if geraldist <= v.range + 50 then
                                    local avolume = xSound:getVolume(v.name)
                                    local dina = xSound:isDynamic(v.name)
                                    local getpos = v.coords
                                    local getposdif = #(getpos - cordsveh)
                                    if avolume <= 0.001 then
                                        sleep = 1000
                                    end
                                    if pploop == carro then
                                        if not dina then
                                            xSound:setSoundDynamic(v.name, true)
                                        end
                                        if avolume ~= v.volume then
                                            xSound:setVolume(v.name, v.volume)
                                        end
                                        if getposdif >= 2.0 or poschanged then
                                            poschanged = false
                                            v.coords = cordsveh
                                            xSound:Position(v.name, cordsveh)
                                        else
                                            --sleep = sleep + 150
                                            sleep = 100
                                        end
                                    else
                                        if not dina then
                                            xSound:setSoundDynamic(v.name, true)
                                        end
                                        if avolume ~= v.volume then
                                            xSound:setVolumeMax(v.name, v.volume)
                                        end
                                        if geraldist >= v.range + 20 then
                                            sleep = (geraldist * 100) / 3
                                        end
                                        if sleep <= 10000 then
                                            local speedcar = GetEntitySpeed(carro) * 3.6
                                            if speedcar <= 2.0 then
                                                sleep = sleep + 2500
                                            elseif speedcar <= 5.0 then
                                                sleep = sleep + 1000
                                            elseif speedcar <= 10.0 then
                                                sleep = sleep + 100
                                            end
                                        end
                                        if getposdif >= 1.0 or poschanged then
                                            poschanged = false
                                            v.coords = cordsveh
                                            xSound:Position(v.name, cordsveh)
                                        else
                                            sleep = sleep + 150
                                        end
                                    end
                                else
                                    if not xSound:isDynamic(v.name) then
                                        xSound:setSoundDynamic(v.name, true)
                                    end
                                    xSound:setVolumeMax(v.name, 0.0)
                                    if not poschanged then
                                        xSound:Position(v.name, vector3(350.0, 0.0, -150.0))
                                        poschanged = true
                                    end
                                    sleep = (geraldist * 100) / 2
                                end
                            end
                        end
                    end
                    if not carrofound then
                        if not xSound:isDynamic(v.name) then
                            xSound:setSoundDynamic(v.name,true)
                        end
                        --xSound:setVolumeMax(v.name,0.0)
                        if not poschanged then
                            xSound:Position(v.name, vector3(350.0,0.0,-150.0))
                            poschanged = true
                        end
                        Wait(5000)
                    end
                else
                    if xSound:soundExists(v.name) then
                        if not xSound:isDynamic(v.name) then
                            xSound:setSoundDynamic(v.name,true)
                        end
                        xSound:setVolumeMax(v.name,0.0)
                        if not poschanged then
                            xSound:Position(v.name, vector3(350.0,0.0,-150.0))
                            poschanged = true
                        end
                    end
                    v.isplaying = false
                    for j = 1, #SoundsPlaying do
                        local k = SoundsPlaying[j]
                        if k == i then
                            table.remove(SoundsPlaying, j)
                        end
                    end
                    break
                end
                if sleep > 10000 then
                    sleep = 10000
                end

                Wait(sleep)
            else
                local sound = exports["high_3dsounds"]:getSound(v.name)
                if v.isplaying and sound then
                    local carrofound = false
                    if NetworkDoesEntityExistWithNetworkId(v.popo) then
                        local carro = NetworkGetEntityFromNetworkId(v.popo)
                        if GetEntityType(carro) == 2 then
                            if GetVehicleNumberPlateText(carro) == v.name then
                                carrofound = true
                                local cordsveh = GetEntityCoords(carro)
                                local geraldist = #(cordsveh - coordsped)
                                if geraldist <= v.range + 50 then
                                    local avolume = exports["high_3dsounds"]:getSoundData(v.name, "timeStamp")
                                    local dina = true
                                    local getpos = v.coords
                                    local getposdif = #(getpos - cordsveh)
                                    if avolume <= 0.001 then
                                        sleep = 1000
                                    end
                                    if pploop == carro then
                                        if avolume ~= v.volume then
                                            sound.modify("volume", v.volume)
                                        end
                                        if getposdif >= 2.0 or poschanged then
                                            poschanged = false
                                            v.coords = cordsveh
                                            sound.modify("position", cordsveh)
                                        else
                                            --sleep = sleep + 150
                                            sleep = 100
                                        end
                                    else
                                        if avolume ~= v.volume then
                                            sound.modify("volume", v.volume)
                                        end
                                        if geraldist >= v.range + 20 then
                                            sleep = (geraldist * 100) / 3
                                        end
                                        if sleep <= 10000 then
                                            local speedcar = GetEntitySpeed(carro) * 3.6
                                            if speedcar <= 2.0 then
                                                sleep = sleep + 2500
                                            elseif speedcar <= 5.0 then
                                                sleep = sleep + 1000
                                            elseif speedcar <= 10.0 then
                                                sleep = sleep + 100
                                            end
                                        end
                                        if getposdif >= 1.0 or poschanged then
                                            poschanged = false
                                            v.coords = cordsveh
                                            sound.modify("position", cordsveh)
                                        else
                                            sleep = sleep + 150
                                        end
                                    end
                                else
                                    sound.modify("volume", 0.0)
                                    if not poschanged then
                                        sound.modify("position", vector3(350.0, 0.0, -150.0))
                                        poschanged = true
                                    end
                                    sleep = (geraldist * 100) / 2
                                end
                            end
                        end
                    end
                    if not carrofound then
                        if not poschanged then
                            sound.modify("position", vector3(350.0, 0.0, -150.0))
                            poschanged = true
                        end
                        Wait(5000)
                    end
                else
                    if exports["high_3dsounds"]:getSound(v.name) then
                        sound.modify("volume", 0.0)
                        if not poschanged then
                            sound.modify("position", vector3(350.0, 0.0, -150.0))
                            poschanged = true
                        end
                    end
                    v.isplaying = false
                    for j = 1, #SoundsPlaying do
                        local k = SoundsPlaying[j]
                        if k == i then
                            table.remove(SoundsPlaying, j)
                        end
                    end
                    break
                end
                if sleep > 10000 then
                    sleep = 10000
                end
                Wait(sleep)
            end
		end
	end)
end

RegisterNetEvent("complete_carplay:ChangeState")
AddEventHandler("complete_carplay:ChangeState", function(tipo, nome)
    if not Config.High3DSound then
        if tipo and xSound:soundExists(nome) then
            xSound:Resume(nome)
        elseif xSound:soundExists(nome) then
            xSound:Pause(nome)
        end
    else
        local sound = exports["high_3dsounds"]:getSound(nome)
        if tipo and sound then
            sound.modify("volume", true)
        elseif sound then
            sound.modify("playing", false)
        end
    end
	local iss = nil
	for i = 1, #music_zones do
		local v = music_zones[i]
		if v.name == nome then
			if v.popo then
				iss = i
			end
			v.isplaying = tipo
		end
	end
	if tipo and iss then
		table.insert(SoundsPlaying, iss)
		StartMusicLoop(iss)
	elseif iss then
		for i = 1, #SoundsPlaying do
			local v = SoundsPlaying[i]
			if v == iss then
				table.remove(SoundsPlaying, i)
			end
		end
	end
end)

RegisterNetEvent("complete_carplay:ChangeLoop")
AddEventHandler("complete_carplay:ChangeLoop", function(tipo, nome)
    if not Config.High3DSound then
        if xSound:soundExists(nome) then
            xSound:setSoundLoop(nome,tipo)
        end
    else
        local sound = exports["high_3dsounds"]:getSound(v_plate)
        if sound then

        end
    end
	for i = 1, #music_zones do
		local v = music_zones[i]
		if v.name == nome then
			v.loop = tipo
		end
	end
end)


RegisterNetEvent("complete_carplay:ChangePosition")
AddEventHandler("complete_carplay:ChangePosition", function(quanti, nome)
	local tempapply
	for i = 1, #music_zones do
		local v = music_zones[i]
		if v.name == nome then
            local timestamp = nil
            if not Config.High3DSound then
                timestamp = xSound:getTimeStamp(nome)
            else
                local sound = exports["high_3dsounds"]:getSound(nome)
                if sound then
                    timestamp = exports["high_3dsounds"]:getSoundData(nome, "timeStamp")
                end
            end
			v.deftime = timestamp + quanti
			if v.deftime < 0 then
				v.deftime = 0
			end
			tempapply = v.deftime
		end
	end
    if not Config.High3DSound then
        if xSound:soundExists(nome) then
            xSound:setTimeStamp(nome, tempapply)
        end
    else
        local sound = exports["high_3dsounds"]:getSound(nome)
        if sound then
            sound.modify("timeStamp", tempapply)
        end
    end
end)

function ApplySound(quanti, plate)
	local exis = false
	local som = datasoundinfo.volume
    if not Config.High3DSound then
        if xSound:soundExists(plate) and xSound:isPlaying(plate) then
            exis = true
            som = xSound:getVolume(plate)
            datasoundinfo.volume = som
        end
    else
        local sound = exports["high_3dsounds"]:getSound(plate)
        if sound and exports["high_3dsounds"]:getSoundData(plate, "playing") then
            exis = true
            som = exports["high_3dsounds"]:getSoundData(plate, "volume")
            datasoundinfo.volume = som
        end
    end
	local vadi = som + quanti
	if vadi <= 1.01 and vadi >= -0.001 and exis then
		if vadi < 0.005 then
			vadi = 0.0
		end
		datasoundinfo.volume = vadi
		TriggerServerEvent("complete_carplay:ChangeVolume", quanti, plate)
	end
end

RegisterNetEvent("complete_carplay:ChangeVolume")
AddEventHandler("complete_carplay:ChangeVolume", function(som, range, nome)
	local carroe
	local crds
    for i = 1, #music_zones do
        local v = music_zones[i]
        if nome == v.name then
            v.volume = som
            v.range = range
			carroe = v.popo
			crds = v.coords
        end
    end
    if not Config.High3DSound then
        if xSound:soundExists(nome) then
            xSound:Distance(nome,range)
            if not carroe and crds then
                xSound:setVolumeMax(nome, som)
            end
        end
    else
        local sound = exports["high_3dsounds"]:getSound(nome)
        if sound then
            sound.modify("distance", range)
            if not carroe and crds then
                sound.modify("volume", som)
            end
        end
    end
end)


RegisterNetEvent("complete_carplay:AddToQueue")
AddEventHandler("complete_carplay:AddToQueue", function(nome, url)
	for i = 1, #music_zones do
		local v = music_zones[i]
		if v.name == nome then
			table.insert(v.queue, url)
            datasoundinfo.queue = v.queue
            SendNUIMessage(
                {
                    type = "refresh_queue",
                    queue = json.encode(datasoundinfo.queue)
                }
            )
		end
	end
end)

RegisterNetEvent("complete_carplay:SetQueue")
AddEventHandler("complete_carplay:SetQueue", function(nome, queue, url)
	local tempapply
	for i = 1, #music_zones do
		local v = music_zones[i]
		if v.name == nome then
			v.queue = queue
            datasoundinfo.queue = v.queue
            SendNUIMessage(
                {
                    type = "queue",
                    url = url,
                    queue = json.encode(datasoundinfo.queue)
                }
            )

            SetUrl(url, nome)
		end
	end
end)

RegisterNetEvent("complete_carplay:RemovePlayer")
AddEventHandler("complete_carplay:RemovePlayer", function(nome)
	for i = 1, #music_zones do
		local v = music_zones[i]
		if v.name == nome then
            if not Config.High3DSound then
                if xSound:soundExists(v.name) then
                    xSound:Destroy(v.name)       
                    table.remove(music_zones, i)
                end
            else
                local sound = exports["high_3dsounds"]:getSound(v.name)
                if sound then
                    sound.destroy()
                    table.remove(music_zones, i)
                end
            end
		end
	end
end)

RegisterNetEvent("complete_carplay:ModifyURL")
AddEventHandler("complete_carplay:ModifyURL", function(data)
	local v = data
	local avancartodos = v.volume
    if not Config.High3DSound then
        if xSound:soundExists(v.name) then
            if not xSound:isDynamic(v.name) then
                xSound:setSoundDynamic(v.name, true)
            end
            Wait(100)
            xSound:setVolumeMax(v.name, 0.0)
            xSound:setSoundURL(v.name, v.deflink)
            Wait(100)
            xSound:Position(v.name, v.coords)
            Wait(800)
            xSound:setTimeStamp(v.name, 0)
            xSound:setVolumeMax(v.name, avancartodos)
        else
            xSound:PlayUrlPos(v.name, v.deflink, avancartodos, v.coords, v.loop, {
                onPlayStart = function(event)
                    xSound:setTimeStamp(v.name, v.deftime)
                    xSound:Distance(v.name,v.range)
                end,
                onPlayEnd = function(event)
                    if #v.queue > 0 then
                        local next_url = v.queue[1]
                        table.remove(v.queue, 1)
                        local vehi = GetVehiclePedIsIn(PlayerPedId(),false)
                        local v_plate = GetVehicleNumberPlateText(vehi)
                        TriggerServerEvent("complete_carplay:SetQueue", v.name, v.queue, next_url)
                    end
                end,
            })
        end
    else
        local sound = exports["high_3dsounds"]:getSound(v.name)
        if sound then
            sound.destroy()
        end
        sound = exports["high_3dsounds"]:Play3DPos(
            v.name, -- uniqueId
            v.coords, -- position
            10.0, -- distance
            v.deflink, -- sound URL/file name
            avancartodos, -- volume
            false -- looped
        )
        sound.addEventListener("onPlay", function()
            sound.modify("timeStamp", v.deftime)
            sound.modify("distance", v.range)
        end)
        sound.addEventListener("onFinished", function()
            if #v.queue > 0 then
                local next_url = v.queue[1]
                table.remove(v.queue, 1)
                local vehi = GetVehiclePedIsIn(PlayerPedId(),false)
                local v_plate = GetVehicleNumberPlateText(vehi)
                TriggerServerEvent("complete_carplay:SetQueue", v.name, v.queue, next_url)
            end
        end)
    end
	local iss = nil
	for i = 1, #music_zones do
		local b = music_zones[i]
		if v.name == b.name then
			if b.popo then
				iss = i
			end
			b.deflink = v.deflink
			b.deftime = 0
			b.isplaying = v.isplaying
			b.queue = v.queue
			if v.popo then
				b.popo = v.popo
			end
		end
	end
	local encontrads = false
	for i = 1, #SoundsPlaying do
		local v = SoundsPlaying[i]
		if v == iss then
			encontrads = true
		end
	end
	if not encontrads and iss then
		table.insert(SoundsPlaying, iss)
		StartMusicLoop(iss)
	end
end)