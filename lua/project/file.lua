local M = {}

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

return { isSubFile = M.isSubFile }
