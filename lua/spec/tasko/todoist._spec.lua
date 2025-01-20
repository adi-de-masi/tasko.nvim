local T = require "tasko.providers.todoist"
local Task = require "tasko.task"
local Store = require "tasko.store"
describe("todoist api", function()
  it("lists all tasks", function()
    local tasks = T:query_all "tasks"
    for key, value in ipairs(tasks) do
      local task = Task:new(value["id"], value["content"], value["description"])
      tasks[key] = task
    end
    assert.is_string(
      tasks[1].title,
      "The first task has no title. This could mean, Adi has no tasks currently or we have an issue"
    )
  end)

  it("converts todoist to tasko", function()
    local todoist_response =
      '{"id":"8684382473","assigner_id":null,"assignee_id":null,"project_id":"2309463793","section_id":null,"parent_id":null,"order":62,"content":"test eins zwei","description":"deeescription","is_completed":false,"labels":[],"priority":4,"comment_count":0,"creator_id":"43441817","created_at":"2024-12-16T10:21:52.049422Z","due":null,"url":"https://app.todoist.com/app/task/8684382473","duration":null,"deadline":null}'
    local task = T:to_task(vim.json.decode(todoist_response))
    assert(task.provider_id == "8684382473", "The provider_id is not correct: " .. task.provider_id)
    assert(task.title == "test eins zwei", "The title is not correct")
    assert(task.description == "deeescription", "The description is not correct")
    assert(task.priority == 1, "The priority is not correct")
    assert(task.is_completed == false, "The task is completed but shouldn't be")
  end)

  it("creates a task", function()
    local task = Task:new("id-flurrrrrr", "title-flurrrrrr", "description-flurrrrrr")
    Store:write(task)
    local response = T:new_task(task)
    -- TODO: Remove task from Todoist
    Store:delete(task.id)
    assert(response["id"] ~= nil, "The task was not created")
  it("maps the priority", function()
    assert(T:map_priority(1) == 4, "The priority is not correct")
    assert(T:map_priority(2) == 3, "The priority is not correct")
    assert(T:map_priority(3) == 2, "The priority is not correct")
    assert(T:map_priority(4) == 1, "The priority is not correct")
  end)
end)
