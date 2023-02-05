local neovim = require "project.neovim"
local scripts = require "project.scripts"
local config = require "project.config"

local M = {}

local COMMANDS = {
    {
        name = "ProjectOption",
        action = neovim.option,
        attributes = {
            nargs = "+",
            complete = "option",
            desc = "set the neovim option, which only works on the current project.",
        },
    },
    {
        name = "ProjectOpenHook",
        action = scripts.openHook,
        attributes = {
            nargs = 1,
            complete = function()
                return vim.fn.readdir(config.getPaths().hook)
            end,
            desc = "create or open a hook script for the current project.",
        },
    },
    {
        name = "ProjectDeleteHook",
        action = scripts.deleteHook,
        attributes = {
            nargs = "+",
            complete = function()
                return vim.fn.readdir(config.getPaths().hook)
            end,
            desc = "delete the hook script from the project.",
        },
    },
    {
        name = "ProjectRunHook",
        action = function(argv)
            scripts.runHook()
        end,
        attributes = {
            nargs = 0,
            desc = "re-execute the script.",
        },
    },
}

function M.regCommands()
    for _, command in pairs(COMMANDS) do
        vim.api.nvim_create_user_command(command.name, command.action, command.attributes)
    end
end

return M
