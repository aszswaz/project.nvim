local M = {}

local PATH_CONFIG = {
    base = nil,
    config = nil,
    hook = nil,
    script = nil,
}

-- 插件的默认配置
local DEFAULT = {
    --[[
        如果是 boolean 表示是否执行设置了 autostart 属性的指令，
        如果是 string 或 list，表示指定目录下的项目执行带有 autostart 属性的指令。
    --]]
    autostart = false,
    -- 用于执行 hook 的 shell
    shell = vim.o.shell,
    -- 浮动窗口占用的空间
    width = math.floor(vim.o.columns * 0.95),
    height = math.floor(vim.o.lines * 0.95),
}
local CONFIG = nil

-- 设置插件配置
function M.setConfig(config)
    config = config or {}
    config = setmetatable(config, { __index = DEFAULT })

    vim.validate {
        autostart = { config.autostart, { "table", "string", "boolean" } },
        shell = { config.shell, "string" },
    }

    local typeStr = type(config.autostart)
    if typeStr == "string" then
        config.autostart = vim.fs.normalize(config.autostart)
    elseif vim.tbl_islist(config.autostart) then
        for index = 1, #config.autostart do
            config.autostart[index] = vim.fs.normalize(config.autostart[index])
        end
    elseif config.autostart and typeStr ~= "boolean" then
        error "autostart must be a string, a list or a boolean."
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
