if Config.CheckScriptUpdates then
    Citizen.CreateThread( function()
        local resourceName = "complete_daily_bonus (".. GetCurrentResourceName() ..")"
        local current = GetResourceMetadata(GetCurrentResourceName(), "version")
        
        function Check(err, response)
            local latest = json.decode(response).tag_name
            if not latest then return end
    
            if current ~= latest then
                Wait(2000)
                print("^0---------------------------------------^0")
                print("^3" .. resourceName .. " it's not up to date!")
                print("^3Your version: ^2" .. current .. "^0")
                print("^3Latest version: ^2" .. latest .. "^0")
                print("^0---------------------------------------^0")
            else
                Wait(2000)
                print("^0" .. resourceName .. " has the latest version")
            end
        end
        
        PerformHttpRequest("https://api.github.com/repos/Michele-Arici/complete_daily_bonus/releases/latest", Check, "GET")
    end)
end
