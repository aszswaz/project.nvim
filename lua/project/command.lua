local config = require "project.config"
local file = require "project.file"
local project = require "project.config.project"

-- 管理脚本
local M = {}
local DEFAULT = { name = nil, script = nil, autostart = false, terminal = false }

-- 创建指令对象
function M.create(newCmd)
    vim.validate {
        cmd = { newCmd, "table" },
        name = { newCmd.name, "string" },
        script = { newCmd.script, "string" },
    }
    setmetatable(newCmd, { __index = DEFAULT })

    local oldCmd = project.appendCmd(newCmd)
    local paths = config.getPaths()
    local newScript = paths.script .. "/" .. newCmd.script

    io.open(newScript, "a+"):close()
    M._editoropen(newScript)
    M.regCmd(newCmd.name, newScript, newCmd.terminal)

    if oldCmd.script ~= newCmd.script then
        os.remove(paths.script .. "/" .. oldCmd.script)
    end
end

-- 删除指令
function M.delete(name)
    vim.validate { name = { name, "string" } }
    local cmd = project.delCmd(name)
    local paths = config.getPaths()
    os.remove(paths.script .. "/" .. cmd.script)
    vim.api.nvim_del_user_command(name)
end

-- 在 neovim 启动后执行该函数
function M.start()
    local paths = config.getPaths()

    if vim.fn.isdirectory(paths.script) == 0 then
        return
    end

    for index, iterm in project.iCommands() do
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
function M._editoropen(file)
    local x, y, width, height = M._coordinate()

    local buffer = vim.fn.bufadd(file)
    vim.fn.appendbufline(buffer, 0, vim.fn.readfile(file))
    vim.bo[buffer].filetype = "sh"
    local window = vim.api.nvim_open_win(buffer, true, {
        relative = "editor",
        width = width,
        height = height,
        row = y,
        col = x,
        focusable = true,
        border = "single",
    })
    vim.wo[window].winhighlight = "NormalFloat:Normal"
    vim.api.nvim_create_autocmd("WinClosed", {
        pattern = tostring(window),
        callback = function()
            vim.api.nvim_buf_delete(buffer, {})
        end,
    })
end

-- 执行脚本
function M._run(terminal, script, args)
    local cfg = config.getConfig()
    local command = { cfg.shell, script }

    for _, arg in pairs(args) do
        table.insert(command, arg)
    end
    if terminal then
        M._termopen(command)
    else
        local callback = function(id, data, event)
            for _, line in pairs(data) do
                print(line)
            end
        end
        local id = vim.fn.jobstart(command, {
            on_stdout = callback,
            on_stderr = callback,
        })
        if id == -1 then
            error(cfg.shell .. " is not executable")
        end
    end
end

-- 打开终端窗口执行脚本
function M._termopen(command)
    local buffer = vim.api.nvim_create_buf(false, true)
    local x, y, width, height = M._coordinate()
    local window = vim.api.nvim_open_win(buffer, true, {
        relative = "editor",
        border = "single",
        row = y,
        col = x,
        width = width,
        height = height,
    })
    -- termopen 会直接使用当前窗口和缓冲区与用户进行交互
    vim.api.nvim_set_current_win(window)
    local id = vim.fn.termopen(command)
    if id == -1 then
        error(cfg.shell .. " is not executable")
    end
    vim.keymap.set("n", "q", function()
        vim.api.nvim_win_close(window, { force = true })
        vim.api.nvim_buf_delete(buffer, { force = true })
    end, { buffer = buffer })
end

-- 计算窗口坐标
function M._coordinate()
    local cfg = config.getConfig()
    return math.floor(vim.o.columns / 2 - cfg.width / 2), math.floor(vim.o.lines / 2 - cfg.height / 2 - 2), cfg.width, cfg.height
end

-- 执行具有 autostart 属性的脚本
function M._autostart()
    local cfg = config.getConfig()
    local path = config.getPaths().script

    if type(cfg.autostart) == "string" then
        if not file.isChild(cfg.autostart, cwd) then
            return
        end
    elseif type(cfg.autostart) == "table" then
        for _, iterm in pairs(cfg.autostart) do
            if file.isChild(iterm, cwd) then
                goto continue
            end
        end
        return
    elseif not cfg.autostart then
        return
    end

    ::continue::
    for _, iterm in project.iCommands() do
        if iterm.autostart then
            M._run(false, path .. "/" .. iterm.script, {})
        end
    end
end

return {
    create = M.create,
    delete = M.delete,
    start = M.start,
    regCmd = M.regCmd,
}
