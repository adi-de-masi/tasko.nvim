local utils = require "tasko.utils"

describe("Split by newline", function()
  local result = utils.split_by_newline "Birnenbaum\nApfelbaum\nKastanienbaum"
  assert(result[1] == "Birnenbaum", "Did not find the first line.")
  assert(result[2] == "Apfelbaum", "Did not find the second line.")
end)

describe("get_buf_by_pattern", function()
  it("finds the tasks file", function()
    vim.fn.execute "edit schnarf.md"
    vim.fn.execute "edit schnirf.md"
    vim.fn.execute "edit *tasks*.md"
    local buf = utils.get_buf_by_pattern "%*tasks%*.md"
    assert.is_number(buf, "Could not identify the open tasks buffer.")
  end)
end)

describe("line_number_of", function()
  it("finds first line of pattern in a buffer", function()
    local buf = vim.api.nvim_create_buf(true, false)
    local md_comment = "[Pimmelpammel](/home/dmad/.local/share/nvim/tasko/a88454fe-5d50-4586-9173-161af7a3dc7e.md)"
    local escaped = "a88454fe%-5d50%-4586%-9173%-161af7a3dc7e"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "Birnenbaum",
      "Apfelbaum",
      "Kastanienbaum",
      md_comment,
    })
    assert.is_equal(2, utils.line_number_of(buf, "Apfelbaum"))
    assert.is_equal(4, utils.line_number_of(buf, escaped))
    assert.is_nil(utils.line_number_of(buf, "Eiche"))
  end)
end)

describe("replace_line", function()
  it("replaces a line in a buffer", function()
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "Birnenbaum",
      "Apfelbaum",
      "Kastanienbaum",
      "Eiche",
    })
    utils.replace_line(buf, 2, "Apfelbaum 2")
    assert.is_equal("Apfelbaum 2", vim.api.nvim_buf_get_lines(buf, 1, 2, false)[1])
    utils.replace_line(buf, 4, "Eiche 2")
    assert.is_equal("Eiche 2", vim.api.nvim_buf_get_lines(buf, 3, 4, false)[1])
  end)
end)
