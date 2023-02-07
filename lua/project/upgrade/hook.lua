local config = require "project.config"

-- hook 功能升级为 script 功能
local M = {}

function M.upgrade()
    local paths = config.getPaths()
    if vim.fn.isdirectory(paths.hook) == 1 then
        -- 重命名 hook 文件夹
        local status, msg = os.rename(path, paths.script)
        if not status then
            error(msg)
        end

        M._toCommands(paths.script)
    end
end

-- 将脚本注册为 neovim 指令，并设置自启动属性
function M._toCommands(dir)

end

return { upgrade = M.upgrade }
