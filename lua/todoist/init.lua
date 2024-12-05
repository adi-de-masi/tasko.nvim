local curl = require("plenary.curl")
local Store = require("tasko.store")
local TASKS_URL = "https://api.todoist.com/rest/v2/tasks"
local PROJECTS_URL = "https://api.todoist.com/rest/v2/projects"

local tdst = {}

--- @class Todoist
--- @field token string
Todoist = {
	todayTasks = {},
	overdueTasks = {},
}

local function get_api_key()
	local token = os.getenv("TODOIST_API_KEY")
	if token == nil then
		return nil
	end
	return token
end

function tdst:_get_headers(hasJsonBody)
	local headers = {
		["Authorization "] = "Bearer " .. self.token,
	}
	if hasJsonBody then
		headers["Content-Type"] = "application/json"
	end
	return headers
end

--- @class TaskQueryParams
--- @field project_id string | nil
--- @field filter string | nil

--- @param query TaskQueryParams
function tdst:query_tasks(query, callback)
	local headers = self:_get_headers(false)
	local res = curl.get(TASKS_URL, { headers = headers, query = query, callback = callback })
	return res
end

function tdst:query_projects(callback)
	local headers = self:_get_headers(false)
	local res = curl.get(PROJECTS_URL, { headers = headers, callback = callback })
	return res
end

function tdst:query_all(type)
	local job
	local response = {}
	local status = nil
	local callback = function(res)
		status = res.status
		response = vim.json.decode(res["body"])
	end
	if type == "tasks" then
		job = self:query_tasks({}, callback)
	elseif type == "projects" then
		job = self:query_projects(callback)
	else
		return nil
	end
	job:wait()
	assert(status == 200, "Todoist did not answer with 200")
	return response
end

--- @param id string
function tdst:complete(id)
	local headers = self:_get_headers(false)
	local url = TASKS_URL .. "/" .. id .. "/close"
	local res = curl.post(url, { headers = headers })
	return res
end

function tdst:new_task(params)
	local headers = self:_get_headers(true)
	local body = vim.fn.json_encode(params)
	local res = curl.post(TASKS_URL, { headers = headers, body = body })
	return res
end

--- @param id string
function tdst:update(id)
	local response = {}
	local status = nil
	local callback = function(res)
		status = res.status
		response = vim.json.decode(res["body"])
	end

	local headers = self:_get_headers(true)
	local task = Store:get_task_by_id(id)
	local body = vim.fn.json_encode({
		content = task.title,
		id = task.todoist_id,
		description = task.description,
		priority = task.priority,
		is_completed = task.is_completed,
	})
	print("updating todoist now! ")
	local job = curl.post(TASKS_URL .. "/" .. id, { headers = headers, body = body, callback = callback })
	job:wait()
	assert(status == 200, "Todoist returned something other than 200: " .. status)
	print("update complete")
	return response
end

function tdst:delete_task(id)
	local headers = self:_get_headers(false)
	local res = curl.delete(TASKS_URL .. "/" .. id, { headers = headers })
	return res
end

function tdst:add_project(params)
	local headers = self:_get_headers(true)
	local body = vim.fn.json_encode(params)
	local res = curl.post(PROJECTS_URL, { headers = headers, body = body })
	return res
end

local Todoist = {}

function Todoist:new()
	local o = tdst
	setmetatable(o, self)
	self.__index = self
	local token = get_api_key()
	if token == nil then
		print("Failed to initialize Todoist - TODOIST_API_KEY not set")
		return nil
	end
	o.token = token
	return o
end

return Todoist
