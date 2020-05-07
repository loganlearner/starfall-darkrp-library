if engine.ActiveGamemode() ~= "darkrp" then return end
util.AddNetworkString("sf_moneyrequest")

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

function ply_methods:requestMoney(amount, callbackSuccess, callbackFail)
    local requestee = getply(self)

    checkluatype(amount, TYPE_NUMBER)
    checkluatype(callbackSuccess, TYPE_FUNCTION)
    if callbackFail then checkluatype(callbackFail, TYPE_FUNCTION) end
    if callbackTimeout then checkluatype(callbackTimeout, TYPE_FUNCTION) end


    local request = {
        index = ...,
        requester = owner,
        requestee = requestee,
        amount = amount,
        success = function()
            callbackSuccess()
        end,
        fail = function(failReason)
            callbackFail(failReason)
        end
    }

    if requestee:canAfford(amount) then
        net.Start("sf_moneyrequest")

        net.Send(requestee)

        table.insert(moneyRequests, request)
    else
        DarkRP.notify(owner, 1, 4, "The user cannot afford this")
        request.fail("REQUEST_NOMONEY")
    end

    request.fail("REQUEST_UNKNOWN")
end

function darkrp_library.formatMoney(amount)
    checkluatype(amount, TYPE_NUMBER)
    return DarkRP.formatMoney(amount)
end

end