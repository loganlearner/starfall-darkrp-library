if engine.ActiveGamemode() ~= "darkrp" then return end

local moneyRequests = {}
local checkluatype = SF.CheckLuaType

SF.RegisterLibrary("darkrp")

return function(instance)

local owner, checktype = instance.player, instance.CheckType
local darkrp_library = instance.Libraries.darkrp
local unwrap = instance.Types.Player.Unwrap
local ply_meta, ply_methods = instance.Types.Player, instance.Types.Player.Methods

local function getply(self)
    local ent = unwrap(self)

    if ent:IsValid() then
        return ent
    else
        SF.Throw("Entity is not valid.", 3)
    end
end

function ply_methods:getMoney()
    return getply(self).DarkRPVars.money
end

function ply_methods:giveMoney(amount)
    checkluatype(amount, TYPE_NUMBER)
    local givee = getply(self)

    if owner:canAfford(amount) then
        owner:ChatPrint("You gave " .. givee:Name() .. " " .. DarkRP.formatMoney(amount) .. "!")
        givee:ChatPrint(owner:Name() .. " gave you " .. DarkRP.formatMoney(amount) .. "!")
        DarkRP.payPlayer(owner, givee, amount)
    else
        DarkRP.notify(owner, 1, 4, DarkRP.getPhrase("cant_afford", ""))
    end
end

--[[
function ply_methods:requestMoney(amount, callbackSuccess, callbackFail, callbackTimeout)
    --instance:runFunction(callback, ...)
    local requestee = getply(self)

    checkluatype(amount, TYPE_NUMBER)
    checkluatype(callbackSuccess, TYPE_FUNCTION)
    if callbackFail then checkluatype(callbackFail, TYPE_FUNCTION) end
    if callbackTimeout then checkluatype(callbackTimeout, TYPE_FUNCTION) end

    if requestee:canAfford(amount) then
        
    end
end
]]

function darkrp_library.formatMoney(amount)
    checkluatype(amount, TYPE_NUMBER)
    return DarkRP.formatMoney(amount)
end

end