fx_version 'cerulean'
game 'gta5'
author 'TRS Studio'
description 'TRS Framework autonome'
version '1.0.0'
lua54 'yes'
shared_scripts {'shared/bootstrap.lua','shared/Config.lua','shared/settings.lua'}
server_scripts {'@oxmysql/lib/MySQL.lua','server/core.lua','server/gameplay.lua'}
client_scripts {'client/main.lua'}
ui_page 'html/index.html'
files {'html/index.html','html/style.css','html/app.js'}
dependencies {'oxmysql','spawnmanager','/onesync'}
