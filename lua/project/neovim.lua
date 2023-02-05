local project = require "project.config.project"

-- 管理项目的 neovim 配置
local M = {}

-- 加载 neovim 选项
function M.loader()
    local options = project.getOptions(true)
    if options then
        for option, value in options() do
            vim.o[option] = value
        end
    end
end

-- 设置选项，或删除选项
function M.option(argv)
    local opt = argv.fargs[1]
    local value = argv.fargs[2]

    local options = project.getOptions()

    if value then
        vim.o[opt] = value
        options[opt] = value
    else
        vim.o[opt] = nil
        options[opt] = nil
    end
end

return {
    loader = M.loader,
    save = M.save,
    option = M.option,
}