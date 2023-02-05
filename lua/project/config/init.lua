local M = {}

local PATH_CONFIG = {
    base = nil,
    config = nil,
    hook = nil,
    script = nil,
}

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

-- 更新配置
function M.update()
    local base = vim.loop.cwd() .. "/.nvim"
    PATH_CONFIG.base = base
    PATH_CONFIG.config = base .. "/config.json"
    PATH_CONFIG.hook = base .. "/hook"
    PATH_CONFIG.script = base .. "/script"
end

function M.getConfig()
    assert(CONFIG, 'Please call "require("project").setup()" to initialize the plugin.')
    return CONFIG
end

function M.getPaths()
    local t = {}
    setmetatable(t, { __index = PATH_CONFIG })
    return t
end

return {
    setConfig = M.setConfig,
    getConfig = M.getConfig,
    getPaths = M.getPaths,
    update = M.update,
}
