
local HelpTool = class("HelpTool", cc.server.ActionBase)

function HelpTool:indexAction()
    print([[

usage: tools <action> [arg] [arg]

example:
    * show this help
    tools help

    * show the tail of nginx log 
    tools example.server.taillog 5 

]])

end

return HelpTool
