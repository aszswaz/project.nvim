local config = require "project.config"
local window = require "project.util.window"
local util = require "project.util"

local M = {}

function M.edit()
    local paths = config.getPaths()

    if vim.fn.isdirectory(paths.base) == 0 then
        vim.fn.mkdir(paths.base, "p")
    end
    window.editor(paths.autoset)
end

function M.run()
    local file = config.getPaths().autoset

    if not vim.loop.fs_access(file, 0) or not util.allow() then
        return
    end

    vim.cmd("source " .. file)
end

return {
    edit = M.edit,
    run = M.run,
}
