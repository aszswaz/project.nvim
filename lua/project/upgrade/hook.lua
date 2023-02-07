local config = require "project.config"
local project = require "project.config.project"

-- hook 功能升级为 script 功能
local M = {}

function M.upgrade()
    local paths = config.getPaths()
    if vim.fn.isdirectory(paths.hook) == 1 then
        -- 重命名 hook 文件夹
        local status, msg = os.rename(paths.hook, paths.script)
        if not status then
            error(msg)
        end

        M._toCommands(paths.script)
    end
end

-- 将脚本注册为 neovim 指令，并设置自启动属性
function M._toCommands(dir)
    for file, _ in vim.fs.dir(dir) do
        -- 去除文件后缀名
        local fileName = string.sub(file, 1, vim.fn.strridx(file, "."))
        -- 文件首字母改为大写
        local char = vim.fn.strgetchar(fileName, 0)
        if char >= 97 and char <= 122 then
            -- 首字母改为大写字母作为指令的名称
            local commandName = vim.fn.nr2char(char - 32) .. string.sub(fileName, 2)
            project.appendCmd { name = commandName, script = file, terminal = false, autostart = true }
        elseif char < 65 or char > 90 then
            -- 首个字符不是字母
            error "the first character of the script name must be a letter"
        end
    end
end

return { upgrade = M.upgrade }
