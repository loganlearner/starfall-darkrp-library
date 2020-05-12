if engine.ActiveGamemode() ~= "darkrp" then return end

local moneyRequestIndex = 0
local moneyRequests = {}
local checkluatype = SF.CheckLuaType
local checkpermission = SF.Permissions.check
local registerprivilege = SF.Permissions.registerPrivilege
local drp_shipments
local latestRequests
local requestThrottle = 0.1

-- Waiting for the CustomShipments table to load
timer.Simple(1, function()
    drp_shipments = CustomShipments
end)

local falseShipment = {
    name = "Invalid Shipment",
    amount = -1,
    price = -1,
    model = "models/error.mdl",
    entity = "invalid_shipment"
}

local function getMoneyRequestFromIndex(index)
    for _, request in pairs(moneyRequests) do
        if request.index == index then
            return request
        end
    end
end

local function payPlayer(ply1, ply2, amount)
    if SERVER then
        ply1:ChatPrint("You gave " .. ply2:Name() .. " " .. DarkRP.formatMoney(amount) .. "!")
        ply2:ChatPrint(ply1:Name() .. " gave you " .. DarkRP.formatMoney(amount) .. "!")

        DarkRP.payPlayer(ply1, ply2, amount)
    end
end

if SERVER then
    util.AddNetworkString("sf_moneyrequest")
    util.AddNetworkString("sf_moneyrequest_accept")
    util.AddNetworkString("sf_moneyrequest_deny")

    registerprivilege("darkrp.giveMoney", "DarkRP GiveMoney", "Allows the user to give money to other players", { entities = { default = 1 } })
    registerprivilege("darkrp.requestMoney", "DarkRP GiveMoney", "Allows the user to request money from other players", { entities = { default = 1 } })

    latestRequests = {}

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

    hook.Add("Tick", "sf_dark_timeout_check", function()
        for _, request in pairs(moneyRequests) do
            if CurTime() >= request.expiration then
                request.fail("REQUEST_TIMEOUT")

                table.RemoveByValue(moneyRequests, request)
            end
        end
    end)
end

SF.RegisterLibrary("darkrp")

return function(instance)

local darkrp_library = instance.Libraries.darkrp
local owner, checktype = instance.player, instance.CheckType
local player_methods, ents_methods = instance.Types.Player.Methods, instance.Types.Entity.Methods
local ply_meta, punwrap = instance.Types.Player, instance.Types.Player.Unwrap
local ent_meta, eunwrap = instance.Types.Entity, instance.Types.Entity.Unwrap

local function getent(self)
    local ent = eunwrap(self)
    if ent:IsValid() or ent:IsWorld() then
        return ent
    else
        SF.Throw("Entity is not valid.", 3)
    end
end

local function getply(self)
    local ent = punwrap(self)

    if ent:IsValid() then
        return ent
    else
        SF.Throw("Entity is not valid.", 3)
    end
end

local function getShipment(ent)
    if not ent then return falseShipment end
    if not isentity(ent) then return falseShipment end
    if ent:GetClass() ~= "spawned_shipment" then return falseShipment end

    for index, shipment in pairs(drp_shipments) do
        if index == ent:Getcontents() then
            return shipment
        end
    end

    return falseShipment
end

local function getShipmentFromClass(class)
    if not class then return falseShipment end
    if not isstring(class) then return falseShipment end

    for _, shipment in pairs(drp_shipments) do
        if string.lower(shipment.entity) == string.lower(class) or string.lower(shipment.name) == string.lower(class) then
            return shipment
        end
    end

    return falseShipment
end

function darkrp_library.formatMoney(amount)
    checkluatype(amount, TYPE_NUMBER)
    return DarkRP.formatMoney(amount)
end

---

function ents_methods:shipmentName(ent)
    checktype(self, ent_meta)
    return getShipment(getent(self)).name
end

function darkrp_library.shipmentName(class)
    checkluatype(class, TYPE_STRING)
    return getShipmentFromClass(class).name
end

---

function ents_methods:isShipment()
    checktype(self, ent_meta)
    return self:GetClass() == "spawned_shipment"
end

---

function ents_methods:shipmentClass()
    checktype(self, ent_meta)
    return getShipment(getent(self)).entity
end

function darkrp_library.shipmentClass(class)
    checkluatype(class, TYPE_STRING)
    return getShipmentFromClass(class).entity
end

---

function ents_methods:shipmentSize()
    checktype(self, ent_meta)
    return getShipment(getent(self)).amount
end

function darkrp_library.shipmentSize(class)
    checkluatype(class, TYPE_STRING)
    return getShipmentFromClass(class).amount
end

---

function ents_methods:shipmentAmountLeft()
    checktype(self, ent_meta)
    local ent = getent(self)
    if ent:GetClass() ~= "spawned_shipment" then return end

    return ent:Getcount()
end

---

function ents_methods:shipmentModel()
    checktype(self, ent_meta)
    return getShipment(getent(self)).model
end

function darkrp_library.shipmentModel(class)
    checkluatype(class, TYPE_STRING)
    return getShipmentFromClass(class).model
end

---

function ents_methods:shipmentPrice()
    checktype(self, ent_meta)
    return getShipment(getent(self)).price
end

function darkrp_library.shipmentPrice(class)
    checkluatype(class, TYPE_STRING)
    return getShipmentFromClass(class).price
end

---

function ents_methods:shipmentPriceSeparate()
    checktype(self, ent_meta)
    local ent = getShipment(getent(self))

    return ent.price / ent.amount
end

function darkrp_library.shipmentPriceSeparate(class)
    checkluatype(class, TYPE_STRING)
    local ent = getShipmentFromClass(class)

    return ent.price / ent.amount
end

---

function player_methods:getMoney()
    checktype(self, ply_meta)
    return getply(self):getDarkRPVar("money")
end

if SERVER then
    local function canRequest(player)
        local lrPly = latestRequests[player:SteamID()]
        if not lrPly then return true end

        if CurTime() > (lrPly + requestThrottle) then
            player:ChatPrint("You are making too many requests!")
            return true
        end

        return false
    end

    function player_methods:giveMoney(amount)
        checktype(self, ply_meta)
        checkluatype(amount, TYPE_NUMBER)

        local givee = getply(self)
        checkpermission(instance, givee, "darkrp.giveMoney")

        amount = math.Clamp(amount, 0, math.huge)

        if owner:canAfford(amount) then
            payPlayer(owner, givee, amount)
        else
            DarkRP.notify(owner, 1, 4, DarkRP.getPhrase("cant_afford", ""))
        end
    end

    function player_methods:requestMoney(amount, callbackSuccess, callbackFail)
        checktype(self, ply_meta)

        local requester = owner
        local requestee = getply(self)
        checkpermission(instance, requestee, "darkrp.requestMoney")

        if not canRequest(requester) then return end

        checkluatype(amount, TYPE_NUMBER)
        if callbackSuccess then checkluatype(callbackSuccess, TYPE_FUNCTION) end
        if callbackFail then checkluatype(callbackFail, TYPE_FUNCTION) end

        if not callbackSuccess then
            callbackSuccess = function() end
        end

        if not callbackFail then 
            callbackFail = function() end
        end

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

        moneyRequestIndex = (moneyRequestIndex + 1) % 500
        latestRequests[requester:SteamID()] = CurTime()
    end
end

end
