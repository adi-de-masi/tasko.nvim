local Store = require("tasko.store")
local Path = require("plenary.path")
local Task = require("tasko.task")

describe("Store", function()
	local function delete_test_files(files)
		for _, file in ipairs(files) do
			Path:new(file):rm()
		end
	end

	-- it("Write returns the filename", function()
	-- 	local file = Store:write(Task:new(1, "title", "my description", 4, false))
	-- 	assert(file, "no filename returned")
	-- 	assert(string.find(file, "/tasko/1%.md$") ~= nil, "wrong filename returned: " .. file)
	-- 	delete_test_files({ file })
	-- end)

	it("Lists two files per task in one table", function()
		local files1 = Store:write(Task:new(1, "title", "my description", 4, false))
		local files2 = Store:write(Task:new(2, "title2", "my description", 4, false))
		local files3 = Store:write(Task:new(3, "title3", "my description", 4, false))
		local task_list = Store:list_tasks()
		for i = 1, 2, 3 do
			assert(string.find(task_list[tostring(i)], "md$") ~= nil, "no markdown file found")
		end
		delete_test_files({ files1, files2, files3 })
	end)

	-- it("writes a task to json", function()
	-- 	local files = Store:write(Task:new(1, "title", "my description", 4, false))
	-- 	local task = Store:get_task_from_paths(files.task_file, files.task_description_file)
	-- 	assert(task.id == 1, "id could not be read")
	-- 	assert(task.title == "title", "title could not be read")
	-- 	assert(task.description == "my description", "description could not be read")
	-- 	assert(task.priority == 4, "priority could not be read")
	-- 	assert(task.is_completed == false, "is_completed could not be read")
	-- 	delete_test_files(files)
	-- end)
	--
	-- it("considers the description", function()
	-- 	local files = Store:write(Task:new(1, "title", "my description", 4, false))
	-- 	local new_description = "new description"
	-- 	Path:new(files.task_description_file):write(new_description, "w")
	-- 	local task = Store:get_task_from_paths(files.task_file, files.task_description_file)
	-- 	assert(task.id == 1, "id could not be read")
	-- 	assert(task.title == "title", "title could not be read")
	-- 	assert(task.description == "new description", "description could not be read")
	-- 	assert(task.priority == 4, "priority could not be read")
	-- 	assert(task.is_completed == false, "is_completed could not be read")
	-- 	delete_test_files(files)
	-- end)
end)
