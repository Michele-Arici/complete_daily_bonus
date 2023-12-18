### Contact
- Discord: https://discord.gg/Y65Muq24rA

### Requirements
- QBCORE
- xSound (free on github / [https://github.com/Xogy/xsound])

### Installation
1) Drag & drop the qb_complete_carplay into your `resources` server folder.
2) Configure the config file.
3) Import the SQL file into your database.
4) Install and ensure the requirements.
5) Add export on qb-phone (see below OPTIONAL)
6) Add `start qb_complete_carplay` to your server config.

### Qb-phone export
1) Open qb-phone folder
2) Open `qb-phone/client/main.lua`
3) `Add this to the bottom of the page`:
    function SendMessage(message, date, number, time, type)

        local ChatMessage = message
        local ChatDate = date
        local ChatNumber = number
        local ChatTime = time
        local ChatType = type
        local Ped = PlayerPedId()
        local Pos = GetEntityCoords(Ped)
        local NumberKey = GetKeyByNumber(ChatNumber)
        local ChatKey = GetKeyByDate(NumberKey, ChatDate)
        if PhoneData.Chats[NumberKey] ~= nil then
            if(PhoneData.Chats[NumberKey].messages == nil) then
                PhoneData.Chats[NumberKey].messages = {}
            end
            if PhoneData.Chats[NumberKey].messages[ChatKey] ~= nil then
                if ChatType == "message" then
                    PhoneData.Chats[NumberKey].messages[ChatKey].messages[#PhoneData.Chats[NumberKey].messages[ChatKey].messages+1] = {
                        message = ChatMessage,
                        time = ChatTime,
                        sender = PhoneData.PlayerData.citizenid,
                        type = ChatType,
                        data = {},
                    }
                end
                TriggerServerEvent('qb-phone:server:UpdateMessages', PhoneData.Chats[NumberKey].messages, ChatNumber, false)
                NumberKey = GetKeyByNumber(ChatNumber)
                ReorganizeChats(NumberKey)
            else
                PhoneData.Chats[NumberKey].messages[#PhoneData.Chats[NumberKey].messages+1] = {
                    date = ChatDate,
                    messages = {},
                }
                ChatKey = GetKeyByDate(NumberKey, ChatDate)
                if ChatType == "message" then
                    PhoneData.Chats[NumberKey].messages[ChatKey].messages[#PhoneData.Chats[NumberKey].messages[ChatKey].messages+1] = {
                        message = ChatMessage,
                        time = ChatTime,
                        sender = PhoneData.PlayerData.citizenid,
                        type = ChatType,
                        data = {},
                    }
                end
                TriggerServerEvent('qb-phone:server:UpdateMessages', PhoneData.Chats[NumberKey].messages, ChatNumber, true)
                NumberKey = GetKeyByNumber(ChatNumber)
                ReorganizeChats(NumberKey)
            end
        else
            PhoneData.Chats[#PhoneData.Chats+1] = {
                name = IsNumberInContacts(ChatNumber),
                number = ChatNumber,
                messages = {},
            }
            NumberKey = GetKeyByNumber(ChatNumber)
            PhoneData.Chats[NumberKey].messages[#PhoneData.Chats[NumberKey].messages+1] = {
                date = ChatDate,
                messages = {},
            }
            ChatKey = GetKeyByDate(NumberKey, ChatDate)
            if ChatType == "message" then
                PhoneData.Chats[NumberKey].messages[ChatKey].messages[#PhoneData.Chats[NumberKey].messages[ChatKey].messages+1] = {
                    message = ChatMessage,
                    time = ChatTime,
                    sender = PhoneData.PlayerData.citizenid,
                    type = ChatType,
                    data = {},
                }
            end
            TriggerServerEvent('qb-phone:server:UpdateMessages', PhoneData.Chats[NumberKey].messages, ChatNumber, true)
            NumberKey = GetKeyByNumber(ChatNumber)
            ReorganizeChats(NumberKey)
        end

        QBCore.Functions.TriggerCallback('qb-phone:server:GetContactPicture', function(Chat)
            SendNUIMessage({
                action = "UpdateChat",
                chatData = Chat,
                chatNumber = ChatNumber,
            })
        end,  PhoneData.Chats[GetKeyByNumber(ChatNumber)]) end



4) Save the file and close it
5) Open `qb-phone/fxmanifest.lua`
6) Add at the bottom of the file: export {'SendMessage'}


### Showcase
- https://www.youtube.com/watch?v=