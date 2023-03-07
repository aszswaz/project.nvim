local config = require "project.config"

local M = {}

-- 允许执行自动脚本
function M.allow()
    local cwd = vim.fn.getcwd(0)
    local cfg = config.getConfig()

    if type(cfg.autostart) == "string" then
        if not M._isChild(cfg.autostart, cwd) then
            return false
        end
    elseif type(cfg.autostart) == "table" then
        for _, iterm in pairs(cfg.autostart) do
            if M._isChild(iterm, cwd) then
                goto success
            end
        end
        return false
    elseif not cfg.autostart then
        return false
    end

    ::success::
    return true
end

function M._isChild(parentDir, tagetFile)
    local dirs01 = vim.fn.split(parentDir, "/")
    local dirs02 = vim.fn.split(tagetFile, "/")

    if #dirs01 > #dirs02 then
        return false
    end
    for index = 1, #dirs01 do
        if dirs01[index] ~= dirs02[index] then
            return false
        end
    end
    return true
end

return {
    allow = M.allow,
}
