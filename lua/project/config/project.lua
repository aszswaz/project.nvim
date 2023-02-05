local config = require "project.config"

-- 管理当前项目的本地化配置
local M = {}

-- project config
local PROJECT_CONFIG = {
    options = nil,
    commands = nil,
}
local MODIFIED = false

function M.read()
    local file = config.getPaths().config
    if vim.fn.filereadable(file) == 1 then
        local cfg = vim.fn.json_decode(io.open(file, "r"):read "*a")
        PROJECT_CONFIG.options = cfg.options
        PROJECT_CONFIG.commands = cfg.commands
    else
        PROJECT_CONFIG.options = {}
        PROJECT_CONFIG.commands = {}
    end
end

-- 保存配置到文件
function M.save()
    if MODIFIED then
        local json = vim.fn.json_encode(PROJECT_CONFIG)
        local file = config.getPaths().config
        local dir = vim.fs.dirname(file)

        if vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir)
        end
        io.open(file, "w"):write(json)
        MODIFIED = false
    end
end

-- 用 metabale 代理原对象
function M.proxyObject(original)
    if type(original) ~= "table" then
        return original
    end

    local t = {}
    setmetatable(t, {
        __index = function(t, key)
            if original[key] == nil then
                return nil
            end
            if type(original[key]) == "table" then
                return M.proxyObject(original[key])
            else
                return original[key]
            end
        end,
        __newindex = function(t, key, value)
            original[key] = value
            MODIFIED = true
        end,
    })
    return t
end

function M.getOptions(iter)
    if iter then
        -- 返回迭代器函数
        return function()
            local key, value = pairs(PROJECT_CONFIG.options)
            return key, value
        end
    else
        return M.proxyObject(PROJECT_CONFIG.options)
    end
end

function M.getCommands(iter)
    if iter then
        return function()
            local key, value = pairs(PROJECT_CONFIG.commands)
            return key, M.proxyObject(value)
        end
    else
        return M.proxyObject(PROJECT_CONFIG.commands)
    end
end

return {
    read = M.read,
    save = M.save,
    getOptions = M.getOptions,
    getCommands = M.getCommands,
}
