
local IndexAction = class("IndexAction")

function IndexAction:ctor(app)
    self._app = app
end

function IndexAction:indexAction(arg)
    if arg.name then
        return self:_getPackageData(arg.name)
    elseif arg.keyword then
        return self:_searchPackages(arg.keyword)
    else
        ngx.status = 403
        ngx.exit(ngx.OK)
    end
end

function IndexAction:_getPackageData(name)
    name = string.trim(string.lower(name))
    if name == "" then
        throw("not specifies package name")
    end

    local index = self:_loadPackagesIndex()
    for _, package in pairs(index) do
        if package.name == name then
            return package
        end
    end
    throw("not found package \"%s\"", name);
end

function IndexAction:_searchPackages(keyword)
    keyword = string.trim(string.lower(keyword))
    if name == "" then
        keyword("not specifies search keyword")
    end

    local index = self:_loadPackagesIndex()
    local keywordlen = string.len(keyword)
    local result = {}
    for _, package in pairs(index) do
        if string.sub(package.name, 1, keywordlen) == keyword then
            result[package.name .. "-" .. package.version] = package
        end
    end
    return result
end

function IndexAction:_loadPackagesIndex()
    local packagesIndexDbPath = "/mnt/dualface/Works/package-manager/repo/packages.json"
    return json.decode(io.readfile(packagesIndexDbPath))
end

return IndexAction
