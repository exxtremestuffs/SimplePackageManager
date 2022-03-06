local HttpService = game:GetService("HttpService")
local GITHUB_URL = "https://raw.githubusercontent.com/"

local SP = {}

type Project = {
	name: string,
	author: string,
	src: string,
	init: string,
}

function request(url: string)
	syn.request({
		Url = url,
		Method = "GET",
	})
end

function getProjectFromPackage(packageName: string)
	assert(type(packageName) == "string", string.format("packageName must be a string, got %s", type(packageName)))
	local author, repo = string.match(packageName, "^(%a+)%/(%a+)$")
	assert(
		author and repo,
		string.format("packageName is formatted improperly as '%s', should be 'author/repo'", packageName)
	)

	local err, project: Project | string = pcall(function()
		return HttpService:JSONDecode(request(string.format("%s%s/%s/project.json", GITHUB_URL, author, repo)))
	end)

	assert(not err, string.format("Failed to import package '%s'\n%s", packageName, project))
	assert(type(project.name) == "string", string.format("package '%s' has no name", packageName))
	assert(type(project.author) == "string", string.format("package '%s' has no author", packageName))
	assert(type(project.src) == "string", string.format("package '%s' has no src folder", packageName))
	assert(type(project.init) == "string", string.format("package '%s' has no init file", packageName))
end

function SP:setCurrentProject(packageName: string)
	self.currentProject = getProjectFromPackage(packageName)
	return self
end

function SP:require(path: string, project: Project?)
	assert(type(path) == "string", string.format("Expected string, got %s", type(path)))
	local path = {}
	for part in path:gmatch("%.*(%a+)%.*") do
		table.insert(path, part)
	end
	assert(#path > 0, "path must contain at least one part")

	local pathStr = table.concat(path, "/")
	local err, module: string = pcall(function()
		return loadstring(request(string.format("%s%s/%s/.lua", GITHUB_URL, project or self.currentProject, pathStr)))()
	end)

	assert(not err, string.format("Failed to load module '%s'\n%s", table.concat(path, "."), module))
	return module
end

function SP:import(packageName: string)
	local project = getProjectFromPackage(packageName)
	return self:require(project.src .. project.init, project)
end

return SP
