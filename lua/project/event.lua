local config = require "project.config"
local project = require "project.config.project"
local command = require "project.command"
local autoset = require "project.autoset"

-- 管理插件的事件
local M = {}

function M.regEvent()
    local events = {
        {
            name = "VimEnter",
            options = {
                callback = M._autostart,
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
                callback = M._autostart,
            },
        },
    }

    for _, iterm in pairs(events) do
        vim.api.nvim_create_autocmd(iterm.name, iterm.options)
    end
end

function M._autostart()
    config.update()
    project.read()
    command.start()
    autoset.run()
end

return M
