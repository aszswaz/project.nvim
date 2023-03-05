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
            local newCmd = {}
            for _, iterm in pairs(argv.fargs) do
                if iterm == "--enable-autostart" then
                    newCmd.autostart = true
                elseif iterm == "--disable-autostart" then
                    newCmd.autostart = false
                elseif iterm == "--enable-terminal" then
                    newCmd.terminal = true
                elseif iterm == "--disable-terminal" then
                    newCmd.terminal = false
                else
                    newCmd.name = iterm
                    newCmd.script = iterm
                    break
                end
            end
            command.create(newCmd)
        end,
        attributes = {
            nargs = "+",
            complete = function(argLead, cmdLine)
                local c = {
                    "--enable-autostart",
                    "--disable-autostart",
                    "--enable-terminal",
                    "--disable-terminal",
                }
                for _, iterm in project.iCommands() do
                    table.insert(c, iterm.name)
                end
                return M._complete(argLead, cmdLine, c)
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
            complete = function(argLead, cmdLine)
                local cmds = {}
                for _, iterm in project.iCommands() do
                    table.insert(cmds, iterm.name)
                end
                return M._complete(argLead, cmdLine, cmds)
            end,
        },
    },
}

-- 注册 user command
function M.regCommands()
    for _, command in pairs(COMMANDS) do
        vim.api.nvim_create_user_command(command.name, command.action, command.attributes)
    end
end

-- 在给定的列表中匹配选项
function M._complete(argLead, cmdLine, opts)
    local result = {}
    local contain = function(text, expr)
        return vim.fn.match(text, expr) ~= -1
    end
    for _, iterm in pairs(opts) do
        if contain(iterm, argLead) and not contain(cmdLine, iterm) then
            table.insert(result, iterm)
        end
    end
    return result
end

return { regCommands = M.regCommands }
