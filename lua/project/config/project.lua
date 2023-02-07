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

-- 用于迭代 options 的函数
function M.iOptions()
    local tbl = PROJECT_CONFIG.options
    local lastKey = nil
    return function()
        local k, v = next(tbl, lastKey)
        lastKey = k
        return k, v
    end
end

-- 用于遍历 commands 的迭代函数
function M.iCommands()
    local tbl = PROJECT_CONFIG.commands
    local count = #tbl
    local index = 0
    return function()
        index = index + 1
        if index <= count then
            return index, M._proxyObject(tbl[index])
        end
    end
end

-- 获取 options
function M.getOptions()
    return M._proxyObject(PROJECT_CONFIG.options)
end

-- 添加 command
function M.appendCommand(command)
    PROJECT_CONFIG.commands[#PROJECT_CONFIG.commands + 1] = {
        name = command.name,
        script = command.script,
        terminal = command.terminal,
        autostart = command.autostart,
    }
    MODIFIED = true
end

-- 用 metabale 代理原对象
function M._proxyObject(original)
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
                return M._proxyObject(original[key])
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

return {
    read = M.read,
    save = M.save,
    iOptions = M.iOptions,
    iCommands = M.iCommands,
    appendCommand = M.appendCommand,
    getOptions = M.getOptions,
}
