local command = require "project.command"

-- 对 command 进行单元测试

function testCreateCommand()
    command.create {
        name = "Demo",
        script = "demo.sh",
        terminal = false,
        autostart = true,
    }
end

function testStart()
    command.start()
end
