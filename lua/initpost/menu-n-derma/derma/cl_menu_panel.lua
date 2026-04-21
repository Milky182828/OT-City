local PANEL = {}

local red_select = Color(245, 45, 45)
local clr_gray = Color(255, 255, 255, 25)
local clr_verygray = Color(10, 10, 19, 235)
local gradient_l = surface.GetTextureID("vgui/gradient-l")

surface.CreateFont("ZC_MM_Title", {
    font = "Bahnschrift",
    size = ScreenScale(40),
    weight = 800,
    antialias = true
})

local Selects = {
    {Title = "Вернуться", Func = function(luaMenu) luaMenu:Close() end},
    {Title = "Роли"},
    {Title = "Discord", Func = function(luaMenu) luaMenu:Close() gui.OpenURL("https://discord.gg/PEjPGmBaF3") end},
    {Title = "Достижения", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("hg_achievements") end},
    {Title = "Одежда", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("hg_appearance_menu") end},
    {Title = "Форум", Func = function(luaMenu) luaMenu:Close() gui.OpenURL("https://forum-monteract.ru/") end},
    {Title = "Говорилка", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("aw_tts_menu") end},
    {Title = "Донат", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("rk_donate_menu") end},
    {Title = "Настройки", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("hg_settings") end},
    {Title = "Главное меню", Func = function(luaMenu) gui.ActivateGameUI() luaMenu:Close() end},
    {Title = "Отключиться", Func = function(luaMenu) RunConsoleCommand("disconnect") end},
}

function PANEL:InitializeMarkup()
    local mapname = game.GetMap()
    local prefix = string.find(mapname, "_")
    if prefix then
        mapname = string.sub(mapname, prefix + 1)
    end

    local roundName = mapname
    if zb and zb.GetRoundName then
        roundName = zb.GetRoundName()
    end

    local gm = gmod.GetGamemode().Name .. " | " .. string.NiceName(roundName)
    local text = "<font=ZC_MM_Title><colour=7,233,75>OT</colour>-City</font>\n<font=ZCity_Small>" .. gm .. "</font>"

    return markup.Parse(text)
end

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("OTSO-CITY")
    self:SetDraggable(false)
    self:SetBorder(false)
    self:SetColorBG(clr_verygray)
    self:ShowCloseButton(false)

    self.Title = self:InitializeMarkup()
    self.Buttons = {}
    self.RoleListOpened = false

    timer.Simple(0, function()
        if IsValid(self) and self.First then
            self:First()
        end
    end)

    self.Content = vgui.Create("DPanel", self)
    self.Content:Dock(FILL)
    self.Content.Paint = function(_, w, h)
        self.Title:Draw(w * 0.5, ScreenScale(30), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 255, TEXT_ALIGN_CENTER)
    end

    self.AuthorLabel = vgui.Create("DLabel", self.Content)
    self.AuthorLabel:SetFont("ZCity_Tiny")
    self.AuthorLabel:SetTextColor(clr_gray)
    self.AuthorLabel:SetText("Авторы сервера: Romaniuz, Milky, Vasillium")
    self.AuthorLabel:SetContentAlignment(5)
    self.AuthorLabel:SizeToContents()

    self.ButtonWrap = vgui.Create("DPanel", self.Content)
    self.ButtonWrap:SetSize(ScreenScale(260), ScrH() * 0.5)
    self.ButtonWrap.Paint = nil

    for _, v in ipairs(Selects) do
        local btn = self:AddSelect(self.ButtonWrap, v.Title, v)
        if v.Title == "Роли" then
            self.RoleMainButton = btn
        end
    end

    self.RolePanel = vgui.Create("DPanel", self.ButtonWrap)
    self.RolePanel:SetSize(ScreenScale(140), ScreenScaleH(40))
    self.RolePanel:SetVisible(false)
    self.RolePanel.Paint = nil

    self.RoleButtons = {}

    self:AddRoleSelect(self.RolePanel, "SOE", "soe", 0)
    self:AddRoleSelect(self.RolePanel, "STD", "standard", 1)

    self:InvalidateLayout(true)
end

function PANEL:PerformLayout(w, h)
    if IsValid(self.ButtonWrap) then
        local total = 0

        for _, btn in ipairs(self.Buttons) do
            if IsValid(btn) then
                total = total + btn:GetTall() + ScreenScaleH(10)
            end
        end

        total = math.max(total, ScreenScaleH(220))

        self.ButtonWrap:SetTall(total)
        self.ButtonWrap:SetPos(
            w * 0.5 - self.ButtonWrap:GetWide() * 0.5,
            h * 0.5 - self.ButtonWrap:GetTall() * 0.5 + ScreenScaleH(20)
        )
    end

    if IsValid(self.AuthorLabel) then
        self.AuthorLabel:SetPos(
            w * 0.5 - self.AuthorLabel:GetWide() * 0.5,
            h - ScreenScaleH(40)
        )
    end

    if IsValid(self.RolePanel) and IsValid(self.RoleMainButton) then
        self.RolePanel:SetPos(
            self.RoleMainButton:GetX() + self.RoleMainButton:GetWide() - ScreenScale(50),
            self.RoleMainButton:GetY() - ScreenScaleH(25)
        )
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(0, 0, 0, w, h, self.ColorBG)
    hg.DrawBlur(self, 5)
    surface.SetDrawColor(self.ColorBG)
    surface.SetTexture(gradient_l)
    surface.DrawTexturedRect(0, 0, w, h)
end

function PANEL:CreateTextButton(parent, title)
    local btn = vgui.Create("DButton", parent)
    btn:SetText("")
    btn:SetMouseInputEnabled(true)
    btn:SetKeyboardInputEnabled(false)
    btn:SetCursor("hand")

    surface.SetFont("ZCity_Small")
    local tw, th = surface.GetTextSize(title)

    btn:SetSize(math.max(tw + ScreenScale(20), ScreenScale(120)), math.max(th, ScreenScale(15)))
    btn.ButtonText = title
    btn.RColor = Color(225, 225, 225)
    btn.HoverLerp = 0
    btn.AppearLerp = 0
    btn.AppearDelay = 0

    function btn:Paint(w, h)
        draw.SimpleText(
            self.ButtonText,
            "ZCity_Small",
            w * 0.5,
            h * 0.5,
            self.RColor:Lerp(red_select, self.HoverLerp),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    return btn
end

function PANEL:AddSelect(pParent, strTitle, tbl)
    local id = #self.Buttons + 1
    local btn = self:CreateTextButton(pParent, strTitle)

    btn.Func = tbl.Func
    btn.HoverLerp = 0
    btn.AppearLerp = 0
    btn.AppearDelay = (id - 1) * 0.06
    btn.StartY = (id - 1) * ScreenScaleH(26)

    btn:SetAlpha(0)

    local luaMenu = self

    function btn:DoClick()
        if strTitle == "Роли" then
            luaMenu.RoleListOpened = not luaMenu.RoleListOpened
            if IsValid(luaMenu.RolePanel) then
                luaMenu.RolePanel:SetVisible(luaMenu.RoleListOpened)
                luaMenu.RolePanel:SetMouseInputEnabled(luaMenu.RoleListOpened)
            end
            return
        end

        if self.Func then
            self.Func(luaMenu)
        end
    end

    function btn:Think()
        self.HoverLerp = LerpFT(
            0.2,
            self.HoverLerp or 0,
            self:IsHovered() and 1 or 0
        )

        local targetAppear = CurTime() >= (luaMenu.OpenTime or 0) + self.AppearDelay and 1 or 0
        self.AppearLerp = LerpFT(0.18, self.AppearLerp or 0, targetAppear)

        local x = pParent:GetWide() * 0.5 - self:GetWide() * 0.5
        local y = self.StartY + (1 - self.AppearLerp) * ScreenScaleH(18)

        self:SetPos(x, y)
        self:SetAlpha(255 * self.AppearLerp)
    end

    self.Buttons[id] = btn

    return btn
end

function PANEL:AddRoleSelect(pParent, strTitle, roleName, index)
    local btn = self:CreateTextButton(pParent, strTitle)
    btn:SetPos(0, index * ScreenScaleH(20))
    btn:SetAlpha(255)

    function btn:DoClick()
        self:GetParent():SetVisible(false)

        if IsValid(self:GetParent():GetParent()) and IsValid(self:GetParent():GetParent():GetParent()) then
            local menu = self:GetParent():GetParent():GetParent()
            if menu.Close then
                menu:Close()
            end
        end

        if hg and hg.SelectPlayerRole then
            hg.SelectPlayerRole(nil, roleName)
        end
    end

    function btn:Think()
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, self:IsHovered() and 1 or 0)
    end

    table.insert(self.RoleButtons, btn)

    return btn
end

function PANEL:First()
    self:AlphaTo(255, 0.1, 0, nil)
end

function PANEL:Close()
    self:AlphaTo(0, 0.1, 0, function()
        if IsValid(self) then
            self:Remove()
        end
    end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register("ZMainMenu", PANEL, "ZFrame")

hook.Add("OnPauseMenuShow", "OpenMainMenu", function()
    if MainMenu and IsValid(MainMenu) then
        MainMenu:Close()
        MainMenu = nil
        return false
    end

    MainMenu = vgui.Create("ZMainMenu")
    MainMenu.OpenTime = CurTime()
    MainMenu:MakePopup()

    return false
end)