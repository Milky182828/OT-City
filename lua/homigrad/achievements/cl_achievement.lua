hg.achievements = hg.achievements or {}
hg.achievements.achievements_data = hg.achievements.achievements_data or {}
hg.achievements.achievements_data.player_achievements = hg.achievements.achievements_data.player_achievements or {}
hg.achievements.achievements_data.created_achevements = {}

hg.achievements.MenuPanel = hg.achievements.MenuPanel or nil

local CreateMenuPanel

concommand.Add("hg_achievements", function()
    CreateMenuPanel()
end)

BlurBackground = BlurBackground or hg.DrawBlur
local gradient_u = Material("vgui/gradient-u")
local gradient_d = Material("vgui/gradient-d")

local function GetPlayerAchievements()
    local sid = tostring(LocalPlayer():SteamID())
    hg.achievements.achievements_data.player_achievements[sid] = hg.achievements.achievements_data.player_achievements[sid] or {}
    return hg.achievements.achievements_data.player_achievements[sid]
end

local function GetAchievementProgress(ach)
    local localach = GetPlayerAchievements()
    local data = localach[ach.key] or {}
    local startValue = tonumber(ach.start_value) or 0
    local neededValue = tonumber(ach.needed_value) or 1
    local value = tonumber(data.value) or startValue
    local progress = math.Clamp(neededValue > 0 and (value / neededValue) or 0, 0, 1)
    local complete = value >= neededValue
    return value, neededValue, progress, complete
end

local function PaintFrame(self, w, h)
    BlurBackground(self)
    surface.SetDrawColor(18, 28, 24, 240)
    draw.RoundedBox(0, 0, 0, w, h, Color(18, 28, 24, 240))
    surface.SetDrawColor(0, 255, 179, 20)
    surface.SetMaterial(gradient_d)
    surface.DrawTexturedRect(0, 0, w, h)
    surface.SetDrawColor(0, 255, 179, 90)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
end

local function PaintButton(self, w, h)
    BlurBackground(self)
    local hovered = self:IsHovered()
    self.hoverLerp = Lerp(FrameTime() * 10, self.hoverLerp or 0, hovered and 1 or 0)
    draw.RoundedBox(0, 0, 0, w, h, Color(12, 18, 16, 230))
    surface.SetDrawColor(0, 255, 179, 35 + 35 * self.hoverLerp)
    surface.SetMaterial(gradient_u)
    surface.DrawTexturedRect(0, 0, w, h)
    surface.SetDrawColor(0, 255, 179, 70 + 90 * self.hoverLerp)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
end

local function createButton(frame, ach, func)
    local button = vgui.Create("DButton", frame)

    ach.img = isstring(ach.img) and Material(ach.img) or ach.img
    local desc = markup.Parse("<font=HomigradFontMedium>" .. (ach.description or "Нет описания") .. "</font>", 900)

    function button:Paint(w, h)
        PaintButton(self, w, h)

        local value, neededValue, progress, complete = GetAchievementProgress(ach)
        local percent = math.Round(progress * 100)
        local pad = ScreenScale(5)
        local iconSize = h - pad * 4
        local textX = pad * 3 + iconSize
        local barW = w - textX - pad * 3
        local barH = ScreenScale(5)

        if ach.img then
            surface.SetDrawColor(255, 255, 255, complete and 255 or 220)
            surface.SetMaterial(ach.img)
            surface.DrawTexturedRect(pad * 2, pad * 2, iconSize, iconSize)
            surface.SetDrawColor(0, 255, 179, complete and 160 or 70)
            surface.DrawOutlinedRect(pad * 2, pad * 2, iconSize, iconSize, 2)
        end

        surface.SetFont("HomigradFont")
        local title = ach.name or "Без названия"
        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos(textX, pad * 1)
        surface.DrawText(title)

        local stateText = complete and "Получено" or "В процессе"
        surface.SetFont("HomigradFontMedium")
        local stateW = surface.GetTextSize(stateText)
        surface.SetTextColor(complete and 120 or 220, 255, complete and 120 or 220)
        surface.SetTextPos(w - stateW - pad * 3, pad * 2)
        surface.DrawText(stateText)

        local progressText = tostring(value) .. " / " .. tostring(neededValue)
        if ach.showpercent then
            progressText = progressText .. "   (" .. percent .. "%)"
        end

        surface.SetFont("HomigradFontMedium")
        surface.SetTextColor(230, 230, 230)
        surface.SetTextPos(textX, ScreenScale(14))
        surface.DrawText(progressText)

        local progressY = ScreenScale(22)
        draw.RoundedBox(0, textX, progressY, barW, barH, Color(0, 0, 0, 180))
        draw.RoundedBox(0, textX, progressY, math.max(barW * progress, 4), barH, complete and Color(90, 255, 120) or Color(0, 220, 170))
        surface.SetDrawColor(255, 255, 255, 10)
        surface.DrawOutlinedRect(textX, progressY, barW, barH, 1)

        desc:Draw(textX, progressY + barH + ScreenScale(1), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local glowX = w - 120 + self.hoverLerp * 35
        surface.SetDrawColor(255, 255, 255, 12 + 18 * self.hoverLerp)
        draw.NoTexture()
        surface.DrawTexturedRectRotated(glowX, 0, 14, h * 1.8, -30)
        surface.DrawTexturedRectRotated(glowX + 28, 0, 10, h * 1.8, -30)
    end

    button:SetText("")
    button:SetTall(ScreenScale(46))
    button:Dock(TOP)
    button:DockMargin(0, 0, 0, ScreenScale(3))
    button.DoClick = function(self)
        func(self)
    end

    return button
end

CreateMenuPanel = function()
    hg.achievements.LoadAchievements()

    if IsValid(hg.achievements.MenuPanel) then
        hg.achievements.MenuPanel:Remove()
        hg.achievements.MenuPanel = nil
    end

    local frame = vgui.Create("ZFrame")
    hg.achievements.MenuPanel = frame
    frame:SetTitle("")
    frame:SetSize(ScrW() * 0.55, ScrH() * 0.72)
    frame:SetPos(ScrW() * 0.5 - frame:GetWide() * 0.5, ScrH() + 500)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false)
    frame:SetAlpha(0)
    frame.OnClose = function()
        frame = nil
    end

    local pad = ScreenScale(8)
    local headerH = ScreenScale(26)
    frame:DockPadding(pad, pad, pad, pad)

    frame:MoveTo(frame:GetX(), ScrH() * 0.5 - frame:GetTall() * 0.5, 0.5, 0, 0.3)
    frame:AlphaTo(255, 0.25, 0)

    function frame:Paint(w, h)
        PaintFrame(self, w, h)
    end

    function frame:Close()
        self:MoveTo(self:GetX(), ScrH() + 500, 0.5, 0, 0.3, function()
            self:Remove()
        end)
        self:AlphaTo(0, 0.1, 0)
        self:SetKeyboardInputEnabled(false)
        self:SetMouseInputEnabled(false)
    end

    local header = vgui.Create("DPanel", frame)
    header:Dock(TOP)
    header:SetTall(headerH)

    function header:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(8, 14, 12, 220))
        surface.SetDrawColor(0, 255, 179, 30)
        surface.SetMaterial(gradient_u)
        surface.DrawTexturedRect(0, 0, w, h)
        surface.SetDrawColor(0, 255, 179, 80)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        local created = hg.achievements.achievements_data.created_achevements or {}
        local localach = GetPlayerAchievements()
        local total = table.Count(created)
        local unlocked = 0

        for _, ach in pairs(created) do
            local data = localach[ach.key]
            local value = tonumber(data and data.value) or tonumber(ach.start_value) or 0
            local needed = tonumber(ach.needed_value) or 1
            if value >= needed then
                unlocked = unlocked + 1
            end
        end

        surface.SetFont("HomigradFont")
        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos(ScreenScale(4), ScreenScale(2))
        surface.DrawText("Достижения")

        local info = "Открыто: " .. unlocked .. " / " .. total
        surface.SetFont("HomigradFontMedium")
        local wt = surface.GetTextSize(info)
        surface.SetTextColor(200, 255, 235)
        surface.SetTextPos(w - wt - ScreenScale(4), ScreenScale(4))
        surface.DrawText(info)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(0, ScreenScale(3), 0, 0)
    frame.scroll = scroll

    local sbar = scroll:GetVBar()
    sbar:SetHideButtons(true)

    function sbar:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 100))
    end

    function sbar.btnGrip:Paint(w, h)
        self.lerpcolor = Lerp(FrameTime() * 10, self.lerpcolor or 0.2, self:IsHovered() and 0.9 or 0.65)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 210 * self.lerpcolor, 160 * self.lerpcolor, 220))
    end

    function frame:UpdateValues()
        self.scroll:Clear()

        local achievements = hg.achievements.achievements_data.created_achevements or {}
        local sorted = {}

        for _, ach in pairs(achievements) do
            table.insert(sorted, ach)
        end

        table.sort(sorted, function(a, b)
            local _, _, pa, ca = GetAchievementProgress(a)
            local _, _, pb, cb = GetAchievementProgress(b)
            if ca ~= cb then
                return ca
            end
            if pa ~= pb then
                return pa > pb
            end
            return (a.name or "") < (b.name or "")
        end)

        for _, ach in ipairs(sorted) do
            self.scroll:AddItem(createButton(self.scroll, ach, function() end))
        end
    end

    frame:UpdateValues()
end

local time_wait = 0

function hg.achievements.LoadAchievements()
    if time_wait > CurTime() then return end
    time_wait = CurTime() + 2

    net.Start("req_ach")
    net.SendToServer()
end

function hg.achievements.GetLocalAchievements()
    return hg.achievements.achievements_data.player_achievements[tostring(LocalPlayer():SteamID())]
end

net.Receive("req_ach", function()
    hg.achievements.achievements_data.created_achevements = net.ReadTable()
    hg.achievements.achievements_data.player_achievements[tostring(LocalPlayer():SteamID())] = net.ReadTable()

    if IsValid(hg.achievements.MenuPanel) then
        hg.achievements.MenuPanel:UpdateValues()
    end
end)

hg.achievements.NewAchievements = hg.achievements.NewAchievements or {}
local AchTable = hg.achievements.NewAchievements

net.Receive("hg_NewAchievement", function()
    local Ach = {
        time = CurTime() + 7.5,
        name = net.ReadString(),
        img = net.ReadString()
    }

    table.insert(AchTable, 1, Ach)
    surface.PlaySound("homigrad/vgui/achievement_earned.wav")
end)

local ach_clr1, ach_clr2 = Color(8, 221, 79), Color(100, 25, 25)

hook.Add("HUDPaint", "hg_NewAchievement", function()
    local frametime = FrameTime() * 10

    for i = 1, #AchTable do
        local ach = AchTable[i]
        if not ach then continue end

        local txt = "Достижение! " .. ach.name
        ach.img = isstring(ach.img) and Material(ach.img) or ach.img

        surface.SetFont("HomigradFontMedium")
        local wt, ht = surface.GetTextSize(txt)

        ach.Lerp = Lerp(frametime, ach.Lerp or 0, math.min(ach.time - CurTime(), 1) * i)

        local WSize = math.max(ScrW() * 0.18, wt + ScrH() * 0.06)
        local HSize = ScrH() * 0.06
        local HPos = ScrH() - (HSize * ach.Lerp)

        draw.RoundedBox(0, 2, HPos + 2, WSize - 4, HSize - 4, ach_clr2)
        surface.SetDrawColor(6, 243, 65)
        surface.SetMaterial(gradient_u)
        surface.DrawTexturedRect(0, HPos, WSize, HSize)
        surface.SetDrawColor(1, 255, 77)
        surface.DrawOutlinedRect(0, HPos, WSize, HSize, 2.5)

        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos(HSize * 1.15, HPos + (HSize / 2) - (ht / 2))
        surface.DrawText(txt)

        if ach.img then
            surface.SetDrawColor(255, 255, 255)
            surface.SetMaterial(ach.img)
            surface.DrawTexturedRect(2, HPos + 2, HSize - 4, HSize - 4)
        end

        if ach.time < CurTime() then
            table.remove(AchTable, i)
        end
    end
end)