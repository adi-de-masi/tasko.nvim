## Reload Plugin
```
:lua require("lazy.core.loader").reload("tasko")
```

## Tests

```lua
nvim --headless -c 'PlenaryBustedFile lua/spec/tasko/utils.spec.lua'
```

```lua

nvim --headless -c 'PlenaryBustedDirectory lua/spec/tasko/'
```
