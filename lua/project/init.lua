local event = require "project.event"
local commands = require "project.config.commands"
local config = require "project.config"

local M = {}

function M.setup(cfg)
    config.setConfig(cfg)
    event.regEvent()
    commands.regCommands()
end

return { setup = M.setup }
