local M = {}

local BASE_DIR = ".nvim"
local CONFIG_PATH = ".nvim/config.lua"

-- the default configuration of the plug-in.
local default = {
    -- Whether hooks are enabled or not, or the directory where hooks are enabled.
    enable_hook = false,
    -- A shell to execute the hook script.
    shell = vim.o.shell,
}
-- project config
local PROJECT_CONFIG = {
    options = {},
}
local configModified = false

function M.setup(config)
    local config = M.handlerConfig(config)
    local createAutocmd = vim.api.nvim_create_autocmd
    createAutocmd("VimEnter", {
        callback = function()
            M.loaderConfig()
            M.runHook(config)
        end,
    })
    createAutocmd("VimLeave", {
        callback = M.saveConfig,
    })

    local commands = {
        {
            name = "ProjectOption",
            action = M.option,
            attributes = {
                nargs = "+",
                complete = "option",
                desc = "set the neovim option, which only works on the current project.",
            },
        },
        {
            name = "ProjectOpenHook",
            action = M.openHook,
            attributes = {
                nargs = 1,
                complete = function()
                    return vim.fn.readdir(M.getHookPath())
                end,
                desc = "create or open a hook script for the current project.",
            },
        },
        {
            name = "ProjectDeleteHook",
            action = M.deleteHook,
            attributes = {
                nargs = "+",
                complete = function()
                    return vim.fn.readdir(M.getHookPath())
                end,
                desc = "delete the hook script from the project.",
            },
        },
        {
            name = "ProjectRunHook",
            action = function(argv)
                M.runHook(config)
            end,
            attributes = {
                nargs = 0,
                desc = "re-execute the script.",
            },
        },
    }
    for _, command in pairs(commands) do
        vim.api.nvim_create_user_command(command.name, command.action, command.attributes)
    end
end

-- save config
function M.saveConfig()
    if configModified then
        local json = vim.fn.json_encode(PROJECT_CONFIG)
        local file = M.getConfigPath()
        local dir = vim.fs.dirname(file)

        if vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir)
        end
        vim.fn.writefile({ json }, file)
        configModified = false
    end
end

-- loader config
function M.loaderConfig()
    local file, readable = M.getConfigPath()

    if not readable then
        return
    end

    local config = vim.fn.json_decode(vim.fn.readfile(file))
    if config.options then
        for option, value in pairs(config.options) do
            vim.o[option] = value
        end
    end
end

-- set or print the value of the option.
function M.option(argv)
    local opt = argv.fargs[1]
    local value = argv.fargs[2]
    vim.o[opt] = value
    if value then
        PROJECT_CONFIG.options[opt] = value
        configModified = true
    else
        print(PROJECT_CONFIG.options[opt])
    end
end

-- create or open a hook script.
function M.openHook(argv)
    local dir, isdir = M.getHookPath()

    if not isdir then
        vim.fn.mkdir(dir, "p")
    end
    vim.cmd.edit(dir .. "/" .. argv.fargs[1])
end

-- execute all shell scripts
function M.runHook(config)
    local shell = config.shell
    local dir, isdir = M.getHookPath()

    if not isdir or not config.enable_hook then
        return
    end
    if type(config.enable_hook) == "string" then
        if not M.isSubFile(config.enable_hook, dir) then
            return
        end
    elseif vim.tbl_islist(config.enable_hook) then
        for _, parentDir in pairs(config.enable_hook) do
            assert(type(parentDir) == "string", "when enable_hook is a list, the elements of the list must be string.")
            if M.isSubFile(parentDir, dir) then
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
    local dir = M.getHookPath()

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

function M.getConfigPath()
    local win = vim.api.nvim_get_current_win()
    local file = vim.fn.getcwd(win) .. "/" .. BASE_DIR .. "/config.json"
    return file, vim.fn.filereadable(file) == 1
end

function M.getHookPath()
    local win = vim.api.nvim_get_current_win()
    local dir = vim.fn.getcwd(win) .. "/" .. BASE_DIR .. "/hook"
    return dir, vim.fn.isdirectory(dir) == 1
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

function M.handlerConfig(config)
    assert(not config or type(config) == "table", "the config parameter must be table or nil")
    if config then
        config = setmetatable(config, { __index = default })
    else
        config = default
    end
    if type(config.enable_hook) == "string" then
        config.enable_hook = vim.fs.normalize(config.enable_hook)
    elseif vim.tbl_islist(config.enable_hook) then
        for index = 1, #config.enable_hook do
            config.enable_hook[index] = vim.fs.normalize(config.enable_hook[index])
        end
    elseif type(config.enable_hook) ~= "boolean" then
        error "enable_hook must be a string, a list or a boolean."
    end
    return config
end

return { setup = M.setup }
