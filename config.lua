Config = {}

Config.CheckScriptUpdates   = true                  -- Check for updates on github
Config.OpenCommand          = 'daily-bonus'         -- Command to open the menu
Config.TimeToClaim          = {
    hours = 24,                                      -- Hours to claim the reward
    minutes = 0,                                    -- Minutes to claim the reward
    seconds = 0,                                    -- Seconds to claim the reward
}
Config.AnimationDuration    = 12                    -- Time in seconds to spin the roulette, more the items more time is reccomended
Config.SellType             = "bank"                -- Type of reward to sell, cash or bank
Config.WeaponAmmo           = 100                   -- Ammo to give with the weapon
Config.CarParkingSpawn      = "SanAndreasAvenue"    -- Garage to spawn the car (SanAndreasAvenue name not working with QBCore, check your garage script config)

-- type: vehicle, item, cash, bank, weapon
-- quantity: only for items, how many items to give
Config.RouletteData = {
    [0] = {
        id = 0,
        type = "vehicle",
        model = "bmci",
        rarity = "legendary",
        img = '/html/img/m5-comp.png',
        name = "BMW M5 F90 2018",
        sell = 25000
    },
    [1] = {
        id = 1,
        type = "weapon",
        model = "weapon_combatpistol",
        rarity = "epic",
        img = '/html/img/combat-pistol.png',
        name = "Combat Pistol",
        sell = 5000
    },
    [2] = {
        id = 2,
        rarity = "rare",
        type = "weapon",
        model = "weapon_knuckle",
        img = '/html/img/knuckles.webp',
        name = "Knuckle Dusters",
        sell = 500
    },
    [3] = {
        id = 3,
        rarity = "rare",
        type = "item",
        model = "fixkit",
        img = '/html/img/fix_kit.png',
        name = "Car Fix Kit",
        sell = 500,
        quantity = 1
    },
    [4] = {
        id = 4,
        rarity = "rare",
        type = "bank",
        model = 1000,
        img = '/html/img/creditCard.png',
        name = "$1000 Bank",
        sell = 500
    },
    [5] = {
        id = 5,
        rarity = "common",
        type = "item",
        model = "bandage",
        img = '/html/img/bandage.png',
        name = "Bandage",
        sell = 50,
        quantity = 1
    },
    [6] = {
        id = 6,
        rarity = "common",
        type = "item",
        model = "cola",
        img = '/html/img/cola.png',
        name = "Coca Cola",
        sell = 50,
        quantity = 1
    },
    [7] = {
        id = 7,
        rarity = "common",
        type = "cash",
        model = 100,
        img = '/html/img/cash.png',
        name = "$100 Cash",
        sell = 50
    },
    [8] = {
        id = 8,
        rarity = "common",
        type = "item",
        model = "medikit",
        img = '/html/img/medikit.png',
        name = "Medikit",
        sell = 50,
        quantity = 1
    },
    [9] = {
        id = 9,
        rarity = "epic",
        type = "vehicle",
        model = "vespa",
        img = '/html/img/vespa.webp',
        name = "Piaggio Vespa 150cc",
        sell = 7500
    },
    [10] = {
        id = 10,
        rarity = "legendary",
        type = "weapon",
        model = "weapon_shotgun",
        img = '/html/img/shotgun.webp',
        name = "Pump Shotgun",
        sell = 7500
    },
    [11] = {
        id = 11,
        rarity = "epic",
        type = "item",
        model = "louisvuittonbag",
        img = '/html/img/louis_vuitton.webp',
        name = "Louis Vuitton Bag",
        sell = 5000,
        quantity = 1
    },
    [12] = {
        id = 12,
        rarity = "rare",
        type = "item",
        model = "bodyarmor",
        img = '/html/img/armor.png',
        name = "Body Armor",
        sell = 500,
        quantity = 1
    },
    [13] = {
        id = 13,
        rarity = "common",
        type = "item",
        model = "joint",
        img = '/html/img/joint.png',
        name = "Joint",
        sell = 50,
        quantity = 1
    },
    [14] = {
        id = 14,
        rarity = "common",
        type = "item",
        model = "chips",
        img = '/html/img/chips.png',
        name = "Chips",
        sell = 50,
        quantity = 1
    },
}

Config.RarityProbability = {
    legendary = 0.001,
    epic = 0.02,
    rare = 0.20,
    common = 0.779
}


-- === TEXT ===
Config.Text = {
    ['initialized'] = "Daily bonus initialized",
    ['item_sold'] = "You sold the item for $",
    ['item_collected'] = "You collected the item"
}

Config.Notify = function(text, type)
    -- ESX
    ESX.ShowNotification(text, type, 3000)

    -- QBCore
    -- QBCore.Functions.Notify(text, type, 3000)
end
