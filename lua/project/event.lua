local config = require "project.config"
local neovim = require "project.neovim"
local scripts = require "project.scripts"
local project = require "project.config.project"

-- 管理插件的事件
local M = {}

local EVENTS = {
    {
        name = "VimEnter",
        options = {
            callback = function()
                config.update()
                project.read()
                neovim.loader()
                scripts.start()
            end,
        },
    },
    {
        name = "VimLeave",
        options = {
            callback = project.save,
        },
    },
    {
        name = "DirChanged",
        options = {
            callback = config.update,
        },
    },
}

function M.regEvent()
    for _, iterm in pairs(EVENTS) do
        vim.api.nvim_create_autocmd(iterm.name, iterm.options)
    end
end

return M
