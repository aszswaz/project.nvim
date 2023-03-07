-- 将当前存储库设置到 runtimepath
local debugInfo = debug.getinfo(1, "S")
local source = string.sub(debugInfo.source, 2, -1)
source = vim.fn.split(source, "/")
local strings = {}
for index = 1, (#source - 2) do
    strings[index] = source[index]
end
local runtimePath = vim.api.nvim_list_runtime_paths()
runtimePath[1] = "/" .. vim.fn.join(strings, "/")
vim.o.runtimepath = vim.fn.join(runtimePath, ",")

require("project").setup {
    autostart = { "~/Documents/project/aszswaz", "/dev/shm" },
    shell = "/usr/bin/bash",
}
