local Task = require("tasko.task")

describe("text to task", function()
	it("Creates a task", function()
		local task = Task:new(nil, "This is my test Task", "This is the body of my test task")
		assert(task.title == "This is my test Task", "Title couldn't be parsed.")
		assert.is_not_nil(task.id)
	end)

	it("converts a tasko file to a task", function()
		local json_representation = [[
      {
        "id": 1,
        "title": "This is my test task",
        "description": "This is the body of my test task",
        "priority": 4,
        "is_completed": false
      }
    ]]
		local task = Task:from_json(json_representation)
		assert(task.id == 1, "Task Id couldn't be parsed.")
		assert(task.title == "This is my test task", "Title couldn't be parsed.")
		assert(task.description == "This is the body of my test task", "Description couldn't be parsed.")
		assert(task.priority == 4, "Priority couldn't be parsed.")
		assert(task.is_completed == false, "Is completed couldn't be parsed.")
	end)
end)
