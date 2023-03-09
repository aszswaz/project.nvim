# Introduction

"project.nvim" supports the following functions:
    1. neovim options localization management.
    2. External shell scripts are mapped to neovim commands.

At some point, when we open neovim in a certain directory, we need to
configure some neovim options for this directory. For example, use ctags to
generate a .tags file, in order to allow neovim to use it, we must execute
`set tags = ./.tags`, but at this time the value of the option tags is
only applicable to the current directory, not suitable for other directory,
we can execute |:ProjectEdit| to open the .nvim/autoset.vim file, and
|project.nvim| will execute it automatically.

When we use ctags to generate tags files, we usually need to pass some
parameters to ctags so that it can generate the tags files we expect.
We can use the command `:ProjectCmd --enable-autostart Ctags` to create a shell
script to execute ctags, :ProjectCmd will save the script in the
`.nvim/script` directory, and will register a user-commands "Ctags",
"Ctags" will use |jobstart| to execute the script, and "--autostart" means
that this script should be executed automatically when neovim is started in
the current directory.

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
        autostart supports three types of value: boolean, string, list.
        autostart = false, disable shell script execution when neovim is started.
        autostart = true, allows shell scripts to be executed when neovim starts.
        autostart = "~/", executes shell scripts when neovim starts in the specified directory and subdirectories.
        autostart = { "~/", "/dev/shm" }, ditto.
    --]]
    autostart = false,
    -- specify the interpreter to execute the script. Bash si recommended.
    shell = vim.o.shell,
}
```

# How to use?

```vimscript
" Edit the .nvim/autoset.vim file.
:ProjectEdit

" Create a shell script and register a user-commands to execute the script, --autostart means that the script needs to be executed automatically when neovim starts.
:ProjectCmd --autostart Demo

" Remove shell scripts, and user-commands.
:ProjectCmdDel Demo
```
