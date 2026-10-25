require('config.options')
require('config.keymaps')
require('config.autocmds')
require('config.usercmds')
if not require('config.profile').is_review then
    require('config.open_readme')
end
require('plugins')
