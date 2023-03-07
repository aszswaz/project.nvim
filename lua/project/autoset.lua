local config = require "project.config"
local editor = require "project.util.editor"
local util = require "project.util"

local M = {}

function M.edit()
    local paths = config.getPaths()

    if vim.fn.isdirectory(paths.base) == 0 then
        vim.fn.mkdir(paths.base, "p")
    end
    editor.openFile(paths.autoset)
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
