local curl = require "plenary.curl"
local Task = require "tasko.task"
local TASKS_URL = "https://api.todoist.com/rest/v2/tasks"
local PROJECTS_URL = "https://api.todoist.com/rest/v2/projects"

local tdst = {}

local function get_api_key()
  local token = os.getenv "TODOIST_API_KEY"
  assert(token ~= nil, "Failed to initialize Todoist - TODOIST_API_KEY not set")
  return token
end

local function _get_headers(hasJsonBody)
  local headers = {
    ["Authorization "] = "Bearer " .. get_api_key(),
  }
  if hasJsonBody then
    headers["Content-Type"] = "application/json"
  end
  return headers
end

local function _get_json_encoded_parameters(task)
  return vim.fn.json_encode {
    content = task.title,
    id = task.provider_id,
    description = task.description,
    priority = task.priority,
    is_completed = task.is_completed,
  }
end

local function exec_curl(method, url, body)
  local response = {}
  local status = nil
  local callback = function(res)
    status = res.status
    if res.status < 300 then
      response = vim.json.decode(res["body"])
    end
  end
  local job
  if method == "get" then
    job = curl.get(url, { headers = _get_headers(false), callback = callback })
  elseif method == "post" then
    job = curl.post(url, { headers = _get_headers(true), body = body, callback = callback })
  end
  job:wait()
  assert(status == 200, "Todoist returned something other than 200: " .. status)
  return response
end

local function post(url, body)
  return exec_curl("post", url, body)
end

function tdst:query_projects(callback)
  local headers = _get_headers(false)
  local res = curl.get(PROJECTS_URL, { headers = headers, callback = callback })
  return res
end

function tdst:to_task(todoist_response_body)
  local title = string.gsub((todoist_response_body["content"] or ""), "\n", "")
  local due = todoist_response_body["due"] == vim.NIL and "" or todoist_response_body["due"]["date"]
  local task = Task:new(
    tonumber(todoist_response_body["id"]),
    title,
    todoist_response_body["description"],
    tonumber(todoist_response_body["priority"]),
    due,
    todoist_response_body["is_completed"]
  )
  local provider_id = todoist_response_body["id"]
  task.set_provider_id(provider_id)
  return task
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
    return exec_curl("get", TASKS_URL)
  elseif type == "projects" then
    job = self:query_projects(callback)
  else
    return nil
  end
  job:wait()
  assert(status == 200, "Todoist did not answer with 200")
  return response
end

function tdst:get_task_by_id(id)
  local todoist_response = exec_curl("get", vim.fs.joinpath(TASKS_URL, id))
  return self:to_task(todoist_response)
end

--- @param id string
function tdst:complete(id)
  local status = nil
  local callback = function(res)
    status = res.status
  end
  local headers = _get_headers(false)
  local url = TASKS_URL .. "/" .. id .. "/close"
  local job = curl.post(url, { headers = headers, callback = callback })
  job:wait()
  assert(status < 300, "Todoist did not answer with 200")
  print "marked task as done"
end

function tdst:new_task(task)
  local response = {}
  local status = nil
  local callback = function(res)
    status = res.status
    response = vim.json.decode(res["body"])
  end
  local headers = _get_headers(true)
  local body = _get_json_encoded_parameters(task)
  local job = curl.post(TASKS_URL, { headers = headers, body = body, callback = callback })
  job:wait()
  assert(status == 200, "Todoist did not answer with 200")
  task.set_provider_id(response["id"])
  task.priority = response["priority"]
  print("Successfully created task " .. task.provider_id)
  return task
end

function tdst:update(task)
  local body = _get_json_encoded_parameters(task)
  local response = post(TASKS_URL .. "/" .. task.provider_id, body)
  print("Updated task " .. task.provider_id)
  return response
end

function tdst:delete_task(id)
  local headers = _get_headers(false)
  local res = curl.delete(TASKS_URL .. "/" .. id, { headers = headers })
  return res
end

function tdst:add_project(params)
  local headers = _get_headers(true)
  local body = vim.fn.json_encode(params)
  local res = curl.post(PROJECTS_URL, { headers = headers, body = body })
  return res
end

return tdst
