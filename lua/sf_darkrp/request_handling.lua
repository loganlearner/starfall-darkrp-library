local function createRequest(index, requester, amount)
    local p = vgui.Create("DFrame")
    p:SetTitle("SF Money Request")
    p:SetSize(400, 235)
    p:Center()
    p:ShowCloseButton(false)
    p:SetSizable(false)
    p:MakePopup()

    function p:Paint(w, h)
        surface.SetDrawColor(Color(44, 54, 92, 254))
        surface.DrawRect(0, 0, w, h)
    end

    local rightDiv = vgui.Create("DPanel", p)
    rightDiv:SetWide(300)
    rightDiv:Dock(RIGHT)
    rightDiv.Paint = nil

    local acceptButton = vgui.Create("DButton", rightDiv)
    acceptButton:DockMargin(50, 50, 50, 50)
    acceptButton:Dock(LEFT)

    acceptButton.DoClick = function()
        p:Close()
    end

    local denyButton = vgui.Create("DButton", rightDiv)
    denyButton:DockMargin(50, 50, 50, 50)
    denyButton:Dock(RIGHT)

    denyButton.DoClick = function()
        p:Close()
    end
end

net.Receive("sf_moneyrequest", function()
    local index = net.ReadFloat()
    local requester = net.ReadEntity()
    local amount = net.ReadFloat()

    createRequest(index, requester, amount)
end)
