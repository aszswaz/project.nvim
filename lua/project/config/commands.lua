local neovim = require "project.neovim"
local hook = require "project.hook"

return {
    {
        name = "ProjectOption",
        action = neovim.option,
        attributes = {
            nargs = "+",
            complete = "option",
            desc = "set the neovim option, which only works on the current project.",
        },
    },
    {
        name = "ProjectOpenHook",
        action = hook.openHook,
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
        action = hook.deleteHook,
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
            hook.runHook()
        end,
        attributes = {
            nargs = 0,
            desc = "re-execute the script.",
        },
    },
}
