local PANEL = {}

hg.settings = hg.settings or {}
hg.settings.tbl = hg.settings.tbl or {}

function hg.settings:AddOpt( strCategory, strConVar, strTitle, bDecimals, bString )
    self.tbl[strCategory] = self.tbl[strCategory] or {}
    self.tbl[strCategory][strConVar] = { strCategory, strConVar, strTitle, bDecimals or false, bString or false }
end

hg.settings:AddOpt("Оптимизация","hg_potatopc", "Режим слабого ПК")
hg.settings:AddOpt("Оптимизация","hg_anims_draw_distance", "Дистанция прорисовки анимаций")
hg.settings:AddOpt("Оптимизация","hg_anim_fps", "FPS анимаций")
hg.settings:AddOpt("Оптимизация","hg_attachment_draw_distance", "Дистанция прорисовки обвесов")
hg.settings:AddOpt("Оптимизация","hg_maxsmoketrails", "Максимум дымовых следов")
hg.settings:AddOpt("Оптимизация","hg_tpik_distance", "Дистанция прорисовки TPIK")

hg.settings:AddOpt("Кровь","hg_blood_draw_distance", "Дистанция прорисовки крови")
hg.settings:AddOpt("Кровь","hg_blood_fps", "FPS крови")
hg.settings:AddOpt("Кровь","hg_blood_sprites", "Спрайты крови (ОТКЛЮЧЕНО ДЛЯ ВСЕХ)")
hg.settings:AddOpt("Кровь","hg_old_blood", "Изменить цвет крови")

hg.settings:AddOpt("Интерфейс","hg_font", "Сменить пользовательский шрифт", false, true)

hg.settings:AddOpt("Оружие","hg_weaponshotblur_enable", "Размытие при стрельбе")
hg.settings:AddOpt("Оружие","hg_dynamic_mags", "Динамический осмотр патронов")

hg.settings:AddOpt("Вид","hg_firstperson_death", "Смерть от первого лица")
hg.settings:AddOpt("Вид","hg_fov", "Угол обзора (FOV)")
hg.settings:AddOpt("Вид","mzb_MoodleHud", "Включить иконки состояния (голод, жажда и т.д.)")
hg.settings:AddOpt("Вид","hg_coolgloves", "Красивые перчатки")
hg.settings:AddOpt("Вид","hg_newspectate", "Плавная камера наблюдателя")
hg.settings:Addopt("Вид","mzb_MoodleHud_enabled", "Худ состаяния персонажа")
hg.settings:AddOpt("Вид","hg_change_gloves", "Модель перчаток")
hg.settings:AddOpt("Вид","hg_cshs_fake", "Камера рагдолла C'sHS")
hg.settings:AddOpt("Вид","hg_gun_cam", "Камера оружия (ТОЛЬКО АДМИН)")
hg.settings:AddOpt("Вид","hg_nofovzoom", "Отключить/включить зум FOV")

hg.settings:AddOpt("Звук","hg_dmusic", "Динамическая музыка")
hg.settings:AddOpt("Звук","hg_quietshots", "Включить/выключить тихие звуки выстрелов (ДЛЯ ТРУСОВ)")

hg.settings:AddOpt("Игра","hg_old_notificate", "Старые уведомления")
hg.settings:AddOpt("Игра","hg_random_appearance", "Включить/выключить случайную внешность")
hg.settings:AddOpt("Игра","hg_cheats", "Включить/выключить читы")

function PANEL:Init()
    self:SetAlpha( 0 )
    self:SetSize( ScrW()*1, ScrH()*1 )
    self:SetY( ScrH() )
    self:SetX( ScrW() / 2 - self:GetWide() / 2 )
    self:SetTitle( "" )
    self:SetBorder( false )
    self:SetColorBG( Color(10,10,25,245) )
    self:SetBlurStrengh( 2 )
    self:SetDraggable( false )
    self:ShowCloseButton( true )
    self.Options = {}

    timer.Simple(0,function()
        if self.First then
            self:First()
        end
    end)

    self.fDock = vgui.Create("DScrollPanel",self)
    local fDock = self.fDock
    fDock:Dock( FILL )

    self:CreateCategory( "Настройки" )

    for k,t in SortedPairs(hg.settings.tbl) do
        for _,tbl in SortedPairs(t) do
            local convar = GetConVar(tbl[2])
            if convar then
                self:CreateOption(tbl[1],convar:GetMax() == 1,convar, tbl[4], tbl[3] or convar:GetName(), nil, tbl[5])
            end
        end
    end
end

function PANEL:First( ply )
    self:MoveTo(self:GetX(), ScrH() / 2 - self:GetTall() / 2, 0.4, 0, 0.2, function() end)
    self:AlphaTo( 255, 0.2, 0.1, nil )
end

function PANEL:CreateCategory( strCategory )
    local fDock = self.fDock
    if not self.Options[strCategory] then
        local category = vgui.Create("DLabel",fDock)
        category:Dock( TOP )
        category:SetSize(0,ScreenScale(20))
        category:SetText(strCategory)
        category:SetFont("ZCity_Small")
        category:DockMargin(ScreenScaleH(65),2,ScreenScaleH(65),5)
    end
    self.Options[strCategory] = self.Options[strCategory] or {}
    return self.Options[strCategory]
end

local color_blacky = Color(39,39,39,220)
local color_reddy = Color(206,43,22,220)

function PANEL:CreateOption( strCategory, bType, cConVar, bDecimals, strTitle, strDesc, bString )
    if not cConVar then
        return
    end

    local fDock = self.fDock
    local Category = self:CreateCategory( strCategory )
    Category[cConVar:GetName()] = vgui.Create("DPanel",fDock)
    local opt = Category[cConVar:GetName()]
    opt:Dock( TOP )
    opt:SetSize(0,ScreenScale(25))
    opt:DockMargin(ScreenScaleH(75),2,ScreenScaleH(75),2)
    function opt:Paint(w,h)
        draw.RoundedBox( 0, 0, 0, w, h, color_blacky )
        surface.SetDrawColor( color_reddy )
        surface.DrawOutlinedRect(0,0,w,h,1.5)
    end

    opt.NLabel = vgui.Create("DLabel",opt)
    local NLbl = opt.NLabel
    NLbl:SetText( strTitle.."\n"..(strDesc or string.NiceName( cConVar:GetHelpText() ) ) )
    NLbl:SetFont("ZCity_Tiny")
    NLbl:SizeToContents()
    NLbl:Dock(LEFT)
    NLbl:DockMargin(10,0,0,0)

    if bString then
        opt.TextInput = vgui.Create("DTextEntry",opt)
        local TextInput = opt.TextInput
        TextInput:DockMargin( 10,ScreenScale(5),10,ScreenScale(5) )
        TextInput:DockPadding(ScreenScale(5),ScreenScale(5),ScreenScale(5),ScreenScale(5))
        TextInput:SetSize( ScreenScale(90),0 )
        TextInput:Dock( RIGHT )

        TextInput:SetValue(cConVar:GetString())
        TextInput:SetPlaceholderText("Твоя переменная "..cConVar:GetName())
        TextInput:SetFont("ZCity_Tiny")
        function TextInput:OnLoseFocus()
            cConVar:SetString(self:GetValue())
        end
    elseif bType then
        opt.Button = vgui.Create("DButton",opt)
        local btn = opt.Button
        btn:SetText( "" )
        btn:DockMargin( 10,ScreenScale(5),10,ScreenScale(5) )
        btn:SetSize( ScreenScale(40),0 )
        btn:Dock( RIGHT )

        btn.On = cConVar:GetBool()

        function btn:Paint(w,h)
            self.Lerp = LerpFT(0.2,self.Lerp or (btn.On and 1 or 0), btn.On and 1 or 0)
            local CLR = color_reddy:Lerp(Color(55,175,55),self.Lerp)
            draw.RoundedBox( 0, 0, 0, w, h, CLR )
            draw.RoundedBox( 0, (w/2)*(self.Lerp), 0, w/2, h, ColorAlpha(color_blacky,255) )
            surface.SetDrawColor( color_reddy )
            surface.DrawOutlinedRect(0,0,w,h,1.5)
        end

        function btn:DoClick()
            cConVar:SetBool(not cConVar:GetBool())
            btn.On = cConVar:GetBool()
        end
    else
        local Slid = vgui.Create( "DNumSlider", opt )
        Slid:DockMargin( 10,15,10,15 )
        Slid:SetSize( 500, 0 )
        Slid:Dock( RIGHT )
        Slid:SetMin( cConVar:GetMin() )
        Slid:SetMax( cConVar:GetMax() )
        Slid:SetDecimals( bDecimals and 2 or 0)
        Slid:SetConVar( cConVar:GetName() )
        Slid.TextArea:SetFont("ZCity_Tiny")
    end
end

vgui.Register( "ZOptions", PANEL, "ZFrame")

concommand.Add("hg_settings",function()
    if hg_options and IsValid(hg_options) then
        hg_options:Close()
        hg_options = nil
    end
    local s = vgui.Create("ZOptions")
    s:MakePopup()
    hg_options = s
end)