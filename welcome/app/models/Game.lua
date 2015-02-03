
local Game = class("Game")

Game.BATTLE_ZONE_SIZE = {width = 480, height = 854}

local _BATTLE_CHANNEL = "_BATTLE"

function Game:subscribeBattleChannel()
    self:subscribeChannel(_BATTLE_CHANNEL, function(payload)
        -- forward message to connect
        self._socket:send_text(payload)
        return true
    end)
end

function Game:unsubscribeBattleChannel()
    self:unsubscribeChannel(_BATTLE_CHANNEL)
end

function Game:sendMessageToBattleChannel(message)
    self:sendMessageToChannel(_BATTLE_CHANNEL, message)
end


return Game
