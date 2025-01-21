return {
  new_task = function(task)
    print("no provider is defined, not doing anything")
    return task
  end,
  update = function(task)
    print("no provider is defined, not doing anything")
    return task
  end,
  complete = function(_)
    print("no provider is defined, not doing anything")
  end,
  reopen = function(_)
    print("no provider is defined, not doing anything")
  end,
  query_all_tasks = function(_)
    print("no provider is defined, not doing anything")
    return {}
  end,
  to_task = function(value)
    print("no provider is defined, return task as is")
    return value
  end,
}
