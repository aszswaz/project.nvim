local config = require "project.config"
local file = require "project.file"
local project = require "project.config.project"

-- 管理脚本
local M = {}
local DEFAULT = { name = nil, script = nil, autostart = false, terminal = false }

-- 创建指令对象
function M.create(obj)
    assert(obj, "obj cannot be nil")
    assert(obj.name, "please specify a name for the directive")
    assert(obj.script, "please specify the script for the command")

    setmetatable(obj, DEFAULT)

    --[[
    --   1. 打开一个用来编辑脚本的浮动窗口
    --   2. 用户关闭窗口后，执行如下操作:
    --        1. 保存指令的属性
    --        2. 注册指令到 neovim
    --]]
    project.appendCommand(obj)
    local path, content = M.readfile(obj.script)
    M.openScriptWindow(path, content)
    M.regCmd(obj.name, path, obj.terminal)
end

-- 读取脚本文件
function M.readfile(script)
    local paths = config.getPaths()
    local dir = paths.script
    local path = dir .. "/" .. script

    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end
    -- 无论用户是否向脚本中写入过内容，都必须确保文件的存在
    io.open(path, "a+"):close()
    return path, vim.fn.readfile(path)
end

-- 打开编辑脚本的窗口
function M.openScriptWindow(file, content)
    local x, y, width, height = M.coordinate()

    local buffer = vim.fn.bufadd(file)
    vim.fn.appendbufline(buffer, 0, content)
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

-- 将脚本注册为 neovim 指令
function M.regCmd(name, script, terminal)
    local opts = { nargs = "*", desc = script }
    vim.api.nvim_create_user_command(name, function(argv)
        M.run(terminal, script, argv.fargs)
    end, opts)
end

-- 执行脚本
function M.run(terminal, script, args)
    local cfg = config.getConfig()
    local command = { cfg.shell, script }

    for index = 1, #args do
        command[index + 2] = args[index]
    end
    if not terminal then
        vim.fn.jobstart(command)
    else
        M.termopen(command)
    end
end

-- 打开终端窗口执行脚本
function M.termopen(command)
    local buffer = vim.api.nvim_create_buf(false, true)
    local x, y, width, height = M.coordinate()
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
function M.coordinate()
    local cfg = config.getConfig()
    return math.floor(vim.o.columns / 2 - cfg.width / 2), math.floor(vim.o.lines / 2 - cfg.height / 2 - 2), cfg.width, cfg.height
end

-- 执行具有 autostart 属性的脚本
function M.autostart()
    local cfg = config.getConfig()
    local commands = project.getCommands(true)
    local cwd = vim.loop.cwd()

    if type(cfg.autostart) == "string" then
        if not M.isSubFile(cfg.autostart, cwd) then
            return
        end
    elseif type(cfg.autostart) == "table" then
        for _, iterm in pairs(cfg.autostart) do
            if M.isSubFile(iterm, cwd) then
                goto continue
            end
        end
        return
    elseif not cfg.autostart then
        return
    end

    ::continue::
    for _, iterm in commands() do
        if iterm.autostart then
            M.run(false, iterm.script, {})
        end
    end
end

function M.isSubFile(parentDir, tagetFile)
    local dirs01 = vim.fn.split(parentDir, "/")
    local dirs02 = vim.fn.split(tagetFile, "/")

    if #dirs01 > #dirs02 then
        return false
    end
    for index = 1, #dirs01 do
        if dirs01[index] ~= dirs02[index] then
            return false
        end
    end
    return true
end

-- 在 neovim 启动后执行该函数
function M.start()
    local paths = config.getPaths()

    if vim.fn.isdirectory(paths.script) == 0 then
        return
    end

    local commands = project.getCommands(true)
    for _, iterm in commands() do
        M.regCmd(iterm.name, paths.script .. "/" .. iter.script, iterm.terminal)
    end

    M.autostart()
end

return { create = M.create, start = M.start }
