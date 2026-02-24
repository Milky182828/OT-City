----
local PANEL = {}

local red_select = Color(245,45,45)

local Selects = {
    {Title = "Отключиться", Func = function(luaMenu) RunConsoleCommand("disconnect") end},
    {Title = "Главное меню", Func = function(luaMenu) gui.ActivateGameUI() luaMenu:Close() end},
    {Title = "Настройки", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("hg_settings") end},
    {Title = "Discord", Func = function(luaMenu) luaMenu:Close() gui.OpenURL("https://discord.gg/QNddJmYFDc")  end},
    --{Title = "How to play", Func = function(luaMenu) gui.OpenURL("http://zcity-help.ru/zcity_wiki.htm?") end},
    --{Title = "Wiki/Rules", Func = function(luaMenu) luaMenu:Close() gui.OpenURL("http://zcity-help.ru") end},
    {Title = "Достижения", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("hg_achievements") end},
    {Title = "Одежда", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("hg_appearance_menu") end},
   -- {Title = "Аксессуары", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("hg_pointshop") end},
    {Title = "Говорилка", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("aw_tts_menu") end},
    {Title = "Донат", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("rk_donate_menu") end},
    {Title = "Роли",
    GamemodeOnly = true,
    CreatedFunc = function(self, parent, luaMenu)
        local btn = vgui.Create( "DLabel", self )
        btn:SetText( "SOE" )
        btn:SetMouseInputEnabled( true )
        btn:SizeToContents()
        btn:SetFont( "ZCity_Small" )
        btn:SetTall( ScreenScale( 15 ) )
        btn:Dock(BOTTOM)
        btn:DockMargin(0,ScreenScale(2),0,0)
        btn:SetTextColor(Color(255,255,255))
        btn:InvalidateParent()
        btn.RColor = Color(225, 225, 225, 0)
        btn.WColor = Color(225, 225, 225, 255)
        btn.x = btn:GetX()

        function btn:DoClick()
            luaMenu:Close()
            hg.SelectPlayerRole(nil, "soe")
        end
    
        local selfa = self
        function btn:Think()
            self.HoverLerp = selfa.HoverLerp
            self.HoverLerp2 = LerpFT(0.2, self.HoverLerp2 or 0, self:IsHovered() and 1 or 0)
                
            self:SetTextColor(self.RColor:Lerp(self.WColor:Lerp(red_select, self.HoverLerp2), self.HoverLerp))
            self:SetX(self.x + ScreenScaleH(40) + self.HoverLerp * ScreenScaleH(50))
        end

        local btn2 = vgui.Create( "DLabel", btn )
        btn2:SetText( "STD" )
        btn2:SetMouseInputEnabled( true )
        btn2:SizeToContents()
        btn2:SetFont( "ZCity_Small" )
        btn2:SetTall( ScreenScale( 15 ) )
        btn2:Dock(BOTTOM)
        btn2:DockMargin(0,ScreenScale(2),0,0)
        btn2:SetTextColor(Color(255,255,255))
        btn2:InvalidateParent()
        btn2.RColor = Color(225, 225, 225, 0)
        btn2.WColor = Color(225, 225, 225, 255)
        btn2.x = btn2:GetX()

        function btn2:DoClick()
            luaMenu:Close()
            hg.SelectPlayerRole(nil, "standard")
        end
    
        function btn2:Think()
            self.HoverLerp = selfa.HoverLerp
            self.HoverLerp2 = LerpFT(0.2, self.HoverLerp2 or 0, self:IsHovered() and 1 or 0)
    
            self:SetTextColor(self.RColor:Lerp(self.WColor:Lerp(red_select, self.HoverLerp2), self.HoverLerp))
            self:SetX(self.x + ScreenScaleH(35))
        end
    end,
    Func = function(luaMenu)
        
    end,
    },
    {Title = "Вернуться", Func = function(luaMenu) luaMenu:Close() end},
}

surface.CreateFont("ZC_MM_Title", {
    font = "Bahnschrift",
    size = ScreenScale(40),
    weight = 800,
    antialias = true
})
-- local Title = markup.Parse("error")

            local Pluv = Material("pluv/pluvkid.jpg")

            function PANEL:InitializeMarkup()
                local mapname = game.GetMap()
                local prefix = string.find(mapname, "_")
                if prefix then
                    mapname = string.sub(mapname, prefix + 1)
                end
                local gm = gmod.GetGamemode().Name .. " | " .. string.NiceName(zb ~= nil and zb.GetRoundName or mapname)

                if hg.PluvTown.Active then
                    local text = "<font=ZC_MM_Title><colour=42,252,0>    </colour>City</font>\n<font=ZCity_Small>" .. gm .. "</font>"

                    self.SelectedPluv = table.Random(hg.PluvTown.PluvMats)

                    return markup.Parse(text)
                end

                local text = "<font=ZC_MM_Title><colour=7,233,75>OT</colour>-City</font>\n<font=ZCity_Small>" .. gm .. "</font>"
                return markup.Parse(text)
            end

local color_red = Color(255,25,25,45)
local clr_gray = Color(255,255,255,25)
local clr_verygray = Color(10,10,19,235)
function PANEL:Init()
    self:SetAlpha( 0 )
    self:SetSize( ScrW(), ScrH() )
    self:Center()
    self:SetTitle( "OTSO-CITY" )
    self:SetDraggable( false )
    self:SetBorder( false )
    self:SetColorBG(clr_verygray)
    self:SetDraggable( false )
    self:ShowCloseButton( false )

    self.Title, self.TitleShadow = self:InitializeMarkup()

    timer.Simple(0,function()
        if self.First then
            self:First()
        end
    end)

    self.lDock = vgui.Create("DPanel",self)
    local lDock = self.lDock
    lDock:Dock( LEFT )
    lDock:SetSize( ScrW() / 2, ScrH() ) -- ЕСЛИ ЧТО ТУТ БЫЛО ВМЕСТО ScrW() ScreenScale(200) (на случай если чето сломается хотя не должно)
    lDock:DockMargin( ScreenScale(15), ScreenScaleH(40), ScreenScale(10), ScreenScaleH(10) )
    lDock.Paint = function(this, w, h)
        if hg.PluvTown.Active then
            surface.SetDrawColor(color_white)
            surface.SetMaterial(self.SelectedPluv or Pluv)
            surface.DrawTexturedRect(0, ScreenScale(27), ScreenScale(35), ScreenScale(27))
        end

        self.Title:Draw(ScreenScale(15), ScreenScale(50), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 255, TEXT_ALIGN_LEFT)
    end

    local zteam = vgui.Create("DLabel",lDock)
    zteam:Dock(BOTTOM)
    zteam:SetFont("ZCity_Tiny")
    zteam:SetTextColor(clr_gray)
    zteam:SetText("Авторы сервера: Romaniuz, MILKY, Vasillium")
    zteam:DockMargin(0,ScreenScaleH(60),0,0)
    zteam:SetContentAlignment(1)

    self.Buttons = {}
    for k,v in ipairs(Selects) do
        if v.GamemodeOnly and engine.ActiveGamemode() != "zcity" then continue end
        self:AddSelect( lDock, v.Title, v )
    end
end

--[[
["5.42.211.48:24215"]:
		["addr"]	=	5.42.211.48:24215
		["map"]	=	hmcd_metropolis_extended
		["max_players"]	=	20
		["name"]	=	Z-City 1 | Beta | RU
		["players"]	=	20
["5.42.211.48:24217"]:
		["addr"]	=	5.42.211.48:24217
		["map"]	=	hmcd_metropolis_extended
		["max_players"]	=	20
		["name"]	=	Z-City 2 | Beta | RU
		["players"]	=	18
]]

local cardcolor = Color(15,15,25,220)
local green_color = Color(55,225,55)

function PANEL:AddServerCard(serverTbl)
    local main = self
    local card = vgui.Create("DPanel",self.rDock)
    card:Dock(TOP)
    card:SetSize(500,ScreenScaleH(45))
    card:DockMargin(5,5,5,5)
    card:DockPadding(15,5,15,15)
    card.Info = serverTbl
    function card:Paint(w,h)
        draw.RoundedBox( 4, 0, 0, w, h, cardcolor )

        draw.RoundedBox( 0, 0, h-h/5, w, h/5, cardcolor )
        draw.RoundedBox( 0, 2.5, h-h/5 +3, w* (card.Info["players"]/card.Info["max_players"]) - 5 , h/6, color_red )
    end

    local lbl = vgui.Create("DLabel",card)
    lbl:Dock(BOTTOM)
    lbl:SetFont("ZCity_Tiny")
    lbl:SetText(card.Info["players"].."/"..card.Info["max_players"])
    lbl:SizeToContents()
    lbl:SetTall(ScreenScaleH(17))

    local lbl2 = vgui.Create("DLabel",card)
    lbl2:Dock(LEFT)
    lbl2:SetFont("ZCity_Small")
    lbl2:SetText(card.Info["name"])
    lbl2:SizeToContents()
    lbl2:SetTall(ScreenScaleH(19))

    local connectButton = vgui.Create("DButton",card)
    connectButton:Dock(RIGHT)
    connectButton:SetFont("ZCity_Small")
    connectButton:SetText("Połącz")
    connectButton:SizeToContents()
    connectButton:SetTall(ScreenScaleH(19))
    connectButton.HoverLerp = 0
    connectButton.RColor = Color(255,255,255)
    function connectButton:Paint(w,h)
        return false
    end

    function connectButton:Think()
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, self:IsHovered() and 1 or 0)
        local v = self.HoverLerp
        self:SetTextColor( self.RColor:Lerp( green_color, v ) )
    end

    function connectButton:DoClick()
        permissions.AskToConnect( card.Info["addr"] )
    end
end

function PANEL:First( ply )
    --self:MoveTo(self:GetX(), self:GetY() - self:GetTall()/2, 0.5, 0, 0.2, function() end)
    self:AlphaTo( 255, 0.1, 0, nil )
end

local gradient_d = surface.GetTextureID("vgui/gradient-d")
local gradient_r = surface.GetTextureID("vgui/gradient-r")
local gradient_l = surface.GetTextureID("vgui/gradient-l")

function PANEL:Paint(w,h)
    draw.RoundedBox( 0, 0, 0, w, h, self.ColorBG )
    hg.DrawBlur(self, 5)

    --if self.DrawBorder then
    --    surface.SetDrawColor(self.ColorBR)
    --    surface.DrawOutlinedRect(0,0,w,h,1.5)
    --end
    surface.SetDrawColor( self.ColorBG )
    surface.SetTexture( gradient_l )
    surface.DrawTexturedRect(0,0,w,h)
end

function PANEL:AddSelect( pParent, strTitle, tbl )
    local id = #self.Buttons + 1
    self.Buttons[id] = vgui.Create( "DLabel", pParent )
    local btn = self.Buttons[id]
    btn:SetText( strTitle )
    btn:SetMouseInputEnabled( true )
    btn:SizeToContents()
    btn:SetFont( "ZCity_Small" )
    btn:SetTall( ScreenScale( 15 ) )
    btn:Dock(BOTTOM)
    btn:DockMargin(ScreenScale(15),ScreenScale(2),0,0)
    btn.Func = tbl.Func
    btn.HoveredFunc = tbl.HoveredFunc
    local luaMenu = self 
    if tbl.CreatedFunc then tbl.CreatedFunc(btn, self, luaMenu) end
    btn.RColor = Color(225,225,225)
    function btn:DoClick()
        btn.Func(luaMenu)
    end

    function btn:Think()
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, (self:IsHovered() or (IsValid(self:GetChild(0)) and self:GetChild(0):IsHovered()) or (IsValid(self:GetChild(0)) and IsValid(self:GetChild(0):GetChild(0)) and self:GetChild(0):GetChild(0):IsHovered())) and 1 or 0)

        local v = self.HoverLerp

        self:SetTextColor(self.RColor:Lerp(red_select, v))
    end
end

function PANEL:Close()
    self:AlphaTo( 0, 0.1, 0, function() self:Remove() end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register( "ZMainMenu", PANEL, "ZFrame")

hook.Add("OnPauseMenuShow","OpenMainMenu",function()
    local run = hook.Run("OnShowZCityPause")
    if run then
        return run
    end

    if MainMenu and IsValid(MainMenu) then
        MainMenu:Close()
        MainMenu = nil
        return false
    end

    MainMenu = vgui.Create("ZMainMenu")
    MainMenu:MakePopup()
    return false
end)

-- уже потом сделаю... как домой вернусь