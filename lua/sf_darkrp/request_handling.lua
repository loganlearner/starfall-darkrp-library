local function createRequest(index, requester, amount)
    local EndTime = CurTime() + 30
    EmitSound(Sound("garrysmod/content_downloaded.wav"), Vector(), -1)

    local p = vgui.Create("DFrame")
    p:SetTitle("SF Money Request")
    p:SetSize(400, 200)
    p:Center()
    p:ShowCloseButton(false)
    p:SetSizable(false)
    p:MakePopup()

    function p:Paint(w, h)
        surface.SetDrawColor(Color(44, 54, 92, 254))
        surface.DrawRect(0, 0, w, h)

        p:SetTitle("SF Money Request - " .. math.Round(EndTime - CurTime()))
    end

    local rightDiv = vgui.Create("DPanel", p)
    rightDiv:SetWide(300)
    rightDiv:Dock(RIGHT)
    --rightDiv.Paint = nil

    local buttonDiv = vgui.Create("DPanel", rightDiv)
    buttonDiv:SetTall(100)
    buttonDiv:Dock(BOTTOM)

    local acceptButton = vgui.Create("DButton", buttonDiv)
    --acceptButton:DockMargin(50, 50, 50, 50)
    acceptButton:Dock(LEFT)

    acceptButton.DoClick = function()
        net.Start("sf_moneyrequest_accept")
            net.WriteFloat(index)
        net.SendToServer()

        p:Close()
    end

    local denyButton = vgui.Create("DButton", buttonDiv)
    --denyButton:DockMargin(50, 50, 50, 50)
    denyButton:Dock(RIGHT)

    denyButton.DoClick = function()
        net.Start("sf_moneyrequest_deny")
            net.WriteFloat(index)
        net.SendToServer()

        p:Close()
    end

    timer.Simple(30, function()
        p:Close()
    end)
end

net.Receive("sf_moneyrequest", function()
    local index = net.ReadFloat()
    local requester = net.ReadEntity()
    local amount = net.ReadFloat()

    createRequest(index, requester, amount)
end)
