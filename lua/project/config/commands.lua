local neovim = require "project.neovim"
local config = require "project.config"
local command = require "project.command"
local project = require "project.config.project"

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
        name = "ProjectCmd",
        action = function(argv)
            command.create(M._newCmd(argv.fargs))
        end,
        attributes = {
            nargs = "+",
            complete = function()
                local c = { "--autostart", "--terminal" }
                for _, iterm in project.iCommands() do
                    table.insert(c, iterm.name)
                end
                return c
            end,
            desc = "Manages the mapping of external shells to neovim commands.",
        },
    },
    {
        name = "ProjectCmdDel",
        action = function(argv)
            command.delete(argv.fargs[1])
        end,
        attributes = {
            nargs = 1,
            desc = "Remove script directives.",
            complete = function()
                local cmds = {}
                for _, iterm in project.iCommands() do
                    table.insert(cmds, iterm.name)
                end
                return cmds
            end,
        },
    },
}

function M.regCommands()
    for _, command in pairs(COMMANDS) do
        vim.api.nvim_create_user_command(command.name, command.action, command.attributes)
    end
end

function M._newCmd(args)
    local newCmd = {}

    for _, iterm in pairs(args) do
        if iterm == "--autostart" then
            newCmd.autostart = true
        elseif iterm == "--terminal" then
            newCmd.terminal = true
        else
            newCmd.name = iterm
            newCmd.script = iterm
            break
        end
    end
    return newCmd
end

return { regCommands = M.regCommands }
