local config = require "project.config"

-- hook 功能升级为 script 功能
local M = {}

function M.upgrade()
    M.movDir()
    M.tocommands()
end

-- 将目录 hook 重命名为 script
function M.movDir()
    local cfgPaths = config.getPaths()
    if vim.fn.isdirectory(cfgPaths.hook) == 1 then
        local status, msg = os.rename(cfgPaths.hook, cfgPaths.script)
        if not status then
            error(msg)
        end
    end
end

-- 将脚本注册为 neovim 指令，并设置自启动属性
function M.tocommands()
end

return { upgrade = M.upgrade }
