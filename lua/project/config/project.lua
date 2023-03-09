local config = require "project.config"

-- 管理当前项目的本地化配置
local M = {}

-- project config
local PROJECT_CONFIG = {
    commands = nil,
}
local MODIFIED = false

function M.read()
    local file = config.getPaths().config
    if vim.fn.filereadable(file) == 1 then
        local cfg = vim.fn.json_decode(io.open(file, "r"):read "*a")
        PROJECT_CONFIG.commands = cfg.commands
    else
        PROJECT_CONFIG.commands = {}
    end
end

-- 保存配置到文件
function M.save()
    if MODIFIED then
        local json = vim.fn.json_encode(PROJECT_CONFIG)
        local paths = config.getPaths()
        local dir = paths.base
        local file = paths.config

        if vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir)
        end
        io.open(file, "w"):write(json)
        MODIFIED = false
    end
end

-- 用于遍历 commands 的迭代函数
function M.getCmds()
    return vim.deepcopy(PROJECT_CONFIG.commands)
end

-- 查找 command 配置
function M.findCmd(name)
    for _, iterm in pairs(PROJECT_CONFIG.commands) do
        if iterm.name == name then
            return vim.deepcopy(iterm)
        end
    end
    return nil
end

-- 添加 command，并返回旧的 command 配置
function M.appendCmd(command)
    vim.validate {
        command = { command, "table" },
        name = { command.name, "string" },
        script = { command.script, "string" },
    }

    local tbl = PROJECT_CONFIG.commands

    for _, iterm in pairs(tbl) do
        if iterm.name == command.name then
            local old = vim.deepcopy(iterm)
            iterm.script = command.script
            iterm.terminal = command.terminal
            iterm.autostart = command.autostart
            MODIFIED = true
            return
        end
    end

    table.insert(tbl, {
        name = command.name,
        script = command.script,
        terminal = command.terminal,
        autostart = command.autostart,
    })
    MODIFIED = true
end

-- 删除 command
function M.delCmd(name)
    vim.validate { name = { name, "string" } }
    local tbl = PROJECT_CONFIG.commands
    for index = 1, #tbl do
        if tbl[index].name == name then
            MODIFIED = true
            return table.remove(tbl, index)
        end
    end
end

return {
    read = M.read,
    save = M.save,
    getCmds = M.getCmds,
    findCmd = M.findCmd,
    appendCmd = M.appendCmd,
    delCmd = M.delCmd,
}
