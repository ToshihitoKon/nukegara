require('plugins.core')
require('plugins.lsp')
require('plugins.git')
if require('config.profile').is_review then
    require('plugins.review')
else
    require('plugins.editing')
end
require('plugins.extras')
