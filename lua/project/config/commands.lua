local neovim = require "project.neovim"
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
}

function M.regCommands()
    for _, command in pairs(COMMANDS) do
        vim.api.nvim_create_user_command(command.name, command.action, command.attributes)
    end
end

return M
