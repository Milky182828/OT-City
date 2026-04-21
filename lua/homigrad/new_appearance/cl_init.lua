hg.Appearance = hg.Appearance or {}

hg.Appearance.SelectedAppearance = ConVarExists("hg_appearance_selected") and GetConVar("hg_appearance_selected") or CreateClientConVar("hg_appearance_selected", "main", true, false, "имя активного внешнего пресета")
hg.Appearance.ForcedRandom = ConVarExists("hg_appearance_force_random") and GetConVar("hg_appearance_force_random") or CreateClientConVar("hg_appearance_force_random", "0", true, false, "принудительно случайная внешность", 0, 1)
hg.Appearance.PresetsCache = hg.Appearance.PresetsCache or {}

RK_DonateAccessories = RK_DonateAccessories or {}

function RK_HasDonateAccessory(ply, uid)
    if not IsValid(ply) then return false end
    if ply ~= LocalPlayer() then return false end

    uid = tostring(uid or "")
    if uid == "" then return false end

    RK_DonateAccessories = RK_DonateAccessories or {}
    return RK_DonateAccessories[uid] == true
end

timer.Simple(0.1, function()
    netstream.Hook("rk_donate_accs_sync", function(data)
        RK_DonateAccessories = {}
        if not istable(data) then return end
        if not istable(data.items) then return end

        for uid, has in pairs(data.items) do
            if has == true then
                RK_DonateAccessories[tostring(uid)] = true
            end
        end
    end)
end)

local function DecodeAppearanceRaw(raw)
    if not isstring(raw) or raw == "" then return nil end
    local tbl = util.JSONToTable(raw)
    if not istable(tbl) then return nil end
    if hg.Appearance.AppearanceValidater and not hg.Appearance.AppearanceValidater(tbl) then return nil end
    return tbl
end

local function SaveLocalAppearance(tbl)
    if not istable(tbl) then return end
    hg.Appearance.ClientSavedAppearance = table.Copy(tbl)
    hg.Appearance.ClientSavedAppearanceRaw = util.TableToJSON(tbl, false) or ""
end

local function GetLocalAppearanceRaw()
    local lply = LocalPlayer()
    if IsValid(lply) and lply.GetMData then
        local raw = lply:GetMData("hg_appearance_selected", "")
        if isstring(raw) and raw ~= "" then
            return raw
        end
    end

    if isstring(hg.Appearance.ClientSavedAppearanceRaw) and hg.Appearance.ClientSavedAppearanceRaw ~= "" then
        return hg.Appearance.ClientSavedAppearanceRaw
    end

    return ""
end

function hg.Appearance.CreateAppearanceFile(_, tblAppearance)
    SaveLocalAppearance(tblAppearance)
end

function hg.Appearance.LoadAppearanceFile()
    local tblAppearance = DecodeAppearanceRaw(GetLocalAppearanceRaw()) or hg.Appearance.ClientSavedAppearance
    if not istable(tblAppearance) then return false, "внешность не найдена в mdata" end
    if hg.Appearance.AppearanceValidater and not hg.Appearance.AppearanceValidater(tblAppearance) then
        return false, "внешность повреждена в mdata"
    end
    return table.Copy(tblAppearance)
end

function hg.Appearance.GetAppearanceList()
    return { tostring(hg.Appearance.SelectedAppearance:GetString() or "main") .. ".json" }
end

net.Receive("Get_Appearance", function()
    local forced_random = hg.Appearance.ForcedRandom:GetBool()

    net.Start("Get_Appearance")
        local tbl, reason
        if not forced_random then
            tbl, reason = hg.Appearance.LoadAppearanceFile(hg.Appearance.SelectedAppearance:GetString())
        end

        net.WriteTable(tbl and tbl or {})
        net.WriteBool(not tbl)
    net.SendToServer()

    if not tbl and not forced_random and IsValid(LocalPlayer()) then
        LocalPlayer():ChatPrint("[Внешность] не удалось загрузить из mdata: " .. tostring(reason))
    end
end)

local function OnlyGetAppearance()
    local forced_random = hg.Appearance.ForcedRandom:GetBool()

    net.Start("OnlyGet_Appearance")
        local tbl, reason
        if not forced_random then
            tbl, reason = hg.Appearance.LoadAppearanceFile(hg.Appearance.SelectedAppearance:GetString())
        end

        net.WriteTable(tbl or {})
    net.SendToServer()

    if not tbl and not forced_random and IsValid(LocalPlayer()) then
        LocalPlayer():ChatPrint("[Внешность] не удалось загрузить из mdata: " .. tostring(reason))
    end
end

net.Receive("OnlyGet_Appearance", OnlyGetAppearance)

net.Receive("hg_appearance_presets_sync", function()
    hg.Appearance.PresetsCache = net.ReadTable() or {}
end)

hook.Add("InitPostEntity", "hg.Appearance.RequestPresetsSync", function()
    net.Start("hg_appearance_presets_request")
    net.SendToServer()
end)

timer.Simple(2, function()
    if mdata and mdata.AddCallback then
        mdata.AddCallback("hg_appearance_selected", function(ply, val)
            if ply ~= LocalPlayer() then return end
            local tbl = DecodeAppearanceRaw(val)
            if istable(tbl) then
                SaveLocalAppearance(tbl)
            end
        end)

        mdata.AddCallback("hg_appearance_presets", function(ply, val)
            if ply ~= LocalPlayer() then return end
            local decoded = util.JSONToTable(tostring(val or "")) or {}
            if istable(decoded) then
                hg.Appearance.PresetsCache = decoded
            end
        end)
    end
end)

local whitelist = {
    weapon_physgun = true,
    gmod_tool = true,
    gmod_camera = true,
    weapon_crowbar = true,
    weapon_pistol = true,
    weapon_crossbow = true
}

local islply

function RenderAccessories(ply, accessories, setup)
    if not IsValid(ply) or not accessories then return end
    if accessories == "none" then return end

    local wep = ply:IsPlayer() and ply:GetActiveWeapon()

    local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
    ent = IsValid(ply.OldRagdoll) and ply.OldRagdoll:IsRagdoll() and ply.OldRagdoll or ent

    islply = ((ply:IsRagdoll() and hg.RagdollOwner(ply)) or ply) == (LocalPlayer():Alive() and LocalPlayer() or LocalPlayer():GetNWEntity("spect", LocalPlayer())) and GetViewEntity() == (LocalPlayer():Alive() and LocalPlayer() or LocalPlayer():GetNWEntity("spect", LocalPlayer()))

    if islply and IsValid(wep) and whitelist[wep:GetClass()] then
        if not ent.modelAccess then return end
        for k, v in ipairs(ent.modelAccess) do
            if IsValid(v) then
                v:Remove()
                v = nil
            end
        end
        return
    end

    if not ent.shouldTransmit or ent.NotSeen then
        if not ent.modelAccess then return end
        for k, v in ipairs(ent.modelAccess) do
            if IsValid(v) then
                v:Remove()
                v = nil
            end
        end
        return
    end

    if istable(accessories) then
        for k = 1, #accessories do
            local accessoriess = accessories[k]
            local accessData = hg.Accessories[accessoriess]
            if not accessData then continue end
            if accessData.needcoolRender then continue end

            DrawAccesories(ply, ent, accessoriess, accessData, islply, nil, setup)
        end
    else
        local accessData = hg.Accessories[accessories]
        if not accessData then return end
        if accessData.needcoolRender then return end

        DrawAccesories(ply, ent, accessories, accessData, islply, nil, setup)
    end
end

local huy_addvec = Vector(0.4, 0, 0.4)
function DrawAccesories(ply, ent, accessories, accessData, islply, force, setup)
    if not accessories then return end
    if not accessData then return end

    ply.modelAccess = ply.modelAccess or {}

    local fem = ThatPlyIsFemale(ent)
    if not IsValid(ply.modelAccess[accessories]) then
        if not accessData.model then return end
        ply.modelAccess[accessories] = ClientsideModel(fem and accessData.femmodel or accessData.model, RENDERGROUP_BOTH)

        local model = ply.modelAccess[accessories]
        model:SetNoDraw(true)
        model:SetModelScale(accessData[fem and "fempos" or "malepos"][3])
        model:SetSkin(isfunction(accessData.skin) and accessData.skin(ent) or accessData.skin)
        model:SetBodyGroups(accessData.bodygroups or "")
        model:SetParent(ent, ent:LookupBone(accessData.bone))
        if accessData.bonemerge then
            model:AddEffects(EF_BONEMERGE)
        end
        if accessData.bSetColor then
            if ply.GetPlayerColor then
                model:SetColor(ply:GetPlayerColor():ToColor())
            else
                model:SetColor(ply:GetNWVector("PlayerColor", Vector(1, 1, 1)):ToColor())
            end
        end

        if accessData.SubMat then
            model:SetSubMaterial(0, accessData.SubMat)
        end

        ply:CallOnRemove("RemoveAccessories" .. accessories, function()
            if ply.modelAccess and IsValid(model) then
                model:Remove()
                model = nil
            end
        end)

        ent:CallOnRemove("RemoveAccessories2" .. accessories, function()
            if ply.modelAccess and IsValid(model) then
                model:Remove()
                model = nil
            end
        end)
    end

    local model = ply.modelAccess[accessories]
    if not IsValid(model) then
        ply.modelAccess[accessories] = nil
        return
    end

    local mdl = string.Split(string.sub(ent:GetModel(), 1, -5), "/")[#string.Split(string.sub(ent:GetModel(), 1, -5), "/")]
    if mdl and model:GetFlexIDByName(mdl) then
        model:SetFlexWeight(model:GetFlexIDByName(mdl), 1)
    end
    model:SetSkin(isfunction(accessData.skin) and accessData.skin(ent) or accessData.skin)

    if ply.armors and accessData.placement and ply.armors[accessData.placement] then
        return
    end

    if not force and ((ent.NotSeen or not ent.shouldTransmit) or (ply:IsPlayer() and not ply:Alive())) then
        return
    end

    if setup ~= false then
        local bone = ent:LookupBone(accessData.bone)
        if not bone then return end
        if ent:GetManipulateBoneScale(bone):LengthSqr() < 0.1 then return end
        local matrix = ent:GetBoneMatrix(bone)
        if not matrix then return end

        local bonePos, boneAng = matrix:GetTranslation(), matrix:GetAngles()
        local addvec = ((ent:GetModel() == "models/player/group01/male_06.mdl") and ((accessData.placement == "head") or (accessData.placement == "face"))) and huy_addvec or vector_origin
        local pos, ang = LocalToWorld(accessData[fem and "fempos" or "malepos"][1], accessData[fem and "fempos" or "malepos"][2], bonePos, boneAng)
        pos = LocalToWorld(addvec, angle_zero, pos, ang)

        model:SetRenderOrigin(pos)
        model:SetRenderAngles(ang)
    end

    if model:GetParent() ~= ent then
        model:SetParent(ent, bone)
    end

    if not (islply and accessData.norender) and (not setup or accessData.bonemerge) then
        if accessData.bSetColor then
            local colorDraw = accessData.vecColorOveride or (ply.GetPlayerColor and ply:GetPlayerColor() or ply:GetNWVector("PlayerColor", Vector(1, 1, 1)))
            render.SetColorModulation(colorDraw[1], colorDraw[2], colorDraw[3])
        end

        model:DrawModel()

        if accessData.bSetColor then
            render.SetColorModulation(1, 1, 1)
        end
    end
end

local flpos, flang = Vector(4, -1, 0), Angle(0, 0, 0)
local offsetVec, offsetAng = Vector(1, 0, 0), Angle(100, 90, 0)
local mat2 = Material("sprites/light_glow02_add_noz")
local mat3 = Material("effects/flashlight/soft")

function DrawAppearance(ent, ply, setup)
    local Access = ent:GetNetVar("Accessories") or ent.PredictedAccessories

    if IsValid(ent) and Access then
        RenderAccessories(ply, Access, setup)
    end

    if setup then return end
    if not ply:IsPlayer() then return end

    local inv = ply:GetNetVar("Inventory", {})
    if not inv.Weapons or not inv.Weapons.hg_flashlight then
        if ply.flashlight then
            ply.flashlight:Remove()
            ply.flashlight = nil
        end
        if ply.flmodel then
            ply.flmodel:Remove()
            ply.flmodel = nil
        end
        return
    end

    local wep = ply:GetActiveWeapon()
    local flashlightwep

    if IsValid(wep) then
        local laser = wep.attachments and wep.attachments.underbarrel
        local attachmentData
        if (laser and not table.IsEmpty(laser)) or wep.laser then
            if laser and not table.IsEmpty(laser) then
                attachmentData = hg.attachments.underbarrel[laser[1]]
            else
                attachmentData = wep.laserData
            end
        end

        if attachmentData then
            flashlightwep = attachmentData.supportFlashlight
        end
    end

    if IsValid(ply.flmodel) then
        ply.flmodel:SetNoDraw(not (ply:GetNetVar("flashlight") and (not wep.IsPistolHoldType or wep:IsPistolHoldType())) or wep.reload or flashlightwep)
    end

    if ply:GetNetVar("flashlight") and not flashlightwep and (not wep.IsPistolHoldType or wep:IsPistolHoldType() or ply.PlayerClassName == "Gordon") and not wep.reload and hg.CanUseLeftHand(ply) then
        local hand = ent:LookupBone("ValveBiped.Bip01_L_Hand")
        if not hand then return end

        local handmat = ent:GetBoneMatrix(hand)
        if not handmat then return end

        local pos, ang = handmat:GetTranslation(), handmat:GetAngles()
        pos, ang = LocalToWorld(offsetVec, offsetAng, pos, ang)

        ply.flmodel = IsValid(ply.flmodel) and ply.flmodel or ClientsideModel("models/runaway911/props/item/flashlight.mdl")
        ply.flmodel:SetModelScale(0.75)

        if ent ~= ply then
            pos = handmat:GetTranslation()
        end

        pos = LocalToWorld(flpos, flang, pos, handmat:GetAngles())

        ply.flmodel:DrawModel()

        ply.flashlight = IsValid(ply.flashlight) and ply.flashlight or ProjectedTexture()
        if ply.flashlight and ply.flashlight:IsValid() and (ply.FlashlightUpdateTime or 0) < CurTime() then
            local flash = ply.flashlight
            ply.FlashlightUpdateTime = CurTime() + 0.01
            flash:SetTexture(mat3:GetTexture("$basetexture"))
            flash:SetFarZ(1500)
            flash:SetHorizontalFOV(60)
            flash:SetVerticalFOV(60)
            flash:SetConstantAttenuation(0.1)
            flash:SetLinearAttenuation(50)
            flash:SetPos(ply.flmodel:GetPos() + ply.flmodel:GetAngles():Forward() * (ply:GetVelocity():Length() / 10 + 15))
            flash:SetAngles(ply.flmodel:GetAngles())
            flash:Update()
        end

        local view = render.GetViewSetup(true)
        local deg = ply.flmodel:GetAngles():Forward():Dot(view.angles:Forward())
        deg = math.ease.InBack(-deg + 0.05) * 2
        deg = -deg
        local chekvisible = util.TraceLine({
            start = ply.flmodel:GetPos() + ply.flmodel:GetAngles():Forward() * 6,
            endpos = view.origin,
            filter = {ply, ent, ply.flmodel, LocalPlayer()},
            mask = MASK_VISIBLE
        })

        if deg < 0 and not chekvisible.Hit then
            render.SetMaterial(mat2)
            render.DrawSprite(ply.flmodel:GetPos() + ply.flmodel:GetAngles():Forward() * 5 + ply.flmodel:GetAngles():Right() * -0.5, 50 * math.min(deg, 0), 50 * math.min(deg, 0), color_white)
        end
    else
        if ply.flashlight and IsValid(ply.flashlight) then
            ply.flashlight:Remove()
            ply.flashlight = nil
        end
    end
end

hook.Add("RenderScreenspaceEffects", "AppearanceShitty", function()
    if (not LocalPlayer():Alive()) or LocalPlayer():GetViewEntity() ~= LocalPlayer() then return end
    local ply = LocalPlayer()
    local acsses = ply:GetNetVar("Accessories", "none")

    if istable(acsses) then
        for _, accessoriess in ipairs(acsses) do
            local accessData = hg.Accessories[accessoriess]
            if not accessData then continue end
            if ply.armors and accessData.placement and ply.armors[accessData.placement] then continue end
            if accessData.ScreenSpaceEffects then
                accessData.ScreenSpaceEffects()
            end
        end
    elseif acsses then
        local accessData = hg.Accessories[acsses]
        if not accessData then return end
        if ply.armors and accessData.placement and ply.armors[accessData.placement] then return end
        if accessData.ScreenSpaceEffects then
            accessData.ScreenSpaceEffects()
        end
    end
end)

function CoolRenderAccessories(ply, accessories)
    if not IsValid(ply) or not accessories then return end
    if accessories == "none" then return end

    local wep = ply:IsPlayer() and ply:GetActiveWeapon()
    local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply

    islply = ((ply:IsRagdoll() and hg.RagdollOwner(ply)) or ply) == (LocalPlayer():Alive() and LocalPlayer() or LocalPlayer():GetNWEntity("spect", LocalPlayer())) and GetViewEntity() == (LocalPlayer():Alive() and LocalPlayer() or LocalPlayer():GetNWEntity("spect", LocalPlayer()))

    if islply and IsValid(wep) and whitelist[wep:GetClass()] then
        if not ent.modelAccess then return end
        for k, v in ipairs(ent.modelAccess) do
            if IsValid(v) then
                v:Remove()
                v = nil
            end
        end
        return
    end

    if not ent.shouldTransmit or ent.NotSeen then
        if not ent.modelAccess then return end
        for k, v in ipairs(ent.modelAccess) do
            if IsValid(v) then
                v:Remove()
                v = nil
            end
        end
        return
    end

    if istable(accessories) then
        for k = 1, #accessories do
            local accessoriess = accessories[k]
            local accessData = hg.Accessories[accessoriess]
            if not accessData then continue end
            if not accessData.needcoolRender then continue end

            DrawAccesories(ply, ent, accessoriess, accessData, islply)
        end
    else
        local accessData = hg.Accessories[accessories]
        if not accessData then return end
        if not accessData.needcoolRender then return end

        DrawAccesories(ply, ent, accessories, accessData, islply)
    end
end

function RenderAccessoriesCool(ent, ply)
    if IsValid(ent) and ent:GetNetVar("Accessories") then
        CoolRenderAccessories(ent, ent:GetNetVar("Accessories", "none"))
    end
end