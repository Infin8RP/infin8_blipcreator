fx_version 'cerulean'
game 'gta5'

author 'Infin8RP'
description 'Infin8_blipcreator - Personal Blip System'
version '1.0.0'

ui_page 'web/build/index.html'
files {
    'web/build/**/*'
}

shared_scripts {
    'config.lua',
    'shared/*.lua'
}

client_scripts {
    'client/nui.lua',
    'client/main.lua'
}

server_scripts {
    'server/*.lua'
}
