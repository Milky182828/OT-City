util.AddNetworkString("Get_Appearance")
util.AddNetworkString("OnlyGet_Appearance")
util.AddNetworkString("hg_appearance_presets_request")
util.AddNetworkString("hg_appearance_presets_sync")
util.AddNetworkString("hg_appearance_preset_save")
util.AddNetworkString("hg_appearance_preset_delete")

hg.Appearance = hg.Appearance or {}
local APmodule = hg.Appearance

hg.PointShop = hg.PointShop or {}
local PSmodule = hg.PointShop

local MDATA_APPEARANCE_KEY = "hg_appearance_selected"
local MDATA_PRESETS_KEY = "hg_appearance_presets"

local function RK_HasDonateAccessoryLocal(ply, uid)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    uid = tostring(uid or "")
    if uid == "" then return false end

    if isfunction(_G.RK_HasDonateAccessory) then
        local ok, has = pcall(_G.RK_HasDonateAccessory, ply, uid)
        if ok and has == true then
            return true
        end
    end

    if PSmodule and PSmodule.Items and PSmodule.Items[uid] and ply.PS_HasItem then
        local ok, has = pcall(ply.PS_HasItem, ply, uid)
        if ok and has == true then
            return true
        end
    end

    return false
end

local function CanUseMData(ply)
    return mdata and isfunction(mdata.IsLoaded) and mdata:IsLoaded(ply) and isfunction(ply.SetMData) and isfunction(ply.GetMData)
end

local function EncodeAppearance(tbl)
    if not istable(tbl) then return "" end
    return util.TableToJSON(tbl, false) or ""
end

local function DecodeAppearance(raw)
    if not isstring(raw) or raw == "" then return nil end
    local tbl = util.JSONToTable(raw)
    if not istable(tbl) then return nil end
    if not APmodule.AppearanceValidater(tbl) then return nil end
    return tbl
end

local function GetSavedAppearanceFromMData(ply)
    if not CanUseMData(ply) then return nil end
    return DecodeAppearance(ply:GetMData(MDATA_APPEARANCE_KEY, ""))
end

local function SaveAppearanceToMData(ply, tbl)
    if not CanUseMData(ply) then return end
    if not istable(tbl) then return end
    if not APmodule.AppearanceValidater(tbl) then return end
    ply:SetMData(MDATA_APPEARANCE_KEY, EncodeAppearance(tbl))
end

local function GetSavedPresetsFromMData(ply)
    if not CanUseMData(ply) then return {} end
    local raw = ply:GetMData(MDATA_PRESETS_KEY, "")
    if not isstring(raw) or raw == "" then return {} end

    local decoded = util.JSONToTable(raw)
    if not istable(decoded) then return {} end

    local presets = {}
    for name, tbl in pairs(decoded) do
        name = string.Trim(tostring(name or ""))
        if name ~= "" and istable(tbl) and APmodule.AppearanceValidater(tbl) then
            presets[name] = tbl
        end
    end

    return presets
end

local function SavePresetsToMData(ply, presets)
    if not CanUseMData(ply) then return end
    presets = istable(presets) and presets or {}

    local sanitized = {}
    for name, tbl in pairs(presets) do
        name = string.Trim(tostring(name or ""))
        if name ~= "" and istable(tbl) and APmodule.AppearanceValidater(tbl) then
            sanitized[name] = tbl
        end
    end

    ply:SetMData(MDATA_PRESETS_KEY, util.TableToJSON(sanitized, false) or "{}")
end

local function SyncPresetsToClient(ply)
    if not IsValid(ply) then return end
    net.Start("hg_appearance_presets_sync")
        net.WriteTable(GetSavedPresetsFromMData(ply))
    net.Send(ply)
end

local function GetAppearanceModel(tbl)
    if not istable(tbl) then return nil, nil end
    local modelKey = tbl.AModel
    local tMdl = APmodule.PlayerModels[1][modelKey] or APmodule.PlayerModels[2][modelKey] or modelKey
    local mdl = istable(tMdl) and tMdl.mdl or tMdl

    if not isstring(mdl) or mdl == "" then
        return tMdl, nil
    end

    return tMdl, mdl
end

local function CheckAttachments(ply, tbl)
    if not IsValid(ply) or not ply:IsPlayer() then return tbl end
    if not istable(tbl) then return tbl end
    if hg.Appearance.GetAccessToAll and hg.Appearance.GetAccessToAll(ply) then return tbl end

    tbl.AAttachments = tbl.AAttachments or {}

    for i = 1, #tbl.AAttachments do
        local uid = tostring(tbl.AAttachments[i] or "")

        if uid == "" or uid == "none" or uid == "Убрать" then
            tbl.AAttachments[i] = ""
            continue
        end

        local acc = hg.Accessories and hg.Accessories[uid]

        if not acc then
            if PSmodule.Items and PSmodule.Items[uid] then
                if not RK_HasDonateAccessoryLocal(ply, uid) then
                    tbl.AAttachments[i] = ""
                end
            else
                tbl.AAttachments[i] = ""
            end
            continue
        end

        if acc.disallowinappearance then
            tbl.AAttachments[i] = ""
            continue
        end

        local shopUID = hg.Appearance.GetAccessoryShopUID and hg.Appearance.GetAccessoryShopUID(acc, uid) or uid
        local restricted = hg.Appearance.IsAccessoryDonateRestricted and hg.Appearance.IsAccessoryDonateRestricted(acc) or acc.bPointShop == true

        if restricted and not RK_HasDonateAccessoryLocal(ply, shopUID) then
            tbl.AAttachments[i] = ""
            continue
        end
    end

    local tMdl = APmodule.PlayerModels[1][tbl.AModel] or APmodule.PlayerModels[2][tbl.AModel] or tbl.AModel
    tbl.ABodygroups = tbl.ABodygroups or {}

    for k, v in pairs(tbl.ABodygroups) do
        if not hg.Appearance.Bodygroups[k] then continue end
        if not hg.Appearance.Bodygroups[k][tMdl.sex and 2 or 1] then continue end

        local bodygroup = hg.Appearance.Bodygroups[k][tMdl.sex and 2 or 1][v]
        if not bodygroup then
            tbl.ABodygroups[k] = nil
            continue
        end

        local uid = tostring(bodygroup.ID or "")
        if bodygroup[2] and uid ~= "" and not RK_HasDonateAccessoryLocal(ply, uid) then
            tbl.ABodygroups[k] = nil
        end
    end

    return tbl
end

local function ClearAppearanceDetails(ply)
    if not IsValid(ply) then return end

    ply:SetSubMaterial()
    local mats = ply:GetMaterials() or {}
    for i = 1, #mats do
        ply:SetSubMaterial(i - 1, nil)
    end

    ply:SetBodyGroups("00000000000000000000")

    local bodygroups = ply:GetBodyGroups() or {}
    for k = 1, #bodygroups do
        ply:SetBodygroup(k - 1, 0)
    end

    ply:SetNetVar("Accessories", {})
    ply:SetNWString("Colthes1", "normal")
    ply:SetNWString("Colthes2", "normal")
    ply:SetNWString("Colthes3", "normal")
    ply:SetNWString("Colthes4", "normal")
    ply:SetNWString("Colthes5", "normal")
end

local function ForceApplyAppearance(ply, tbl, noModelChange)
    if not IsValid(ply) then return end
    if not istable(tbl) then return end

    local tMdl, mdl = GetAppearanceModel(tbl)

    if mdl and not noModelChange and ply:GetModel() ~= mdl then
        ply:SetModel(mdl)
    end

    local clr = tbl.AColor or Color(255, 255, 255)
    if ply.SetPlayerColor then
        ply:SetPlayerColor(Vector(clr.r / 255, clr.g / 255, clr.b / 255))
    end
    ply:SetNWVector("PlayerColor", Vector(clr.r / 255, clr.g / 255, clr.b / 255))

    ClearAppearanceDetails(ply)

    local mats = ply:GetMaterials() or {}

    if istable(tMdl) and istable(tMdl.submatSlots) then
        for k, v in pairs(tMdl.submatSlots) do
            local slot = nil

            for i = 1, #mats do
                if mats[i] == v then
                    slot = i - 1
                    break
                end
            end

            if slot ~= nil then
                local sexIndex = tMdl.sex and 2 or 1
                local clothesKey = tbl.AClothes and tbl.AClothes[k] or "normal"
                local clothesMat = hg.Appearance.Clothes[sexIndex][clothesKey] or hg.Appearance.Clothes[sexIndex]["normal"]
                ply:SetSubMaterial(slot, clothesMat)
                ply:SetNWString("Colthes" .. k, clothesKey or "normal")
            end
        end
    end

    for i = 1, #mats do
        if hg.Appearance.FacemapsSlots[mats[i]] and hg.Appearance.FacemapsSlots[mats[i]][tbl.AFacemap] then
            ply:SetSubMaterial(i - 1, hg.Appearance.FacemapsSlots[mats[i]][tbl.AFacemap])
        end
    end

    ply:SetNWString("PlayerName", tbl.AName or "")
    tbl.ABodygroups = tbl.ABodygroups or {}

    local bodygroups = ply:GetBodyGroups() or {}
    for k, v in ipairs(bodygroups) do
        if not v.name then continue end
        if not tbl.ABodygroups[v.name] then continue end
        if not hg.Appearance.Bodygroups[v.name] then continue end
        if not hg.Appearance.Bodygroups[v.name][tMdl.sex and 2 or 1] then continue end

        local wanted = hg.Appearance.Bodygroups[v.name][tMdl.sex and 2 or 1][tbl.ABodygroups[v.name]]
        if not wanted then continue end

        for i = 0, #v.submodels do
            local b = v.submodels[i]
            if wanted[1] ~= b then continue end
            ply:SetBodygroup(k - 1, i)
            break
        end
    end

    ply:SetNetVar("Accessories", tbl.AAttachments or {})

    ply.CurAppearance = {}
    table.CopyFromTo(tbl, ply.CurAppearance)
    ply.CachedAppearance = {}
    table.CopyFromTo(tbl, ply.CachedAppearance)
end

local function WearAppearance(ply, tbl, noModelChange)
    if not istable(tbl) then return end
    local checked = table.Copy(tbl)
    checked.AAttachments = table.Copy(tbl.AAttachments or {})
    checked.ABodygroups = table.Copy(tbl.ABodygroups or {})
    checked.AClothes = table.Copy(tbl.AClothes or {})
    checked = CheckAttachments(ply, checked)
    ForceApplyAppearance(ply, checked, noModelChange)
end

APmodule.ForceApplyAppearance = ForceApplyAppearance

local tWaitResponse = {}

function ApplyAppearance(Client, tAppearance, bRandom, bResponeIsValid, bUseCached)
    if not IsValid(Client) then return end

    if bRandom or (Client.IsBot and Client:IsBot()) or (Client.IsRagdoll and Client:IsRagdoll()) then
        tAppearance = APmodule.GetRandomAppearance()
        WearAppearance(Client, tAppearance, false)
        return
    end

    if bUseCached then
        local saved = GetSavedAppearanceFromMData(Client)
        tAppearance = saved or Client.CachedAppearance or APmodule.GetRandomAppearance()

        if not APmodule.AppearanceValidater(tAppearance) then
            tAppearance = APmodule.GetRandomAppearance()
        end

        Client.CachedAppearance = tAppearance

        net.Start("OnlyGet_Appearance")
        net.Send(Client)

        WearAppearance(Client, tAppearance, false)
        return
    end

    if not bResponeIsValid then
        tWaitResponse[Client] = CurTime() + 3
        net.Start("Get_Appearance")
        net.Send(Client)
        return
    end

    if not tWaitResponse[Client] then return end
    if tWaitResponse[Client] < CurTime() then
        ApplyAppearance(Client, nil, true)
        return
    end

    if not tAppearance then
        ApplyAppearance(Client, nil, true)
        return
    end

    if not APmodule.AppearanceValidater(tAppearance) then
        ApplyAppearance(Client, nil, true)
        return
    end

    tAppearance = CheckAttachments(Client, tAppearance)
    Client.CachedAppearance = tAppearance
    SaveAppearanceToMData(Client, tAppearance)
    WearAppearance(Client, tAppearance, false)
end

net.Receive("Get_Appearance", function(_, client)
    local tAppearance = net.ReadTable()
    local bRandom = net.ReadBool()

    if not APmodule.AppearanceValidater(tAppearance) then
        bRandom = true
    end

    if not bRandom and tAppearance and APmodule.AppearanceValidater(tAppearance) then
        tAppearance = CheckAttachments(client, tAppearance)
        SaveAppearanceToMData(client, tAppearance)
    end

    ApplyAppearance(client, tAppearance, table.IsEmpty(tAppearance or {}) and true or bRandom, true)
end)

net.Receive("OnlyGet_Appearance", function(_, client)
    local tAppearance = net.ReadTable()
    local bRandom = not tAppearance or table.IsEmpty(tAppearance)

    if bRandom then
        return
    end

    if not APmodule.AppearanceValidater(tAppearance) then
        return
    end

    tAppearance = CheckAttachments(client, tAppearance)
    client.CachedAppearance = tAppearance
    SaveAppearanceToMData(client, tAppearance)
end)

net.Receive("hg_appearance_presets_request", function(_, ply)
    SyncPresetsToClient(ply)
end)

net.Receive("hg_appearance_preset_save", function(_, ply)
    local presetName = string.Trim(net.ReadString() or "")
    local appearance = net.ReadTable()

    if presetName == "" then return end
    presetName = string.Left(string.gsub(presetName, "[^%w%s_%-а-яА-Я]", ""), 64)
    if presetName == "" then return end
    if not istable(appearance) then return end
    if not APmodule.AppearanceValidater(appearance) then return end

    appearance = CheckAttachments(ply, appearance)

    local presets = GetSavedPresetsFromMData(ply)
    presets[presetName] = appearance
    SavePresetsToMData(ply, presets)
    SyncPresetsToClient(ply)
end)

net.Receive("hg_appearance_preset_delete", function(_, ply)
    local presetName = string.Trim(net.ReadString() or "")
    if presetName == "" then return end

    local presets = GetSavedPresetsFromMData(ply)
    presets[presetName] = nil
    SavePresetsToMData(ply, presets)
    SyncPresetsToClient(ply)
end)

APmodule.ApplyAppearance = ApplyAppearance

function ApplyAppearanceRagdoll(ent, ply)
    local Appearance = ply.CurAppearance
    if not Appearance then return end

    ent:SetNWString("PlayerName", ply:GetNWString("PlayerName", Appearance.AName))

    ent:SetNetVar("Accessories", ply:GetNetVar("Accessories", ""))

    local tMdl = APmodule.PlayerModels[1][ent:GetModel()] or APmodule.PlayerModels[2][ent:GetModel()] or ent:GetModel()
    if istable(tMdl) and istable(tMdl.submatSlots) then
        for k, _ in pairs(tMdl.submatSlots) do
            ent:SetNWString("Colthes" .. k, ply:GetNWString("Colthes" .. k, "normal"))
        end
    end
end

hook.Add("PlayerInitialSpawn", "hg.Appearance.SyncPresetsOnJoin", function(ply)
    timer.Create("hg.Appearance.WaitMData." .. ply:SteamID64(), 0.25, 40, function()
        if not IsValid(ply) then
            timer.Remove("hg.Appearance.WaitMData." .. tostring(ply:SteamID64()))
            return
        end

        if CanUseMData(ply) then
            SyncPresetsToClient(ply)
            timer.Remove("hg.Appearance.WaitMData." .. ply:SteamID64())
        end
    end)
end)

if engine.ActiveGamemode() == "sandbox" then
    hook.Add("PlayerSpawn", "SetAppearance", function(ply)
        if OverrideSpawn then return end

        timer.Create("hg.Appearance.ApplySaved." .. ply:SteamID64(), 0.25, 40, function()
            if not IsValid(ply) then
                timer.Remove("hg.Appearance.ApplySaved." .. tostring(ply:SteamID64()))
                return
            end

            if CanUseMData(ply) then
                ApplyAppearance(ply, nil, nil, nil, true)
                timer.Remove("hg.Appearance.ApplySaved." .. ply:SteamID64())
            end
        end)
    end)
end