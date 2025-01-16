local utils = require "tasko.utils"
local Task = require "tasko.task"

describe("TaskoList utils", function()
  it("get_display_string without edited_time", function()
    local task = Task:new(1, "my title", "my description", 3, "2025-01-03", false)
    local display_string = utils.get_display_string(task)
    assert(display_string == "3 my title", "Display string not as expected: " .. display_string)
  end)

  it("creates an ordinal with title and description", function()
    local task = Task:new(1, "my title", "my description", 3, "2025-01-03", false)
    local ordinal = utils.to_ordinal(task)
    assert(
      ordinal == "--priority: 3 --due: 2025-01-03 3 my title my description 1",
      "Ordinal not as expected: " .. ordinal
    )
  end)

  it("creates an ordinal with title but no description", function()
    local task = Task:new(1, "my title", nil, 3, "2025-01-03", false)
    local ordinal = utils.to_ordinal(task)
    assert(ordinal == "--priority: 3 --due: 2025-01-03 3 my title  1", "Ordinal not as expected: " .. ordinal)
  end)

  it("gets the due date from the ordinal", function()
    local task = Task:new(1, "my title", "my description", 3, "2025-01-03", false)
    local due_date = utils.get_due_date_from_ordinal(utils.to_ordinal(task))
    assert(due_date == 1735902000, "Due date not found in ordinal: " .. due_date)
  end)

  it("gets nil as due date from the ordinal", function()
    local task = Task:new(1, "my title", "my description", 3, nil, false)
    local due_date = utils.get_due_date_from_ordinal(utils.to_ordinal(task))
    assert(due_date == nil, "Due date not nil")
  end)

  it("gets the priority from the ordinal", function()
    local task = Task:new(1, "my title", "my description", 3, "2025-01-03", false)
    local priority = utils.get_priority_from_ordinal(utils.to_ordinal(task))
    assert(priority == 3, "Priority not found in ordinal.")
  end)

  it("calculates the time difference", function()
    local original_os_time = os.time

    -- Perform the test
    local target_date = os.time {
      year = 2025,
      month = 1,
      day = 10,
      hour = 0,
      min = 0,
      sec = 0,
    }

    local from_date = os.time {
      year = 2025,
      month = 1,
      day = 3,
      hour = 0,
      min = 0,
      sec = 0,
    }

    -- Mock os.time to return January 3, 2025, 00:00:00
    os.time = function()
      return original_os_time {
        year = 2025,
        month = 1,
        day = 3,
        hour = 0,
        min = 0,
        sec = 0,
      }
    end
    local result, err = utils.calculate_time_difference(target_date, from_date)

    -- Assert the result
    assert(result, "Result should not be nil")
    assert(result.days == 7, "Days difference should be 7 but is " .. result.days)
    assert(result.hours == 0, "Hours difference should be 0")
    assert(result.minutes == 0, "Minutes difference should be 0")
    assert(result.total_seconds == 7 * 24 * 60 * 60, "Total seconds difference should be correct")

    -- Restore the original os.time
    os.time = original_os_time
  end)
end)

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

describe("parse_iso8601", function()
  it("parses an ISO8601 date", function()
    local date = utils.parse_iso8601 "2025-01-03T12:00:00Z"
    assert.is_equal(1735902000, date)
  end)
end)
