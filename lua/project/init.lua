local M = {}

local config = require "project.config"
local neovim = require "project.neovim"
local hook = require "project.hook"

function M.setup(cfg)
    local createAutocmd = vim.api.nvim_create_autocmd

    config.setConfig(cfg)

    createAutocmd("VimEnter", {
        callback = function()
            neovim.loader()
            hook.runHook()
        end,
    })
    createAutocmd("VimLeave", {
        callback = neovim.save,
    })

    for _, command in pairs(require "project.config.commands") do
        vim.api.nvim_create_user_command(command.name, command.action, command.attributes)
    end
end

return { setup = M.setup }
