fx_version 'adamant'
lua54 'on'
game 'gta5'

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
    '@mysql-async/lib/MySQL.lua',
}

escrow_ignore {
    "config.lua",
}