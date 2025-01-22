# Tasko
Tasko is esperanto for Task, and it's to no surprise a task management neovim plugin. It emerged from a personal need of the author, who loves working in the console. It currently integrates minimally with Todoist, but has a modular nature and it should be easy to add support for similar services. No provider is fine as well, all tasks are stored locally anyway.

Tasko uses markdown to store all necessary information.
Task titles are expected to be formatted as `# heading 1`.

## Configuration

Lazy:
```lua
return {
  'adi-de-masi/tasko.nvim',
  dependencies = {
    { 'nvim-lua/plenary.nvim' },
    { 'nvim-telescope/telescope.nvim' },
  },
  -- optional, if omitted tasks will be stored locally in ~/.local/share/nvim/tasko
  config = function()
    require('tasko').setup {
      provider = 'todoist', -- requirement: set environment variable TODOIST_API_KEY
    }
  end,
}
```
## How it works and how to use it

Tasko stores all tasks as markdown files in a subdirectory of `vim.fn.stdpath("data")` 
which resolves to `~/.local/share/nvim` on unix systems.

These markdown files have the following format:

```markdown
# Heading 1 = title

Anything below = description.

Important: Somewhere in the file, ideally at the end, you need the task metadata formatted
as such:

-- key: value
-- id: an-id-3524
-- priority: 1
```
- `TaskoList` Displays all tasks you haven't completed yet. Options: `today` = shows only tasks you marked as due today or that are already overdue.
- `TaskoNew` Creates a new task locally. The new markdown file is written to disk with the title you gave.
- `TaskoPush` Optional for users who like to send their tasks to an upstream service like Todoist. The current buffer must be a tasko task.
- `TaskoFetch` Overrides the current task with the version that's stored on the provider side.
- `TaskoFetchAll` Fetches all open tasks from the provider.
- `TaskoDone` Marks a task as done. Remark: Updating the `-- is_completed: true|false` meta information has no effect on the provider.


## Contributing
### Executing Tests

```lua
nvim --headless -c 'PlenaryBustedFile lua/spec/tasko/utils.spec.lua'
```

```lua

nvim --headless -c 'PlenaryBustedDirectory lua/spec/tasko/'
```

### Reloading the Plugin

```lua
:lua require("lazy.core.loader").reload("tasko.nvim")
```
