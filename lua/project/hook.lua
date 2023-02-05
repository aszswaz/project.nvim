local config = require "project.config"
local file = require "project.file"

-- 管理 hook 脚本
local M = {}

-- 创建或打开 HOOK 脚本
function M.openHook(argv)
    local dir, isdir = config.getHookPath()

    if not isdir then
        vim.fn.mkdir(dir, "p")
    end
    vim.cmd.edit(dir .. "/" .. argv.fargs[1])
end

-- 执行所有 HOOK 脚本
function M.runHook()
    local cfg = config.getConfig()
    local shell = cfg.shell
    local dir, isdir = config.getHookPath()

    if not isdir or not cfg.enable_hook then
        return
    end
    if type(cfg.enable_hook) == "string" then
        if not M.isSubFile(cfg.enable_hook, dir) then
            return
        end
    elseif vim.tbl_islist(cfg.enable_hook) then
        for _, parentDir in pairs(cfg.enable_hook) do
            assert(type(parentDir) == "string", "when enable_hook is a list, the elements of the list must be string.")
            if file.isSubFile(parentDir, dir) then
                goto continue
            end
        end
    end

    ::continue::
    for _, script in pairs(vim.fn.readdir(dir)) do
        local jobid = vim.fn.jobstart { shell, dir .. "/" .. script }
        if jobid == -1 then
            error(shell .. " is not executable.")
        end
    end
end

-- delete the hook script
function M.deleteHook(argv)
    local buffers = vim.api.nvim_list_bufs()
    local dir = config.getHookPath()

    for _, hook in pairs(argv.fargs) do
        local file = dir .. "/" .. hook
        for _, buffer in pairs(buffers) do
            if file == vim.fn.bufname(buffer) then
                vim.api.nvim_buf_delete(buffer, { force = true })
            end
            os.remove(file)
        end
    end
end

return {
    openHook = M.openHook,
    runHook = M.runHook,
    deleteHook = M.deleteHook,
}
