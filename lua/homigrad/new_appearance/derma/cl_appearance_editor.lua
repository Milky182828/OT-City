hg.Appearance = hg.Appearance or {}
local APmodule = hg.Appearance
local PANEL = {}
local colors = {}
colors.secondary = Color(18, 28, 18, 220)
colors.mainText = Color(235, 255, 235, 255)
colors.secondaryText = Color(120, 170, 120, 180)
colors.selectionBG = Color(30, 140, 50, 235)
colors.highlightText = Color(120, 255, 140, 255)
colors.presetBG = Color(22, 32, 22, 230)
colors.presetBorder = Color(50, 170, 80, 255)
colors.presetHover = Color(30, 60, 35, 245)
colors.scrollbarBG = Color(15, 24, 15, 210)
colors.scrollbarGrip = Color(40, 120, 55, 255)
colors.scrollbarGripHover = Color(65, 170, 85, 255)
colors.scrollbarBorder = Color(60, 190, 90, 220)
colors.previewBorder = Color(80, 220, 110, 255)

local function GetPresetCache()
    hg.Appearance.PresetsCache = hg.Appearance.PresetsCache or {}
    return hg.Appearance.PresetsCache
end

local function SavePreset(strName, tblAppearance)
    if not isstring(strName) or strName == "" then return end
    if not istable(tblAppearance) then return end
    net.Start("hg_appearance_preset_save")
        net.WriteString(strName)
        net.WriteTable(tblAppearance)
    net.SendToServer()
end

local function LoadPreset(strName)
    local presets = GetPresetCache()
    local preset = presets[strName]
    if not istable(preset) then return nil end
    return table.Copy(preset)
end

local function GetPresetList()
    local presets = GetPresetCache()
    local list = {}
    for name in pairs(presets) do
        list[#list + 1] = name
    end
    table.sort(list, function(a, b) return tostring(a) < tostring(b) end)
    return list
end

local function DeletePreset(strName)
    if not isstring(strName) or strName == "" then return false end
    net.Start("hg_appearance_preset_delete")
        net.WriteString(strName)
    net.SendToServer()
    return true
end

hg.Appearance.SavePreset = SavePreset
hg.Appearance.LoadPreset = LoadPreset
hg.Appearance.GetPresetList = GetPresetList
hg.Appearance.DeletePreset = DeletePreset

local modelsPrecached = false
local function PrecacheAccessoryModels()
    if modelsPrecached then return end
    modelsPrecached = true

    timer.Simple(0.1, function()
        if APmodule.PlayerModels then
            for _, sexModels in pairs(APmodule.PlayerModels) do
                for _, modelData in pairs(sexModels) do
                    if modelData.mdl then
                        util.PrecacheModel(modelData.mdl)
                    end
                end
            end
        end

        if hg.Accessories then
            for _, accessory in pairs(hg.Accessories) do
                if accessory.model then
                    util.PrecacheModel(accessory.model)
                end
            end
        end
    end)
end

hook.Add("InitPostEntity", "HG_PrecacheAppearanceModels", function()
    timer.Simple(5, PrecacheAccessoryModels)
end)

hg.Appearance.PrecacheModels = PrecacheAccessoryModels

local function CreateStyledScrollPanel(parent)
    local scroll = vgui.Create("DScrollPanel", parent)
    local sbar = scroll:GetVBar()
    sbar:SetWide(ScreenScale(4))
    sbar:SetHideButtons(true)

    function sbar:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, colors.scrollbarBG)
        surface.SetDrawColor(colors.scrollbarBorder)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    function sbar.btnGrip:Paint(w, h)
        local col = self:IsHovered() and colors.scrollbarGripHover or colors.scrollbarGrip
        draw.RoundedBox(4, 2, 2, w - 4, h - 4, col)
        surface.SetDrawColor(colors.scrollbarBorder)
        surface.DrawOutlinedRect(2, 2, w - 4, h - 4, 1)
    end

    return scroll
end

local clr_ico = Color(16, 24, 16, 255)
local clr_menu = Color(10, 16, 10, 248)

local function CreateStyledAccessoryMenu(parent, title)
    local menu = vgui.Create("DFrame", parent)
    menu:SetTitle(title or "")
    menu:SetSize(ScreenScale(90), ScreenScale(140))
    local cx, cy = input.GetCursorPos()
    menu:SetPos(cx, cy)
    menu:MakePopup()
    menu:SetDraggable(false)
    menu:ShowCloseButton(true)
    menu.CurrentPreviewIcon = nil

    function menu:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, clr_menu)
        surface.SetDrawColor(colors.scrollbarBorder)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        draw.RoundedBoxEx(8, 0, 0, w, ScreenScale(10), colors.secondary, true, true, false, false)
        surface.SetDrawColor(colors.scrollbarBorder)
        surface.DrawLine(0, ScreenScale(10), w, ScreenScale(10))
    end

    local scroll = CreateStyledScrollPanel(menu)
    scroll:Dock(FILL)
    scroll:DockMargin(ScreenScale(2), ScreenScale(2), ScreenScale(2), ScreenScale(2))

    local iconLayout = vgui.Create("DIconLayout", scroll)
    iconLayout:Dock(TOP)
    iconLayout:SetSpaceX(ScreenScale(2))
    iconLayout:SetSpaceY(ScreenScale(2))
    menu.IconLayout = iconLayout
    menu.ScrollPanel = scroll

    function menu:AddAccessoryIcon(model, accessorKey, accessoryData, onSelect, onRightClick)
        local ico = vgui.Create("DPanel", self.IconLayout)
        local icoSize = ScreenScale(36)
        ico:SetSize(icoSize, icoSize)
        ico.Accessor = accessorKey
        ico.bIsHovered = false
        ico.IsPreviewing = false

        local spawnIcon = vgui.Create("DModelPanel", ico)
        spawnIcon:Dock(FILL)
        spawnIcon:DockMargin(2, 2, 2, 2)
        spawnIcon:SetModel(model or "models/error.mdl")
        spawnIcon:SetTooltip(string.NiceName(accessoryData and accessoryData.name or accessorKey))
        spawnIcon:SetFOV(15)
        spawnIcon:SetLookAt(accessoryData.vpos or Vector(0, 0, 0))

        function spawnIcon:PreDrawModel()
            if accessoryData.bSetColor then
                local lply = LocalPlayer()
                local colorDraw = accessoryData.vecColorOveride or (lply.GetPlayerColor and lply:GetPlayerColor() or lply:GetNWVector("PlayerColor", Vector(1, 1, 1)))
                render.SetColorModulation(colorDraw[1], colorDraw[2], colorDraw[3])
            end
        end

        function spawnIcon:PostDrawModel()
            if accessoryData.bSetColor then
                render.SetColorModulation(1, 1, 1)
            end
        end

        timer.Simple(0, function()
            if not IsValid(spawnIcon) or not IsValid(spawnIcon.Entity) then return end
            spawnIcon.Entity:SetSkin((isfunction(accessoryData.skin) and accessoryData.skin()) or (accessoryData.skin or 0))
            spawnIcon.Entity:SetBodyGroups(accessoryData.bodygroups or "0000000")
            if accessoryData.SubMat then
                spawnIcon.Entity:SetSubMaterial(0, accessoryData.SubMat)
            end
        end)

        function spawnIcon:DoClick()
            if onSelect then onSelect(accessorKey) end
            surface.PlaySound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav")
            menu:Close()
        end

        function spawnIcon:OnCursorEntered()
            ico.IsPreviewing = true
            menu.CurrentPreviewIcon = ico
            if onRightClick then
                onRightClick(accessorKey, true)
            end
        end

        function spawnIcon:OnCursorExited()
            ico.IsPreviewing = false
            if menu.CurrentPreviewIcon == ico then
                menu.CurrentPreviewIcon = nil
            end
            if onRightClick then
                onRightClick(accessorKey, false)
            end
        end

        function ico:Paint(w, h)
            local borderCol = self.bIsHovered and colors.scrollbarGripHover or colors.scrollbarBorder
            draw.RoundedBox(4, 0, 0, w, h, clr_ico)
            surface.SetDrawColor(borderCol)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        function ico:Think()
            self.bIsHovered = vgui.GetHoveredPanel() == self or vgui.GetHoveredPanel() == spawnIcon
        end

        return ico
    end

    function menu:AddNoneOption(onSelect)
        local ico = vgui.Create("DPanel", self.IconLayout)
        local icoSize = ScreenScale(36)
        ico:SetSize(icoSize, icoSize)
        ico.Accessor = "none"
        ico.bIsHovered = false

        function ico:Paint(w, h)
            local borderCol = self.bIsHovered and colors.scrollbarGripHover or colors.scrollbarBorder
            draw.RoundedBox(4, 0, 0, w, h, Color(18, 24, 18, 255))
            surface.SetDrawColor(borderCol)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            surface.SetDrawColor(colors.highlightText)
            local margin = ScreenScale(8)
            surface.DrawLine(margin, margin, w - margin, h - margin)
            surface.DrawLine(w - margin, margin, margin, h - margin)

            draw.SimpleText("Нет", "DermaDefault", w / 2, h - ScreenScale(4), colors.mainText, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        end

        function ico:Think()
            self.bIsHovered = vgui.GetHoveredPanel() == self
        end

        function ico:OnMousePressed(mc)
            if mc == MOUSE_LEFT then
                if onSelect then onSelect("none") end
                surface.PlaySound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav")
                menu:Close()
            end
        end

        function ico:OnCursorEntered()
            self:SetCursor("hand")
        end

        return ico
    end

    return menu
end

function PANEL:SetAppearance(tAppearacne)
    self.AppearanceTable = tAppearacne
end

function PANEL:CallbackAppearance()
end

function PANEL:First()
    self:SetY(self:GetY() + self:GetTall())
    self:MoveTo(self:GetX(), self:GetY() - self:GetTall(), 0.4, 0, 0.2)
    self:AlphaTo(255, 0.2, 0.1)
    if self.PostInit then
        self:PostInit()
    end
end

local sizeX, sizeY = ScrW() * 1, ScrH() * 1
local xbars = 17
local ybars = 30
local gradient_l = Material("vgui/gradient-l")
local sw, sh = ScrW(), ScrH()

function PANEL:Paint(w, h)
    surface.SetDrawColor(12, 18, 12, 255)
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(60, 180, 80, 18)
    for i = 1, (ybars + 1) do
        surface.DrawRect((sw / ybars) * i - (CurTime() * 30 % (sw / ybars)), 0, ScreenScale(1), sh)
    end
    for i = 1, (xbars + 1) do
        surface.DrawRect(0, (sh / xbars) * (i - 1) + (CurTime() * 30 % (sh / xbars)), sw, ScreenScale(1))
    end

    local border_size = 5
    surface.SetDrawColor(0, 0, 0)
    surface.SetMaterial(gradient_l)
    surface.DrawTexturedRect(0, 0, border_size, sh)
end

function PANEL:PostInit()
    local main = self
    self:SetBorder(false)
    self:SetDraggable(false)
    self.modelPosID = "Все"
    self.AppearanceTable = self.AppearanceTable or hg.Appearance.LoadAppearanceFile(hg.Appearance.SelectedAppearance:GetString()) or APmodule.GetRandomAppearance()
    local tMdl = APmodule.PlayerModels[1][self.AppearanceTable.AModel] or APmodule.PlayerModels[2][self.AppearanceTable.AModel]

    local viewer = vgui.Create("DModelPanel", self)
    viewer:SetSize(sizeX / 2.6, sizeY)
    viewer:SetModel(util.IsValidModel(tostring(tMdl.mdl)) and tostring(tMdl.mdl) or "models/player/group01/female_01.mdl")
    viewer:SetFOV(75)
    viewer:SetLookAng(Angle(11, 180, 0))
    viewer:SetCamPos(Vector(100, 0, 55))
    viewer:SetDirectionalLight(BOX_RIGHT, Color(0, 180, 70))
    viewer:SetDirectionalLight(BOX_LEFT, Color(120, 255, 160))
    viewer:SetDirectionalLight(BOX_FRONT, Color(160, 160, 160))
    viewer:SetDirectionalLight(BOX_BACK, Color(0, 0, 0))
    viewer:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
    viewer:SetDirectionalLight(BOX_BOTTOM, Color(0, 0, 0))
    viewer:Dock(FILL)
    viewer:SetAmbientLight(Color(120, 255, 140, 255))

    function viewer:OnMouseWheeled(delta)
        self.SmoothFOVDelta = self:GetFOV() - delta * 5
    end

    local offsets = {
        ["Все"] = 1,
        ["Голова"] = 1.15,
        ["Лицо"] = 1.1,
        ["Торс"] = 0.9,
        ["Ноги"] = 0.4,
        ["Ботинки"] = 0.1,
        ["Руки"] = 0.5
    }

    function viewer:Think()
        self.SmoothFOV = LerpFT(0.05, self.SmoothFOV or self:GetFOV(), main.modelPosID == "Все" and 75 or 35)
        self.LookAngles = LerpFT(0.05, self.LookAngles or 11, main.modelPosID == "Все" and 11 or 0)
        self:SetFOV(self.SmoothFOV)
        self:SetLookAng(Angle(self.LookAngles, 180, 0))
        self.OffsetY = LerpFT(0.1, self.OffsetY or 0, offsets[main.modelPosID] or 1)
    end

    local leftAnchorX = ScreenScale(8)
    local rightAnchorX = sizeX - ScreenScale(108)
    local baseY = sizeY * 0.22

    function viewer:LayoutEntity(Entity)
        local lookX, lookY = input.GetCursorPos()
        lookX = lookX / sizeX - 0.5
        lookY = lookY / sizeY - 0.5

        Entity.Angles = Entity.Angles or Angle(0, 0, 0)
        Entity.Angles = LerpAngle(FrameTime() * 5, Entity.Angles, Angle(lookY * 2, (self.Rotate and -179 or 0) - lookX * 75, 0))

        local tbl = main.AppearanceTable
        tMdl = APmodule.PlayerModels[1][tbl.AModel] or APmodule.PlayerModels[2][tbl.AModel]
        Entity:SetNWVector("PlayerColor", Vector(tbl.AColor.r / 255, tbl.AColor.g / 255, tbl.AColor.b / 255))
        Entity:SetAngles(Entity.Angles)
        Entity:SetSequence(Entity:LookupSequence("idle_suitcase"))
        Entity:SetSubMaterial()
        self:SetCamPos(Vector(100, 0, 55 * (self.OffsetY or 1)))

        if Entity:GetModel() ~= tMdl.mdl then
            Entity:SetModel(tMdl.mdl)
            self:SetModel(tMdl.mdl)
            tbl.AFacemap = "По умолчанию"
        end

        local mats = Entity:GetMaterials()
        for k, v in pairs(tMdl.submatSlots) do
            local slot = 1
            for i = 1, #mats do
                if mats[i] == v then
                    slot = i - 1
                    break
                end
            end
            Entity:SetSubMaterial(slot, hg.Appearance.Clothes[tMdl.sex and 2 or 1][tbl.AClothes[k]] or hg.Appearance.Clothes[tMdl.sex and 2 or 1].normal)
            Entity:SetNWString("Colthes" .. k, tbl.AClothes[k])
        end

        for i = 1, #mats do
            if hg.Appearance.FacemapsSlots[mats[i]] and hg.Appearance.FacemapsSlots[mats[i]][tbl.AFacemap] then
                Entity:SetSubMaterial(i - 1, hg.Appearance.FacemapsSlots[mats[i]][tbl.AFacemap])
            end
        end

        local bodygroups = Entity:GetBodyGroups()
        tbl.ABodygroups = tbl.ABodygroups or {}
        for k, v in ipairs(bodygroups) do
            if not tbl.ABodygroups[v.name] then continue end
            for i = 0, #v.submodels do
                local b = v.submodels[i]
                if not hg.Appearance.Bodygroups[v.name] then continue end
                if not hg.Appearance.Bodygroups[v.name][tMdl.sex and 2 or 1] then continue end
                if not hg.Appearance.Bodygroups[v.name][tMdl.sex and 2 or 1][tbl.ABodygroups[v.name]] then continue end
                if hg.Appearance.Bodygroups[v.name][tMdl.sex and 2 or 1][tbl.ABodygroups[v.name]][1] ~= b then continue end
                Entity:SetBodygroup(k - 1, i)
            end
        end
    end

    function viewer:PostDrawModel(Entity)
        local tbl = main.AppearanceTable
        for _, attach in ipairs(tbl.AAttachments) do
            DrawAccesories(Entity, Entity, attach, hg.Accessories[attach], false, true)
        end
        Entity:SetupBones()
    end

    function viewer.Entity:GetPlayerColor()
        return
    end

    local upPanel = vgui.Create("DPanel", viewer)
    upPanel:Dock(TOP)
    upPanel:DockMargin(ScreenScale(100), 0, ScreenScale(100), 0)
    upPanel:SetSize(1, ScreenScale(15))
    function upPanel:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, colors.secondary)
        surface.SetDrawColor(colors.scrollbarBorder)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local modelSelector = vgui.Create("DComboBox", upPanel)
    modelSelector:SetSize(ScreenScale(164), ScreenScale(15))
    modelSelector:SetFont("ZCity_Tiny")
    modelSelector:SetText(main.AppearanceTable.AModel)
    modelSelector:Dock(FILL)
    modelSelector:SetContentAlignment(5)

    function modelSelector:OnSelect(_, str)
        main.AppearanceTable.AModel = str
    end

    for k in pairs(APmodule.PlayerModels[1]) do
        modelSelector:AddChoice(k)
    end
    for k in pairs(APmodule.PlayerModels[2]) do
        modelSelector:AddChoice(k)
    end

    local bottomContainer = vgui.Create("DPanel", viewer)
    bottomContainer:Dock(BOTTOM)
    bottomContainer:SetSize(1, ScreenScale(50))
    bottomContainer:DockMargin(ScreenScale(50), 0, ScreenScale(50), ScreenScale(8))
    function bottomContainer:Paint() end

    local downPanel = vgui.Create("DPanel", bottomContainer)
    downPanel:Dock(BOTTOM)
    downPanel:SetSize(1, ScreenScale(15))
    downPanel:DockMargin(ScreenScale(44), 0, ScreenScale(44), 0)
    function downPanel:Paint() end

    local backViewButton = vgui.Create("DButton", downPanel)
    backViewButton:SetSize(ScreenScale(72), ScreenScale(15))
    backViewButton:SetFont("ZCity_Tiny")
    backViewButton:SetText("Повернуть")
    backViewButton:Dock(LEFT)

    function backViewButton:DoClick()
        viewer.Rotate = not viewer.Rotate
        surface.PlaySound("pwb2/weapons/iron.wav")
    end

    function backViewButton:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, colors.secondary)
        surface.SetDrawColor(colors.scrollbarBorder)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local ApplyButton = vgui.Create("DButton", downPanel)
    ApplyButton:SetSize(ScreenScale(72), ScreenScale(15))
    ApplyButton:SetFont("ZCity_Tiny")
    ApplyButton:SetText("Применить")
    ApplyButton:Dock(RIGHT)

    function ApplyButton:DoClick()
        hg.Appearance.CreateAppearanceFile(hg.Appearance.SelectedAppearance:GetString(), main.AppearanceTable)
        net.Start("OnlyGet_Appearance")
            net.WriteTable(main.AppearanceTable)
        net.SendToServer()
        surface.PlaySound("pwb2/weapons/iron.wav")
    end

    function ApplyButton:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, colors.selectionBG)
        surface.SetDrawColor(colors.scrollbarBorder)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local NameEntry = vgui.Create("DTextEntry", downPanel)
    NameEntry:SetSize(ScreenScale(164), ScreenScale(15))
    NameEntry:SetFont("ZCity_Tiny")
    NameEntry:SetText(main.AppearanceTable.AName)
    NameEntry:Dock(FILL)
    NameEntry:DockMargin(ScreenScale(4), 0, ScreenScale(4), 0)
    NameEntry:SetContentAlignment(5)

    function NameEntry:OnChange()
        main.AppearanceTable.AName = self:GetValue()
    end

    function NameEntry:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(12, 20, 12, 240))
        surface.SetDrawColor(colors.scrollbarBorder)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        self:DrawTextEntryText(colors.mainText, colors.selectionBG, colors.mainText)
    end

    local presetsPanel = vgui.Create("DPanel", bottomContainer)
    presetsPanel:Dock(BOTTOM)
    presetsPanel:SetSize(1, ScreenScale(16))
    presetsPanel:DockMargin(ScreenScale(60), 0, ScreenScale(60), ScreenScale(4))
    function presetsPanel:Paint() end

    local savePresetBtn = vgui.Create("DButton", presetsPanel)
    savePresetBtn:Dock(LEFT)
    savePresetBtn:SetSize(ScreenScale(30), ScreenScale(16))
    savePresetBtn:SetFont("ZCity_Tiny")
    savePresetBtn:SetText("Сохранить")
    savePresetBtn:SetTextColor(colors.mainText)
    savePresetBtn:DockMargin(0, 0, 5, 0)

    function savePresetBtn:Paint(w, h)
        local bgCol = self:IsHovered() and Color(40, 160, 60, 255) or colors.selectionBG
        draw.RoundedBox(4, 0, 0, w, h, bgCol)
        surface.SetDrawColor(colors.scrollbarBorder)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local presetNameEntry

    function savePresetBtn:DoClick()
        local presetName = presetNameEntry:GetValue()
        if presetName == "" or #presetName < 2 then
            surface.PlaySound("buttons/button10.wav")
            notification.AddLegacy("Введите имя пресета минимум из 2 символов", NOTIFY_ERROR, 3)
            return
        end
        presetName = string.Trim(string.Left(string.gsub(presetName, "[^%w%s_%-а-яА-Я]", ""), 64))
        if presetName == "" then
            surface.PlaySound("buttons/button10.wav")
            notification.AddLegacy("Некорректное имя пресета", NOTIFY_ERROR, 3)
            return
        end
        SavePreset(presetName, main.AppearanceTable)
        surface.PlaySound("buttons/button14.wav")
        notification.AddLegacy("Пресет '" .. presetName .. "' сохранён", NOTIFY_GENERIC, 3)
    end

    local loadPresetBtn = vgui.Create("DButton", presetsPanel)
    loadPresetBtn:Dock(LEFT)
    loadPresetBtn:SetSize(ScreenScale(30), ScreenScale(20))
    loadPresetBtn:SetFont("ZCity_Tiny")
    loadPresetBtn:SetText("Загрузить")
    loadPresetBtn:SetTextColor(colors.mainText)
    loadPresetBtn:DockMargin(0, 0, 5, 0)

    function loadPresetBtn:Paint(w, h)
        local bgCol = self:IsHovered() and Color(35, 125, 55, 255) or Color(24, 70, 34, 230)
        draw.RoundedBox(4, 0, 0, w, h, bgCol)
        surface.SetDrawColor(colors.scrollbarBorder)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    function loadPresetBtn:DoClick()
        local presetList = GetPresetList()
        if #presetList == 0 then
            surface.PlaySound("buttons/button10.wav")
            notification.AddLegacy("Сохранённых пресетов пока нет", NOTIFY_ERROR, 3)
            return
        end

        local presetMenu = vgui.Create("DFrame")
        presetMenu:SetTitle("Загрузка пресета")
        presetMenu:SetSize(ScreenScale(120), ScreenScale(100))
        presetMenu:Center()
        presetMenu:MakePopup()
        presetMenu:SetDraggable(false)

        function presetMenu:Paint(w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(10, 18, 10, 250))
            surface.SetDrawColor(colors.presetBorder)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
            draw.RoundedBoxEx(8, 0, 0, w, ScreenScale(12), colors.secondary, true, true, false, false)
        end

        local scroll = CreateStyledScrollPanel(presetMenu)
        scroll:Dock(FILL)
        scroll:DockMargin(ScreenScale(2), ScreenScale(2), ScreenScale(2), ScreenScale(2))

        for _, presetName in ipairs(presetList) do
            local presetBtn = vgui.Create("DButton", scroll)
            presetBtn:Dock(TOP)
            presetBtn:DockMargin(2, 2, 2, 0)
            presetBtn:SetTall(ScreenScale(14))
            presetBtn:SetFont("ZCity_Tiny")
            presetBtn:SetText(presetName)
            presetBtn:SetTextColor(colors.mainText)

            function presetBtn:Paint(w, h)
                local bgCol = self:IsHovered() and colors.presetHover or colors.presetBG
                draw.RoundedBox(4, 0, 0, w, h, bgCol)
                surface.SetDrawColor(colors.scrollbarBorder)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end

            function presetBtn:DoClick()
                local loadedPreset = LoadPreset(presetName)
                if loadedPreset then
                    main.AppearanceTable = loadedPreset
                    NameEntry:SetText(loadedPreset.AName or "")
                    modelSelector:SetText(loadedPreset.AModel or "Мужчина 01")
                    presetNameEntry:SetText(presetName)
                    surface.PlaySound("buttons/button14.wav")
                    notification.AddLegacy("Пресет '" .. presetName .. "' загружен", NOTIFY_GENERIC, 3)
                else
                    surface.PlaySound("buttons/button10.wav")
                    notification.AddLegacy("Не удалось загрузить пресет", NOTIFY_ERROR, 3)
                end
                presetMenu:Close()
            end

            function presetBtn:DoRightClick()
                local confirmMenu = DermaMenu()
                confirmMenu:AddOption("Удалить '" .. presetName .. "'", function()
                    DeletePreset(presetName)
                    surface.PlaySound("buttons/button15.wav")
                    notification.AddLegacy("Пресет удалён", NOTIFY_HINT, 2)
                    presetBtn:Remove()
                end):SetIcon("icon16/cross.png")
                confirmMenu:Open()
            end
        end
    end

    local deletePresetBtn = vgui.Create("DButton", presetsPanel)
    deletePresetBtn:Dock(LEFT)
    deletePresetBtn:SetSize(ScreenScale(35), ScreenScale(20))
    deletePresetBtn:SetFont("ZCity_Tiny")
    deletePresetBtn:SetText("Удалить")
    deletePresetBtn:SetTextColor(colors.mainText)

    function deletePresetBtn:Paint(w, h)
        local bgCol = self:IsHovered() and Color(70, 120, 70, 255) or Color(35, 80, 40, 230)
        draw.RoundedBox(4, 0, 0, w, h, bgCol)
        surface.SetDrawColor(colors.scrollbarBorder)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    function deletePresetBtn:DoClick()
        local presetName = presetNameEntry:GetValue()
        if presetName == "" then
            surface.PlaySound("buttons/button10.wav")
            notification.AddLegacy("Введите имя пресета для удаления", NOTIFY_ERROR, 3)
            return
        end

        if DeletePreset(presetName) then
            surface.PlaySound("buttons/button15.wav")
            notification.AddLegacy("Запрос на удаление пресета отправлен", NOTIFY_HINT, 3)
            presetNameEntry:SetText("")
        else
            surface.PlaySound("buttons/button10.wav")
            notification.AddLegacy("Не удалось удалить пресет", NOTIFY_ERROR, 3)
        end
    end

    presetNameEntry = vgui.Create("DTextEntry", presetsPanel)
    presetNameEntry:Dock(FILL)
    presetNameEntry:SetSize(ScreenScale(80), ScreenScale(20))
    presetNameEntry:SetFont("ZCity_Tiny")
    presetNameEntry:SetPlaceholderText("Имя пресета...")
    presetNameEntry:SetContentAlignment(5)
    presetNameEntry:DockMargin(5, 0, 0, 0)

    function presetNameEntry:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(12, 20, 12, 255))
        surface.SetDrawColor(colors.scrollbarBorder)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        self:DrawTextEntryText(colors.mainText, colors.selectionBG, colors.mainText)
    end

    local previewAccessory = {nil, nil, nil}
    local originalAccessory = {nil, nil, nil}
    local accessoryMenus = {}
    local lply = LocalPlayer()

    local function CloseAllAccessoryMenus()
        for _, menu in ipairs(accessoryMenus) do
            if IsValid(menu) then
                menu:Close()
            end
        end
        accessoryMenus = {}
    end

    local function MakeSideButton(text, side, yOffset, onClick)
        local btn = vgui.Create("DButton", viewer)
        btn:SetSize(ScreenScale(100), ScreenScale(16))
        btn:SetFont("ZCity_Tiny")
        btn:SetText(text)

        function btn:Think()
            if side == "left" then
                self:SetPos(leftAnchorX, baseY + yOffset)
            else
                self:SetPos(rightAnchorX, baseY + yOffset)
            end
        end

        function btn:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, colors.secondary)
            surface.SetDrawColor(colors.scrollbarBorder)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        function btn:DoClick()
            if onClick then onClick(self) end
        end

        return btn
    end

    local hatSelector = MakeSideButton("Головные уборы", "left", 0, function()
        main.modelPosID = "Голова"
        CloseAllAccessoryMenus()
        originalAccessory[1] = main.AppearanceTable.AAttachments[1]
        local hatSelectMenu = CreateStyledAccessoryMenu(nil, "Выбор головного убора")
        table.insert(accessoryMenus, hatSelectMenu)

        for k, v in pairs(hg.Accessories) do
            if v.placement ~= "head" and v.placement ~= "ears" then continue end
            if not lply:PS_HasItem(k) and v.bPointShop and not hg.Appearance.GetAccessToAll(lply) then continue end
            hatSelectMenu:AddAccessoryIcon(v.model, k, v,
                function(accessorKey)
                    main.AppearanceTable.AAttachments[1] = accessorKey
                    previewAccessory[1] = nil
                end,
                function(accessorKey, isPreviewing)
                    if isPreviewing then
                        previewAccessory[1] = accessorKey
                        main.AppearanceTable.AAttachments[1] = accessorKey
                    else
                        previewAccessory[1] = nil
                        main.AppearanceTable.AAttachments[1] = originalAccessory[1]
                    end
                end
            )
        end

        hatSelectMenu:AddNoneOption(function()
            main.AppearanceTable.AAttachments[1] = "none"
            previewAccessory[1] = nil
        end)

        function hatSelectMenu:OnClose()
            if previewAccessory[1] then
                main.AppearanceTable.AAttachments[1] = originalAccessory[1]
                previewAccessory[1] = nil
            end
            main.modelPosID = "Все"
        end

        function hatSelectMenu:OnFocusChanged(gained)
            if not gained then
                self:Close()
            end
        end
    end)

    local faceSelector = MakeSideButton("Аксессуары лица", "left", ScreenScale(32), function()
        main.modelPosID = "Лицо"
        CloseAllAccessoryMenus()
        originalAccessory[2] = main.AppearanceTable.AAttachments[2]
        local faceSelectorMenu = CreateStyledAccessoryMenu(nil, "Выбор аксессуара на лицо")
        table.insert(accessoryMenus, faceSelectorMenu)

        for k, v in pairs(hg.Accessories) do
            if v.placement ~= "face" then continue end
            if not lply:PS_HasItem(k) and v.bPointShop and not hg.Appearance.GetAccessToAll(lply) then continue end
            faceSelectorMenu:AddAccessoryIcon(v.model, k, v,
                function(accessorKey)
                    main.AppearanceTable.AAttachments[2] = accessorKey
                    previewAccessory[2] = nil
                end,
                function(accessorKey, isPreviewing)
                    if isPreviewing then
                        previewAccessory[2] = accessorKey
                        main.AppearanceTable.AAttachments[2] = accessorKey
                    else
                        previewAccessory[2] = nil
                        main.AppearanceTable.AAttachments[2] = originalAccessory[2]
                    end
                end
            )
        end

        faceSelectorMenu:AddNoneOption(function()
            main.AppearanceTable.AAttachments[2] = "none"
            previewAccessory[2] = nil
        end)

        function faceSelectorMenu:OnClose()
            if previewAccessory[2] then
                main.AppearanceTable.AAttachments[2] = originalAccessory[2]
                previewAccessory[2] = nil
            end
            main.modelPosID = "Все"
        end

        function faceSelectorMenu:OnFocusChanged(gained)
            if not gained then
                self:Close()
            end
        end
    end)

    local bodySelector = MakeSideButton("Аксессуары тела", "left", ScreenScale(64), function()
        main.modelPosID = "Торс"
        CloseAllAccessoryMenus()
        originalAccessory[3] = main.AppearanceTable.AAttachments[3]
        local bodySelectorMenu = CreateStyledAccessoryMenu(nil, "Выбор аксессуара на тело")
        table.insert(accessoryMenus, bodySelectorMenu)

        for k, v in pairs(hg.Accessories) do
            if v.placement ~= "torso" and v.placement ~= "spine" then continue end
            if not lply:PS_HasItem(k) and v.bPointShop and not hg.Appearance.GetAccessToAll(lply) then continue end
            bodySelectorMenu:AddAccessoryIcon(v.model, k, v,
                function(accessorKey)
                    main.AppearanceTable.AAttachments[3] = accessorKey
                    previewAccessory[3] = nil
                end,
                function(accessorKey, isPreviewing)
                    if isPreviewing then
                        previewAccessory[3] = accessorKey
                        main.AppearanceTable.AAttachments[3] = accessorKey
                    else
                        previewAccessory[3] = nil
                        main.AppearanceTable.AAttachments[3] = originalAccessory[3]
                    end
                end
            )
        end

        bodySelectorMenu:AddNoneOption(function()
            main.AppearanceTable.AAttachments[3] = "none"
            previewAccessory[3] = nil
        end)

        function bodySelectorMenu:OnClose()
            if previewAccessory[3] then
                main.AppearanceTable.AAttachments[3] = originalAccessory[3]
                previewAccessory[3] = nil
            end
            main.modelPosID = "Все"
        end

        function bodySelectorMenu:OnFocusChanged(gained)
            if not gained then
                self:Close()
            end
        end
    end)

    local torsoSelector = MakeSideButton("Торс", "left", ScreenScale(96), function()
        main.modelPosID = "Торс"
        local menu = DermaMenu()
        local bgKey = "TORSO"
        local sexTable = hg.Appearance.Bodygroups[bgKey] and hg.Appearance.Bodygroups[bgKey][tMdl.sex and 2 or 1]

        if sexTable then
            for name in SortedPairs(sexTable) do
                menu:AddOption(name, function()
                    surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
                    main.AppearanceTable.ABodygroups = main.AppearanceTable.ABodygroups or {}
                    main.AppearanceTable.ABodygroups[bgKey] = name
                end)
            end
        else
            menu:AddOption("Нет вариантов торса", function() end):SetEnabled(false)
        end

        menu:Open()
        function menu:OnRemove()
            main.modelPosID = "Все"
        end
    end)

    local legsBootsSelector = MakeSideButton("Ноги и обувь", "left", ScreenScale(128), function()
        main.modelPosID = "Ноги"
        local menu = DermaMenu()
        local bgKey = "LEGS"
        local sexTable = hg.Appearance.Bodygroups[bgKey] and hg.Appearance.Bodygroups[bgKey][tMdl.sex and 2 or 1]

        if sexTable then
            for name in SortedPairs(sexTable) do
                menu:AddOption(name, function()
                    surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
                    main.AppearanceTable.ABodygroups = main.AppearanceTable.ABodygroups or {}
                    main.AppearanceTable.ABodygroups[bgKey] = name
                end)
            end
        else
            menu:AddOption("Нет вариантов ног и обуви", function() end):SetEnabled(false)
        end

        menu:Open()
        function menu:OnRemove()
            main.modelPosID = "Все"
        end
    end)

    local bodyMatSelector = MakeSideButton("Куртка", "right", 0, function()
        main.modelPosID = "Торс"
        local menu = DermaMenu()

        for k in pairs(hg.Appearance.Clothes[tMdl.sex and 2 or 1]) do
            local mater = menu:AddOption(k, function()
                surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
                main.AppearanceTable.AClothes.main = k
            end)
            if hg.Appearance.ClothesDesc and hg.Appearance.ClothesDesc[k] then
                mater:SetTooltip(hg.Appearance.ClothesDesc[k].desc or "")
                if hg.Appearance.ClothesDesc[k].link then
                    function mater:DoRightClick()
                        gui.OpenURL(hg.Appearance.ClothesDesc[k].link)
                    end
                end
            end
        end

        local colorSelector = vgui.Create("DColorCombo", menu)
        function colorSelector:OnValueChanged(clr)
            main.AppearanceTable.AColor = clr
        end
        colorSelector:SetColor(main.AppearanceTable.AColor)
        menu:AddPanel(colorSelector)
        menu:Open()

        function menu:OnRemove()
            main.modelPosID = "Все"
        end
    end)

    local legsMatSelector = MakeSideButton("Штаны", "right", ScreenScale(32), function()
        main.modelPosID = "Ноги"
        local menu = DermaMenu()

        for k in pairs(hg.Appearance.Clothes[tMdl.sex and 2 or 1]) do
            local mater = menu:AddOption(k, function()
                surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
                main.AppearanceTable.AClothes.pants = k
            end)
            if hg.Appearance.ClothesDesc and hg.Appearance.ClothesDesc[k] then
                mater:SetTooltip(hg.Appearance.ClothesDesc[k].desc or "")
                if hg.Appearance.ClothesDesc[k].link then
                    function mater:DoRightClick()
                        gui.OpenURL(hg.Appearance.ClothesDesc[k].link)
                    end
                end
            end
        end

        menu:Open()
        function menu:OnRemove()
            main.modelPosID = "Все"
        end
    end)

    local bootsMatSelector = MakeSideButton("Ботинки", "right", ScreenScale(64), function()
        main.modelPosID = "Ботинки"
        local menu = DermaMenu()

        for k in pairs(hg.Appearance.Clothes[tMdl.sex and 2 or 1]) do
            local mater = menu:AddOption(k, function()
                surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
                main.AppearanceTable.AClothes.boots = k
            end)
            if hg.Appearance.ClothesDesc and hg.Appearance.ClothesDesc[k] then
                mater:SetTooltip(hg.Appearance.ClothesDesc[k].desc or "")
                if hg.Appearance.ClothesDesc[k].link then
                    function mater:DoRightClick()
                        gui.OpenURL(hg.Appearance.ClothesDesc[k].link)
                    end
                end
            end
        end

        menu:Open()
        function menu:OnRemove()
            main.modelPosID = "Все"
        end
    end)

    local glovesSelector = MakeSideButton("Перчатки", "right", ScreenScale(96), function()
        main.modelPosID = "Руки"
        local menu = DermaMenu()

        for k, v in pairs(hg.Appearance.Bodygroups.HANDS[tMdl.sex and 2 or 1] or {}) do
            if not lply:PS_HasItem(v.ID) and v[2] and not hg.Appearance.GetAccessToAll(lply) then continue end
            menu:AddOption(k, function()
                surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
                main.AppearanceTable.ABodygroups = main.AppearanceTable.ABodygroups or {}
                main.AppearanceTable.ABodygroups.HANDS = k
            end)
        end

        menu:Open()
        function menu:OnRemove()
            main.modelPosID = "Все"
        end
    end)

    local faceMatSelector = MakeSideButton("Лицо", "right", ScreenScale(128), function()
        main.modelPosID = "Лицо"
        local menu = DermaMenu()
        local facemaps = hg.Appearance.FacemapsSlots and hg.Appearance.FacemapsModels and hg.Appearance.FacemapsSlots[hg.Appearance.FacemapsModels[tMdl.mdl]] or {}

        for k in SortedPairs(facemaps) do
            menu:AddOption(k, function()
                surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
                main.AppearanceTable.AFacemap = k
            end)
        end

        menu:Open()
        function menu:OnRemove()
            main.modelPosID = "Все"
        end
    end)

    local oldClose = self.Close
    function self:Close()
        CloseAllAccessoryMenus()
        if oldClose then
            oldClose(self)
        end
    end

    self:CallbackAppearance()
end

vgui.Register("HG_AppearanceMenu", PANEL, "ZFrame")

function hg.CreateApperanceMenu(ParentPanel)
    if hg.Appearance.PrecacheModels then
        hg.Appearance.PrecacheModels()
    end

    hg.PointShop:SendNET("SendPointShopVars", nil, function()
        if IsValid(zpan) then
            zpan:Close()
        end
        zpan = vgui.Create("HG_AppearanceMenu", ParentPanel)
        zpan:SetSize(ParentPanel:GetWide(), ParentPanel:GetTall())
        zpan:SetPos(0, 0)
    end)
end

concommand.Add("hg_appearance_menu", function()
    if hg.Appearance.PrecacheModels then
        hg.Appearance.PrecacheModels()
    end

    net.Start("hg_appearance_presets_request")
    net.SendToServer()

    hg.PointShop:SendNET("SendPointShopVars", nil, function()
        if IsValid(zpan) then
            zpan:Close()
        end
        zpan = vgui.Create("HG_AppearanceMenu")
        zpan:SetSize(sizeX, sizeY)
        zpan:SetPos(0, 0)
        zpan:MakePopup()
    end)
end)