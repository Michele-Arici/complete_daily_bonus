Config = {}

-- === VERSION 1.0 ===
Config.OpenCommand  = 'daily-bonus' -- Command to open the menu
Config.TimeToClaim  = 86400        -- Time in seconds to claim the reward, 86400 = 24 hours
Config.RouletteTime = 9           -- Time in seconds to spin the roulette, 9 recommended

Config.RouletteData = {
    [0] = {
        data = {
            id = 0,
            rarity = "legendary",
            img = '/html/img/merc.png',
            name = "Mercedes G63 AMG",
        },
        reward = function ()
            -- Give reward
        end
    },
    [1] = {
        data = {
            id = 1,
            rarity = "epic",
            img = '/html/img/supreme.webp',
            name = "Supreme Backpack",
        },
        reward = function ()
            -- Give reward
        end
    },
    [2] = {
        data = {
            id = 2,
            rarity = "rare",
            img = '/html/img/knife.png',
            name = "Knife",
        },
        reward = function ()
            -- Give reward
        end
    },
    [3] = {
        data = {
            id = 3,
            rarity = "rare",
            img = '/html/img/carplay.png',
            name = "Carplay",
        },
        reward = function ()
            -- Give reward
        end
    },
    [4] = {
        data = {
            id = 4,
            rarity = "common",
            img = '/html/img/merc.png',
            name = "Gucci Backpack",
        },
        reward = function ()
            -- Give reward
        end
    },
    [5] = {
        data = {
            id = 5,
            rarity = "common",
            img = '/html/img/cola.png',
            name = "Coca Cola",
        },
        reward = function ()
            -- Give reward
        end
    },
    [6] = {
        data = {
            id = 6,
            rarity = "common",
            img = '/html/img/cash.png',
            name = "$1000 cash",
        },
        reward = function ()
            -- Give reward
        end
    },
    [7] = {
        data = {
            id = 7,
            rarity = "common",
            img = '/html/img/iphone.webp',
            name = "Iphone",
        },
        reward = function ()
            -- Give reward
        end
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
    ['no_phone'] = "You don't have a phone",
    ['no_carplay'] = "Carplay is not installed in this vehicle",
    ['not_owner'] = 'You are not the owner of this vehicle',
    ['carplay_installed'] = "Installing carplay",
    ['no_item'] = "You don't have the item"
}
