local HttpService = game:GetService("HttpService")
local GITHUB_URL = "https://raw.githubusercontent.com/"

local SP = {}

-- type Project = {
-- 	name: string,
-- 	author: string,
-- 	src: string,
-- 	init: string,
--  branch: string?,
-- }

function request(url)
	local response = syn.request({
		Url = url,
		Method = "GET",
	})
	assert(response.Success, string.format("Failed to request '%s'", url))
	return response.Body
end

function getProjectFromPackage(packageName, branch)
	assert(type(packageName) == "string", string.format("packageName must be a string, got %s", type(packageName)))
	local author, repo = string.match(packageName, "^(%a+)%/(%a+)$")
	assert(
		author and repo,
		string.format("packageName is formatted improperly as '%s', should be 'author/repo'", packageName)
	)

	local err, project = pcall(function()
		return HttpService:JSONDecode(
			request(string.format("%s%s/%s/%s/project.json", GITHUB_URL, author, repo, branch))
		)
	end)

	assert(
		not err,
		string.format("Failed to import package '%s'\n%s", packageName, type(project) == "string" and project or "")
	)
	assert(type(project.name) == "string", string.format("package '%s' has no name", packageName))
	assert(type(project.author) == "string", string.format("package '%s' has no author", packageName))
	assert(type(project.src) == "string", string.format("package '%s' has no src folder", packageName))
	assert(type(project.init) == "string", string.format("package '%s' has no init file", packageName))

	return project
end

function SP:setCurrentProject(packageName, branch)
	self.currentProject = getProjectFromPackage(packageName, branch or "master")
	return self
end

function SP:require(path, project)
	assert(type(path) == "string", string.format("Expected string, got %s", type(path)))
	assert(self.currentProject, "No current project set")
	local path = {}
	for part in path:gmatch("%.*(%a+)%.*") do
		table.insert(path, part)
	end
	assert(#path > 0, "path must contain at least one part")

	local pathStr = table.concat(path, "/")
	local err, module = pcall(function()
		return loadstring(
			request(
				string.format(
					"%s%s/%s/%s/.lua",
					GITHUB_URL,
					project or self.currentProject,
					project and project.branch or self.currentProject.branch or "master",
					pathStr
				)
			)
		)()
	end)

	assert(not err, string.format("Failed to load module '%s'\n%s", table.concat(path, "."), module))
	return module
end

function SP:import(packageName, branch)
	local project = getProjectFromPackage(packageName, branch or "master")
	return self:require(project.src .. project.init, project)
end

return SP
