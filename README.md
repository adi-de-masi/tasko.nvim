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

Tasko stores all tasks as markdown files in a subdirectory of `vim.fn.stdpath("data")`,
typically resolving to `~/.local/share/nvim/tasko`  on unix systems.

These markdown files have the following format:

```markdown
# Heading 1 = title

Anything below = description.

Important: Somewhere in the file, ideally at the end, you need the task metadata formatted
as such:

-- id: 
-- provider_id: 
-- priority: 1
-- due: "2024-11-23"
-- is_completed: false
-- updated_time: 
-- edited_time: 
```
- `TaskoList` Displays all tasks you haven't completed yet. Options: `today` = shows only tasks you marked as due today or that are already overdue.
- `TaskoNew` Creates a new task locally. The new markdown file is written to disk with the title you gave. To sync it, use `TaskoPush`
- `TaskoPush` When editing a task, this command will send the updates to the server.
- `TaskoFetch` Overrides the current task with the version that's stored on the provider side.
- `TaskoFetchAll` Fetches all open tasks from the provider, overriding all local tasks.
- `TaskoSyncAll` Synchronizes your tasks with the server as follows: Fetches new tasks and overrides unedited local tasks with the server state.
Pushes new and edited tasks to the server.
- `TaskoDone` Marks a task both locally and server-side as done. Remark: Updating the `-- is_completed: true|false` meta information has no effect on the provider.
- `TaskoReopen` Reopens a closed task both locally and server-side.


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
