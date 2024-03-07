fx_version 'adamant'
lua54 'on'
game 'gta5'

description 'Complete Daily Bonus | Attract players every day'
author 'fanonx'
version '1.0.2'

ui_page 'html/main.html'

files {
	'html/main.html',
	'html/app.js',
	'html/style.css',
	'html/jquery-3.4.1.min.js',
    'html/img/*.png',
    'html/img/*.jpg',
    'html/img/*.webp',
}

client_scripts{
    'config.lua',
    'client/client.lua',
}

server_scripts{
    'config.lua',
    'server/server.lua',
    'server/version.lua',
    '@mysql-async/lib/MySQL.lua',
}