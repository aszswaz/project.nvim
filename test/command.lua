local command = require "project.command"

function testCommand()
    command.create {
        name = "Demo",
        script = "demo.sh",
        terminal = true,
    }
end
