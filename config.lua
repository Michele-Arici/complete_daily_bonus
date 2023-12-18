Config = {}

-- === VERSION 2.0 ===

Config.Debug                    = false
-- === IMPORTANT ===
-- add this item
--  ['carplay'] = {['name'] = 'carplay', ['label'] = 'Carplay', ['weight'] = 1000, ['type'] = 'item', ['image'] = 'carplay.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Device to controll your vehicle'}
-- remember to add the export in qb-phone as told in the readme.md

-- === GENERAL ===
Config.QBCoreName               = 'qb-core' -- if you have renamed the qb-core folder change this
Config.OpenUICommand            = 'carplay' -- Console command to open the NUI
Config.OpenUIKey                = 'k'
Config.OpenTrunkCameraCommand   = 'trunk-camera' -- Console command to open the trunk camera
Config.OpenTrunkCameraKey       = 'f7' -- Open or close
Config.Km                       = true -- if false mph
Config.Apps                     = {
    ['messages'] = true,
    ['music'] = true,
    ['actions'] = true,
    ['trunk'] = true,
    ['status'] = true
} -- set to FALSE if you want to disable the app
Config.Draggable                = true -- if TRUE you will be able to drag and resize the UI
Config.RemoveFocusKey           = 16 -- [16 = SHIFT] with the UI open, pressing this button the UI will remain on screen but you will be able to use mouse and keyboard (drive)
-- that's a javascript key, use this to change https://www.toptal.com/developers/keycode         
Config.ReturnFocusCommand       = "carplay-focus"       
Config.ReturnFocusKey           = "H"       
Config.High3DSound              = false

-- === PHONE ===
Config.NeedPhoneItem            = true -- true if you need a phone in inventory to use carplay
Config.PhoneItemName            = {
    'phone', 
    'red_phone', 
    'blue_phone'
} -- item name of the phone
Config.PhoneType                = 'qbphone' 
-- now supported: qbphone | gksphone | highphone | quasar | npwd | roadphone | lbphone

-- === NAVIGATOR ===
Config.EnableNavigator          = true
Config.NavigatorPosition        = 'top-left' -- COPY-PASE ONE OF THIS: top-left | top-middle | top-right | middle-left | middle-middle | middle-right | bottom-left | bottom-middle | bottom-right
Config.DisplayCurrentStreet     = true

-- === CARPLAY INSTALLATION ===
Config.NoInstall                = false -- all vehicles will be able to use carplay also without installing it 
Config.RequireMechanic          = true
Config.MechanicJobName          = {
    'mechanic'
}
Config.ItemUsable               = true
Config.MechanicInstallCommand   = 'carplay-install'
Config.InstallTime              = 10000 -- milliseconds

-- === MUSIC ===
Config.BlackListSongs           = {
    'https://youtu.be/93M1QtYDtpU',
}

-- === TEXT ===
Config.Text = {
    ['no_phone'] = "You don't have a phone",
    ['no_carplay'] = "Carplay is not installed in this vehicle",
    ['not_owner'] = 'You are not the owner of this vehicle',
    ['carplay_installed'] = "Installing carplay",
    ['no_item'] = "You don't have the item"
}
