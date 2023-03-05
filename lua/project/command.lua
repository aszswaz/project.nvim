local config = require "project.config"
local file = require "project.file"
local project = require "project.config.project"

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
    local newScript = paths.script .. "/" .. newCmd.script

    if vim.fn.isdirectory(paths.script) == 0 then
        vim.fn.mkdir(paths.script, "p")
    end

    -- 先注册 user command，这样可以先校验指令名称是否正确
    M.regCmd(newCmd.name, newScript, newCmd.terminal)

    M._editoropen(newScript)

    local oldCmd = project.appendCmd(newCmd)
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

--[[
  在 neovim 启动后执行该函数，
  将脚本注册为 user command，并执行设置了 autostart 的脚本
--]]
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
    local buffer = vim.fn.bufadd(file)

    if vim.fn.filereadable(file) == 1 then
        vim.fn.appendbufline(buffer, 0, vim.fn.readfile(file))
    else
        -- 创建文件
        vim.fn.writefile({}, file)
        -- 将文件的权限设置为：用户和组内用户可读、可写和可执行
        vim.fn.setfperm(file, "rwxrwx---")
    end
    vim.bo[buffer].filetype = "sh"

    local x, y, width, height = M._coordinate()
    local window = vim.api.nvim_open_win(buffer, true, {
        relative = "editor",
        width = width,
        height = height,
        row = y,
        col = x,
        focusable = true,
        border = "single",
    })
    M._setHighlight(window)

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
    M._setHighlight(window)
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

    -- 将光标移动到最后一行，当 shell 输出超过窗口高度时，termopen() 会把光标保持在最后一行
    vim.cmd.normal "G"
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
    local cwd = vim.loop.cwd()

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

-- 设置窗口样式
function M._setHighlight(win)
    -- neovim 默认主题的浮动窗口的背景色太亮，导致无法正常显示文字，需要使用自定义样式
    if vim.fn.exists "g:colors_name" == 0 then
        if vim.fn.hlID "ProjectWindow" == 0 then
            vim.api.nvim_set_hl(0, "ProjectWindow", {
                bg = "#000000",
            })
        end
        vim.wo[win].winhighlight = "NormalFloat:ProjectWindow"
    else
        vim.wo[win].winhighlight = "NormalFloat:Normal"
    end
end

return {
    create = M.create,
    delete = M.delete,
    start = M.start,
    regCmd = M.regCmd,
}
