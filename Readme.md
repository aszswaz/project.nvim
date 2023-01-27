# Introduction

`project.nvim` is a plugin for managing project configuration. For example, integrated development tools such as [IntelliJ IDEA](https://www.jetbrains.com/idea/) will save project-related configurations in the .idea folder under the project directory. I was inspired by it and developed a plug-in with similar functions for neovim.

# Features

1. Manage neovim options that apply only to current project.

2. Users can write hook scripts for the current project, and `project.nvim` will execute these scripts after neovim starts.

All configurations and hook hook scripts of the current project are saved in the `.nvim` folder.

# Install

Install `project.nvim` using the [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
require("packer").startup(function(use)
    use "aszswaz/project.nvim"
end)
```

# Quick Start

You need to call the `setup` function to load `project.nvim`:

```lua
-- Use the default configuration
require("project.nvim").setup {}

-- custom options
require("project.nvim").setup {
    --[[
        enable_hook supports three types of value: boolean, string, list.
        enable_hook = false, disable execution of project hook scripts.
        enable_hook = true, allows execution of project hook scripts, but this may pose security issues.
        enable_hook = "~/", only projects in the specified directory are allowed to execute scripts.
        enable_hook = { "~/", "/dev/shm" }, ditto.
    --]]
    enable_hook = false,
    -- specify the interpreter to execute the hook script. Bash si recommended.
    shell = vim.o.shell,
}
```

# How to use?

```vimscript
" view options
:ProjectOption filetype
" Set option parameters
:ProjectOption filetype text
" Opens the hook script, which will be created automatically if it does not exist.
:ProjectOpenHook demo.sh
" delete the hook script
:ProjectDeleteHook demo.sh
```
