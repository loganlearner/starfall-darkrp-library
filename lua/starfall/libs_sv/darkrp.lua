if engine.ActiveGamemode() ~= "darkrp" then return end
util.AddNetworkString("sf_moneyrequest")
util.AddNetworkString("sf_moneyrequest_accept")
util.AddNetworkString("sf_moneyrequest_deny")

local moneyRequestIndex = 1
local moneyRequests = {}
local checkluatype = SF.CheckLuaType

SF.RegisterLibrary("darkrp")

return function(instance)

local owner, checktype = instance.player, instance.CheckType
local darkrp_library = instance.Libraries.darkrp
local unwrap = instance.Types.Player.Unwrap
local ply_methods = instance.Types.Player.Methods

local function getply(self)
    local ent = unwrap(self)

    if ent:IsValid() then
        return ent
    else
        SF.Throw("Entity is not valid.", 3)
    end
end

local function getMoneyRequestFromIndex(index)
    for _, request in pairs(moneyRequests) do
        if request.index == index then
            return request
        end
    end
end

local function payPlayer(ply1, ply2, amount)
    ply1:ChatPrint("You gave " .. ply2:Name() .. " " .. DarkRP.formatMoney(amount) .. "!")
    ply2:ChatPrint(ply1:Name() .. " gave you " .. DarkRP.formatMoney(amount) .. "!")

    DarkRP.payPlayer(ply1, ply2, amount)
end

function ply_methods:getMoney()
    return getply(self).DarkRPVars.money
end

function ply_methods:giveMoney(amount)
    checkluatype(amount, TYPE_NUMBER)
    local givee = getply(self)

    if owner:canAfford(amount) then
        payPlayer(owner, givee, amount)
    else
        DarkRP.notify(owner, 1, 4, DarkRP.getPhrase("cant_afford", ""))
    end
end

function ply_methods:requestMoney(amount, callbackSuccess, callbackFail, callbackTimeout)
    local requester = owner
    local requestee = getply(self)

    checkluatype(amount, TYPE_NUMBER)
    checkluatype(callbackSuccess, TYPE_FUNCTION)
    if callbackFail then checkluatype(callbackFail, TYPE_FUNCTION) end
    if callbackTimeout then checkluatype(callbackTimeout, TYPE_FUNCTION) end

    amount = math.Clamp(amount, 0, math.huge)

    local request = {
        index = moneyRequestIndex,
        requester = requester,
        requestee = requestee,
        amount = amount,
        expiration = CurTime() + 30,
        success = function()
            callbackSuccess()
        end,
        fail = function(failReason)
            callbackFail(failReason)
        end,
        timeout = function()
            callbackTimeout()
        end
    }


    if requestee:canAfford(amount) then
        net.Start("sf_moneyrequest")
            net.WriteFloat(moneyRequestIndex)
            net.WriteEntity(requester)
            net.WriteFloat(math.Round(amount))
        net.Send(requestee)

        table.insert(moneyRequests, request)
    else
        DarkRP.notify(requester, 1, 4, "The user cannot afford this")
        request.fail("REQUEST_NOMONEY")
    end

    moneyRequestIndex = moneyRequestIndex + 1
end

net.Receive("sf_moneyrequest_accept", function()
    local index = net.ReadFloat()
    local request = getMoneyRequestFromIndex(index)

    payPlayer(request.requestee, request.requester, request.amount)
    request.success()

    table.RemoveByValue(moneyRequests, request)
end)

net.Receive("sf_moneyrequest_deny", function()
    local index = net.ReadFloat()
    local request = getMoneyRequestFromIndex(index)

    request.fail("REQUEST_DENIED")

    table.RemoveByValue(moneyRequests, request)
end)

function darkrp_library.formatMoney(amount)
    checkluatype(amount, TYPE_NUMBER)
    return DarkRP.formatMoney(amount)
end

hook.Add("Tick", "sf_dark_timeout_check", function()
    for _, request in pairs(moneyRequests) do
        if CurTime() >= request.expiration then
            request.timeout()

            table.RemoveByValue(moneyRequests, request)
        end
    end
end)

end
