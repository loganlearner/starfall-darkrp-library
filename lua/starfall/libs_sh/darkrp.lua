if engine.ActiveGamemode() ~= "darkrp" then return end

if SERVER then
    util.AddNetworkString("sf_moneyrequest")
    util.AddNetworkString("sf_moneyrequest_accept")
    util.AddNetworkString("sf_moneyrequest_deny")
end

local moneyRequestIndex = 0
local moneyRequests = {}
local checkluatype = SF.CheckLuaType
local drp_shipments

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

SF.RegisterLibrary("darkrp")

return function(instance)

local owner, checktype = instance.player, instance.CheckType
local darkrp_library = instance.Libraries.darkrp
local unwrap = instance.Types.Player.Unwrap
local ply_methods, ent_methods = instance.Types.Player.Methods, instance.Types.Entity.Methods
local getent

instance:AddHook("initialize", function()
    getent = instance.Types.Entity.GetEntity
end)

local function getply(self)
    local ent = unwrap(self)

    if ent:IsValid() then
        return ent
    else
        SF.Throw("Entity is not valid.", 3)
    end
end

-- Credits to TylerB for the following two functions
local function getShipment(ent)
    if not ent then return falseShipment end
    if not isentity(ent) then return falseShipment end
    if ent:GetClass() ~= "spawned_shipment" then return end

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
end

function darkrp_library.formatMoney(amount)
    checkluatype(amount, TYPE_NUMBER)
    return DarkRP.formatMoney(amount)
end

---

function ent_methods:shipmentName()
    return getShipment(getent(self)).name
end

function darkrp_library.shipmentName(class)
    checkluatype(class, TYPE_STRING)
    return getShipmentFromClass(class).name
end

---

function ent_methods:isShipment()
    return self:GetClass() == "spawned_shipment"
end

---

function ent_methods:shipmentClass()
    return getShipment(getent(self)).entity
end

function darkrp_library.shipmentClass(class)
    checkluatype(class, TYPE_STRING)
    return getShipmentFromClass(class).entity
end

---

function ent_methods:shipmentSize()
    return getShipment(getent(self)).amount
end

function darkrp_library.shipmentSize(class)
    checkluatype(class, TYPE_STRING)
    return getShipmentFromClass(class).amount
end

---

function ent_methods:shipmentAmountLeft()
    local ent = getent(self)
    if ent:GetClass() ~= "spawned_shipment" then return end

    return ent:Getcount()
end

---

function ent_methods:shipmentModel()
    return getShipment(getent(self)).model
end

function darkrp_library.shipmentModel(class)
    checkluatype(class, TYPE_STRING)
    return getShipmentFromClass(class).model
end

---

function ent_methods:shipmentPrice()
    return getShipment(getent(self)).price
end

function darkrp_library.shipmentPrice(class)
    checkluatype(class, TYPE_STRING)
    return getShipmentFromClass(class).price
end

---

function ent_methods:shipmentPriceSeparate()
    local ent = getShipment(getent(self))

    return ent.price / ent.amount
end

function darkrp_library.shipmentPriceSeparate(class)
    checkluatype(class, TYPE_STRING)
    local ent = getShipmentFromClass(class)

    return ent.price / ent.amount
end

---

function ply_methods:getMoney()
    return getply(self):getDarkRPVar("money")
end

if SERVER then
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
    
    function ply_methods:giveMoney(amount)
        checkluatype(amount, TYPE_NUMBER)
        local givee = getply(self)

        amount = math.Clamp(amount, 0, math.huge)

        if owner:canAfford(amount) then
            payPlayer(owner, givee, amount)
        else
            DarkRP.notify(owner, 1, 4, DarkRP.getPhrase("cant_afford", ""))
        end
    end

    function ply_methods:requestMoney(amount, callbackSuccess, callbackFail, callbackTimeout)
        local requester = owner
        local requestee = getply(self)
        print(requester)
        print(requestee)

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

        moneyRequestIndex = (moneyRequestIndex + 1) % 500
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

    hook.Add("Tick", "sf_dark_timeout_check", function()
        for _, request in pairs(moneyRequests) do
            if CurTime() >= request.expiration then
                request.timeout()

                table.RemoveByValue(moneyRequests, request)
            end
        end
    end)
end

end
