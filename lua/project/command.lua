local config = require "project.config"
local util = require "project.util"
local project = require "project.config.project"
local window = require "project.util.window"

-- 管理脚本
local M = {}

-- 创建指令对象
function M.create(newCmd)
    vim.validate {
        cmd = { newCmd, "table" },
        name = { newCmd.name, "string" },
        script = { newCmd.script, "string" },
    }

    local paths = config.getPaths()

    if vim.fn.isdirectory(paths.script) == 0 then
        vim.fn.mkdir(paths.script, "p")
    end

    -- 查找 command 旧的配置，整合 command 旧的配置和新的配置
    local oldCmd = project.findCmd(newCmd.name)
    if oldCmd then
        newCmd.autostart = newCmd.autostart == nil and oldCmd.autostart or newCmd.autostart
        newCmd.terminal = newCmd.terminal == nil and oldCmd.terminal or newCmd.terminal
    else
        newCmd.autostart = not not newCmd.autostart
        newCmd.terminal = not not newCmd.terminal
    end

    -- 注册 user command
    local script = paths.script .. "/" .. newCmd.script
    M.regCmd(newCmd.name, script, newCmd.terminal)
    M._openEditor(script)

    project.appendCmd(newCmd)
end

-- 删除指令
function M.delete(name)
    vim.validate { name = { name, "string" } }
    local cmd = project.delCmd(name)
    local paths = config.getPaths()
    os.remove(paths.script .. "/" .. cmd.script)
    vim.api.nvim_del_user_command(name)
end

--[[
  在 neovim 启动后执行该函数，
  将脚本注册为 user command，并执行设置了 autostart 的脚本
--]]
function M.start()
    local paths = config.getPaths()

    if vim.fn.isdirectory(paths.script) == 0 then
        return
    end

    for index, iterm in pairs(project.getCmds()) do
        M.regCmd(iterm.name, paths.script .. "/" .. iterm.script, iterm.terminal)
    end

    M._autostart()
end

-- 将脚本注册为 neovim 指令
function M.regCmd(name, script, terminal)
    -- 如果指令已存在，删除指令
    if vim.fn.exists(":" .. name) == 2 then
        vim.api.nvim_del_user_command(name)
    end

    local opts = { nargs = "*", desc = script }
    local callback = function(argv)
        M._run(terminal, script, argv.fargs)
    end
    vim.api.nvim_create_user_command(name, callback, opts)
end

-- 打开编辑脚本的窗口
function M._openEditor(file)
    -- 如果文件不存在，创建新的文件
    if not vim.loop.fs_access(file, 0) then
        vim.fn.writefile({
            "#!" .. config.getConfig().shell,
            "",
            "set -o errexit",
            "set -o nounset",
            "",
            "",
        }, file)
        -- 将文件的权限设置为：用户和组内用户可读、可写和可执行
        vim.fn.setfperm(file, "rwxrwx---")
    end

    window.editor(file)
end

-- 执行脚本
function M._run(terminal, script, args)
    local cfg = config.getConfig()
    local command = { cfg.shell, script }

    if args then
        for _, arg in pairs(args) do
            table.insert(command, arg)
        end
    end
    if terminal then
        window.terminal(command)
    else
        local id = vim.fn.jobstart(command, {
            on_stdout = M.jobCallback,
            on_stderr = M.jobCallback,
        })
        if id == -1 then
            error(cfg.shell .. " is not executable")
        end
    end
end

-- 执行具有 autostart 属性的脚本
function M._autostart()
    local path = config.getPaths().script

    if not util.allow() then
        return
    end

    for _, iterm in pairs(project.getCmds()) do
        if iterm.autostart then
            M._run(false, path .. "/" .. iterm.script)
        end
    end
end

-- 执行 jobstart 时的回调函数
function M.jobCallback(id, data, event)
    for _, line in pairs(data) do
        print(line)
    end
end

return {
    create = M.create,
    delete = M.delete,
    start = M.start,
    regCmd = M.regCmd,
}
