local M = {}

local BASE_DIR = ".nvim"
local CONFIG_PATH = ".nvim/config.lua"

-- 插件的默认配置
local DEFAULT = {
    -- 值为 boolean 表示是否启用 hook，值为 string 或列表，表示指定的文件夹下启用 hook
    enable_hook = false,
    -- 用于执行 hook 的 shell
    shell = vim.o.shell,
}
local CONFIG = nil

-- 设置插件配置
function M.setConfig(config)
    assert(not config or type(config) == "table", "the config parameter must be table or nil")
    config = setmetatable(config, { __index = DEFAULT })
    if type(config.enable_hook) == "string" then
        config.enable_hook = vim.fs.normalize(config.enable_hook)
    elseif vim.tbl_islist(config.enable_hook) then
        for index = 1, #config.enable_hook do
            config.enable_hook[index] = vim.fs.normalize(config.enable_hook[index])
        end
    elseif type(config.enable_hook) ~= "boolean" then
        error "enable_hook must be a string, a list or a boolean."
    end
    CONFIG = config
end

function M.getConfig()
    if not CONFIG then
        error 'Please call "require("project").setup()" to initialize the plugin.'
    end
    return CONFIG
end

function M.getConfigPath()
    local file = vim.loop.cwd() .. "/" .. BASE_DIR .. "/config.json"
    return file, vim.fn.filereadable(file) == 1
end

function M.getHookPath()
    local dir = vim.loop.cwd() .. "/" .. BASE_DIR .. "/hook"
    return dir, vim.fn.isdirectory(dir) == 1
end

function M.getCommandDir()
    local dir = vim.loop.cwd() .. "/" .. BASE_DIR .. "/command"
    return dir, vim.fn.isdirectory(dir) == 1
end

return {
    setConfig = M.setConfig,
    getConfig = M.getConfig,
    getConfigPath = M.getConfigPath,
    getHookPath = M.getHookPath,
    getCommandDir = M.getCommandDir,
}
