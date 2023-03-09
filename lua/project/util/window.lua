local config = require "project.config"

-- 编辑器窗口
local M = {}

-- 打开文件编辑器
function M.editor(file)
    local buffer = vim.fn.bufadd(file)
    if vim.fn.filereadable(file) == 1 then
        local content = vim.fn.readfile(file)
        vim.fn.appendbufline(buffer, 0, content)
        vim.bo[buffer].filetype = vim.filetype.match { contents = content, filename = file }
    end

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
    return window, buffer
end

-- 打开终端窗口
function M.terminal(command)
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

    -- 窗口关闭后删除 buffer
    vim.api.nvim_create_autocmd("WinClosed", {
        pattern = tostring(window),
        callback = function()
            vim.api.nvim_buf_delete(buffer, { force = true })
        end,
    })
    -- 进入 terminal 模式
    vim.cmd.startinsert()
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

-- 计算窗口坐标
function M._coordinate()
    local cfg = config.getConfig()
    return math.floor(vim.o.columns / 2 - cfg.width / 2), math.floor(vim.o.lines / 2 - cfg.height / 2 - 2), cfg.width, cfg.height
end

return { editor = M.editor, terminal = M.terminal }
