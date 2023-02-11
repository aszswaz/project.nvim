local command = require "project.command"

-- 对 command 进行单元测试

-- shell script 映射为 user-commands，执行设置了 autostart 的 shell script
function testStart()
    command.start()
end

-- 创建脚本并映射为 user-commands
function testCreate()
    command.create {
        name = "Demo",
        script = "demo.sh",
        terminal = true,
        autostart = false,
    }
end

-- 执行脚本
function testRun()
end
