local config = require "project.config"

-- 管理项目的 neovim 配置
local M = {}

-- project config
local PROJECT_CONFIG = {
    options = {},
}
local MODIFIED = false

-- 加载 neovim 选项
function M.loader()
    local file, readable = config.getConfigPath()

    if not readable then
        return
    end

    local config = vim.fn.json_decode(vim.fn.readfile(file))
    if config.options then
        for option, value in pairs(config.options) do
            vim.o[option] = value
        end
    end
end

-- 保存 neovim 选项
function M.save()
    if MODIFIED then
        local json = vim.fn.json_encode(PROJECT_CONFIG)
        local file = config.getConfigPath()
        local dir = vim.fs.dirname(file)

        if vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir)
        end
        io.open(file, "w"):write(json)
        MODIFIED = false
    end
end

-- 设置选项，或打印选项的值
function M.option(argv)
    local opt = argv.fargs[1]
    local value = argv.fargs[2]
    vim.o[opt] = value
    if value then
        PROJECT_CONFIG.options[opt] = value
        MODIFIED = true
    else
        print(PROJECT_CONFIG.options[opt])
    end
end

return {
    loader = M.loader,
    save = M.save,
    option = M.option,
}
