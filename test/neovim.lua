local neovim = require "project.neovim"

function testLoader()
    -- neovim.loader()
    local demo = { a = 1, b = 2 }
    local k, v = next(demo, "b")
    print(k, v)
end
