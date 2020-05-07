surface.CreateFont("DermaMoney", {
    font = "DermaLarge",
    size = 24
})

surface.CreateFont("DermaMoneyButton", {
    font = "DermaLarge",
    size = 18,
    weight = 900
})

local function createRequest(index, requester, amount)
    local EndTime = CurTime() + 30
    EmitSound(Sound("garrysmod/content_downloaded.wav"), Vector(), -1)

    local p = vgui.Create("DFrame")
    p:SetTitle("SF Money Request")
    p:SetSize(400, 135)
    p:Center()
    p:ShowCloseButton(false)
    p:SetSizable(false)
    p:SetDraggable(false)
    p:MakePopup()

    function p:Paint(w, h)
        local timeleft = math.Round(EndTime - CurTime())

        surface.SetDrawColor(Color(44, 54, 92, 254))
        surface.DrawRect(0, 0, w, h)

        p:SetTitle("SF Money Request - " .. timeleft)

        if timeleft <= 0 then
            p:Close()
        end
    end

    local bgDiv = vgui.Create("DPanel", p)
    bgDiv:Dock(FILL)

    function bgDiv:Paint(w, h)
        surface.SetDrawColor(Color(31, 36, 50))
        surface.DrawRect(0, 0, w, h)
    end

    local leftDiv = vgui.Create("DPanel", bgDiv)
    leftDiv:Dock(FILL)
    leftDiv.Paint = nil

    local avatarImage = vgui.Create("AvatarImage", leftDiv)
    avatarImage:DockMargin(5, 5, 5, 5)
    avatarImage:Dock(FILL)
    avatarImage:SetPlayer(requester, 184)

    local rightDiv = vgui.Create("DPanel", bgDiv)
    rightDiv:SetWide(290)
    rightDiv:Dock(RIGHT)
    
    function rightDiv:Paint(w, h)
        draw.SimpleText(requester:Name() .. " is requesting: ", "DermaDefault", 0, 5)
        draw.SimpleText(DarkRP.formatMoney(amount), "DermaMoney", 0, 28, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Would you like to accept?", "DermaDefault", 0, 40)
    end

    local buttonDiv = vgui.Create("DPanel", rightDiv)
    buttonDiv:SetTall(50)
    buttonDiv:Dock(BOTTOM)
    buttonDiv.Paint = nil

    local acceptButton = vgui.Create("DButton", buttonDiv)
    acceptButton:SetText("Accept")
    acceptButton:SetWide(140)
    acceptButton:DockMargin(0, 5, 5, 5)
    acceptButton:Dock(LEFT)
    acceptButton:SetTextColor(Color(255, 255, 255))
    acceptButton:SetFont("DermaMoneyButton")

    function acceptButton:Paint(w, h)
        local isHovering = self:IsHovered()
        local col = isHovering and Color(113, 198, 106) or Color(98, 192, 90)
        surface.SetDrawColor(col)
        surface.DrawRect(0, 0, w, h)
    end

    acceptButton.DoClick = function()
        net.Start("sf_moneyrequest_accept")
            net.WriteFloat(index)
        net.SendToServer()

        p:Close()
    end

    local denyButton = vgui.Create("DButton", buttonDiv)
    denyButton:SetText("Deny")
    denyButton:SetWide(140)
    denyButton:DockMargin(5, 5, 5, 5)
    denyButton:Dock(RIGHT)
    denyButton:SetTextColor(Color(255, 255, 255))
    denyButton:SetFont("DermaMoneyButton")

    function denyButton:Paint(w, h)
        local isHovering = self:IsHovered()
        local col = isHovering and Color(229, 72, 72) or Color(227, 52, 52)
        surface.SetDrawColor(col)
        surface.DrawRect(0, 0, w, h)
    end

    denyButton.DoClick = function()
        net.Start("sf_moneyrequest_deny")
            net.WriteFloat(index)
        net.SendToServer()

        p:Close()
    end
end

net.Receive("sf_moneyrequest", function()
    local index = net.ReadFloat()
    local requester = net.ReadEntity()
    local amount = net.ReadFloat()

    createRequest(index, requester, amount)
end)
