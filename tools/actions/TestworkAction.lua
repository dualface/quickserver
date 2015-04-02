local TestworkAction = class("Testwork")

function TestworkAction:ctor(con)

end

function TestworkAction:helloAction(arg)
    return {res = string.format("say %s in %s later.", arg.name, arg.delay)}
end

return TestworkAction
