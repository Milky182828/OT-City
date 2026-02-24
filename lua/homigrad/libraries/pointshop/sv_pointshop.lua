hg.Pointshop = hg.Pointshop or {}

local POINTS_AMOUNT = 2
local POINTS_INTERVAL = 60
local ADMINS_GET_POINTS = true

local PLUGIN = hg.Pointshop
PLUGIN.PlayerInstances = PLUGIN.PlayerInstances or {}

-- =========================================================
-- ВАЖНО:
-- DonPoints (донат-поинты) теперь берём НЕ из hg_pointshop,
-- а из твоей системы баланса RK_Balance (таблица rk_donate_balance).
-- hg_pointshop хранит только: points + items
-- =========================================================

local function EnsureRKBalance()
    if not RK_Balance or not isfunction(RK_Balance.Load) or not isfunction(RK_Balance.Add) then
        error("[Z-City Shop] RK_Balance not found. Load RK donate balance system BEFORE pointshop.")
    end
end

local function PS_RefreshDonPoints(ply)
    if not IsValid(ply) then return end
    local sid64 = ply:SteamID64()
    if not PLUGIN.PlayerInstances[sid64] then
        PLUGIN.PlayerInstances[sid64] = { donpoints = 0, points = 0, items = {} }
    end

    -- берём из RK_Balance (который тянет из MySQL)
    PLUGIN.PlayerInstances[sid64].donpoints = math.max(0, tonumber(ply.RK_DonateBalance) or 0)
end

-- =========================================================
-- Таблица hg_pointshop: создаём БЕЗ donpoints (donpoints теперь в rk_donate_balance)
-- Если у тебя уже есть donpoints в таблице hg_pointshop - ничего страшного, мы просто не используем.
-- =========================================================
hook.Add("DatabaseConnected", "PointshopCreateData", function()
    EnsureRKBalance()

    local query = mysql:Create("hg_pointshop")
        query:Create("steamid", "VARCHAR(20) NOT NULL")
        query:Create("steam_name", "VARCHAR(32) NOT NULL")
        -- donpoints убираем из логики, но можно оставить в таблице если уже есть:
        -- query:Create("donpoints", "FLOAT NOT NULL")
        query:Create("points", "FLOAT NOT NULL")
        query:Create("items", "TEXT NOT NULL")
        query:PrimaryKey("steamid")
    query:Execute()

    PLUGIN.Active = true
    print("[Z-City Shop] База данных успешно загружена.")
end)

hook.Add("PlayerInitialSpawn", "Pointshop_OnInitSpawn", function(ply)
    EnsureRKBalance()

    local name = ply:Name()
    local steamID64 = ply:SteamID64()

    if not PLUGIN.Active then
        PLUGIN.PlayerInstances[steamID64] = {donpoints=0, points=0, items={}}
        return
    end

    local query = mysql:Select("hg_pointshop")
        query:Select("points")
        query:Select("items")
        query:Where("steamid", steamID64)
        query:Callback(function(result)
            if (IsValid(ply) and istable(result) and #result > 0 and result[1].points) then
                local updateQuery = mysql:Update("hg_pointshop")
                    updateQuery:Update("steam_name", name)
                    updateQuery:Where("steamid", steamID64)
                updateQuery:Execute()

                PLUGIN.PlayerInstances[steamID64] = {}
                PLUGIN.PlayerInstances[steamID64].points = tonumber(result[1].points) or 0
                PLUGIN.PlayerInstances[steamID64].items = util.JSONToTable(result[1].items or "[]") or {}

                -- грузим донат-баланс из RK_Balance
                RK_Balance.Load(ply)

                -- RK_Balance.Load асинхронный -> даём чуть времени и синкаем donpoints в vars
                timer.Simple(0.5, function()
                    if not IsValid(ply) then return end
                    PS_RefreshDonPoints(ply)
                    hook.Run("PS_PlayerLoaded", ply, steamID64)
                    PLUGIN:NET_SendPointShopVars(ply)
                end)
            else
                local insertQuery = mysql:Insert("hg_pointshop")
                    insertQuery:Insert("steamid", steamID64)
                    insertQuery:Insert("steam_name", name)
                    insertQuery:Insert("points", 0)
                    insertQuery:Insert("items", util.TableToJSON({}))
                insertQuery:Execute()

                PLUGIN.PlayerInstances[steamID64] = {donpoints=0, points=0, items={}}

                RK_Balance.Load(ply)

                timer.Simple(0.5, function()
                    if not IsValid(ply) then return end
                    PS_RefreshDonPoints(ply)
                    hook.Run("PS_PlayerLoaded", ply, steamID64)
                    PLUGIN:NET_SendPointShopVars(ply)
                end)
            end
        end)
    query:Execute()
end)

local plyMeta = FindMetaTable("Player")

function plyMeta:GetPointshopVars()
    local steamID64 = self:SteamID64()
    if not PLUGIN.PlayerInstances[steamID64] then
        PLUGIN.PlayerInstances[steamID64] = {donpoints=0, points=0, items={}}
    end

    -- всегда подтягиваем актуальный донат-баланс из RK_Balance
    PLUGIN.PlayerInstances[steamID64].donpoints = math.max(0, tonumber(self.RK_DonateBalance) or 0)

    return PLUGIN.PlayerInstances[steamID64]
end

-- =========================
-- Обычные points (как было)
-- =========================
function plyMeta:PS_AddPoints(ammout)
    local pointshopVars = self:GetPointshopVars()
    ammout = tonumber(ammout) or 0
    if ammout < 1 then return false end
    self:PS_SetPoints(pointshopVars.points + ammout)
    return true, ammout .. " points added"
end

function plyMeta:PS_SetPoints(value)
    if not util.IsBinaryModuleInstalled("mysqloo") and not mysql then return end
    value = tonumber(value) or 0

    local steamID64 = self:SteamID64()
    local pointshopVars = self:GetPointshopVars()

    local updateQuery = mysql:Update("hg_pointshop")
        updateQuery:Update("points", value)
        updateQuery:Where("steamid", steamID64)
    updateQuery:Execute()

    pointshopVars.points = value
end

function plyMeta:PS_TakePoints(ammout, callback)
    local pointshopVars = self:GetPointshopVars()
    ammout = tonumber(ammout) or 0
    if ammout > pointshopVars.points then return false, "Вам не хватает." end
    self:PS_SetPoints(pointshopVars.points - ammout)
    if callback then callback(self) end
    return true
end

-- =========================================================
-- Донат поинты: теперь через RK_Balance (rk_donate_balance.balance)
-- =========================================================
function plyMeta:PS_AddDPoints(ammout)
    ammout = tonumber(ammout) or 0
    if ammout < 1 then return false end
    -- + к балансу
    RK_Balance.Add(self, ammout)
    -- обновим кэш vars
    PS_RefreshDonPoints(self)
    return true
end

function plyMeta:PS_SetDPoints(value)
    value = tonumber(value) or 0
    local cur = math.max(0, tonumber(self.RK_DonateBalance) or 0)

    local delta = value - cur
    if delta == 0 then
        PS_RefreshDonPoints(self)
        return
    end

    RK_Balance.Add(self, delta)
    PS_RefreshDonPoints(self)
end

function plyMeta:PS_TakeDPoints(ammout, callback)
    local cur = math.max(0, tonumber(self.RK_DonateBalance) or 0)
    ammout = tonumber(ammout) or 0

    if ammout > cur then return false, "Вам не хватает." end

    RK_Balance.Add(self, -ammout)
    PS_RefreshDonPoints(self)

    if callback then callback(self) end
    return true, ""
end

-- =========================
-- Items (как было)
-- =========================
function plyMeta:PS_SetItems(tItems)
    local steamID64 = self:SteamID64()
    local pointshopVars = self:GetPointshopVars()

    local updateQuery = mysql:Update("hg_pointshop")
        updateQuery:Update("items", util.TableToJSON(tItems))
        updateQuery:Where("steamid", steamID64)
    updateQuery:Execute()

    pointshopVars.items = tItems
end

function plyMeta:PS_AddItem(uid)
    if not hg.PointShop.Items[uid] then return end
    local pointshopVars = self:GetPointshopVars()
    pointshopVars.items[uid] = true
    self:PS_SetItems(pointshopVars.items)
end

function plyMeta:PS_HasItem(uid)
    local pointshopVars = self:GetPointshopVars()
    if not pointshopVars then return false end
    return pointshopVars.items[uid] or false
end

-- =========================
-- NET
-- =========================
util.AddNetworkString("hg_pointshop_net")

function PLUGIN:NET_SendPointShopVars(ply)
    -- перед отправкой подтягиваем донат-баланс из RK_Balance
    PS_RefreshDonPoints(ply)

    net.Start("hg_pointshop_net")
        net.WriteTable(ply:GetPointshopVars())
    net.Send(ply)
end

util.AddNetworkString("hg_pointshop_send_notificate")

function PLUGIN:NET_BuyItem(ply, uid)
    if not util.IsBinaryModuleInstalled("mysqloo") and not mysql then return end
    if not hg.PointShop.Items[uid] then return end

    if ply:PS_HasItem(uid) then
        PLUGIN:NET_SendPointShopVars(ply)
        return
    end

    local yes = false
    local reason = ""

    if hg.PointShop.Items[uid].ISDONATE then
        yes, reason = ply:PS_TakeDPoints(hg.PointShop.Items[uid].PRICE, function() ply:PS_AddItem(uid) end)
    else
        yes, reason = ply:PS_TakePoints(hg.PointShop.Items[uid].PRICE, function() ply:PS_AddItem(uid) end)
    end

    net.Start("hg_pointshop_send_notificate")
        net.WriteString(reason or "")
    net.Send(ply)

    PLUGIN:NET_SendPointShopVars(ply)
end

function PLUGIN:NET_GetBuyedItems(ply)
    PLUGIN:NET_SendPointShopVars(ply)
end

net.Receive("hg_pointshop_net", function(_, ply)
    if ply.PSNetCD and ply.PSNetCD > CurTime() then return end
    ply.PSNetCD = CurTime() + 0.01

    local str = net.ReadString()
    local funcstring = PLUGIN["NET_" .. str]
    if not funcstring then return end

    local vars = net.ReadTable()
    if table.Count(vars) > 5 then return end

    funcstring(PLUGIN, ply, unpack(vars))
end)

hook.Add("HG_PlayerSay", "OpenPointShop", function(ply, txtTbl, txt)
    if txt == "!pointshop" then
        ply:ConCommand("hg_pointshop")
    end
end)

timer.Create("ZCity_PointsTimer", POINTS_INTERVAL, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsFullyAuthenticated() then
            if not ADMINS_GET_POINTS and (ply:IsSuperAdmin() or ply:IsAdmin()) then
                continue
            end
            ply:PS_AddPoints(POINTS_AMOUNT)
            PLUGIN:NET_SendPointShopVars(ply)
        end
    end
end)

-- =========================
-- Tebex команды (как было)
-- Теперь premium добавляет В rk_donate_balance через RK_Balance
-- =========================
local function FindPlayerFinal(input)
    if not input then return nil end
    input = string.Replace(input, '"', "")
    input = string.Trim(input)

    for _, v in ipairs(player.GetAll()) do
        if v:SteamID() == input then return v end
        if v:SteamID64() == input then return v end
        if v:Nick() == input then return v end
    end
    return nil
end

concommand.Add("zcity_tebex_add", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local target = FindPlayerFinal(args[1])
    local amount = tonumber(args[2])

    if target and amount then
        target:PS_AddPoints(amount)
        PLUGIN:NET_SendPointShopVars(target)
        print("[TEBEX] SUKCES: Dodano " .. amount .. " ZP dla " .. target:Nick())
        if IsValid(target) then target:ChatPrint("[Магазин] Спасибо! Вы получили его. " .. amount .. " ZP!") end
    else
        print("[TEBEX] ERROR: Игрок не найден или неверный номер.")
    end
end)

concommand.Add("zcity_tebex_add_premium", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local target = FindPlayerFinal(args[1])
    local amount = tonumber(args[2])

    if target and amount then
        target:PS_AddDPoints(amount) -- теперь через RK_Balance -> rk_donate_balance
        PLUGIN:NET_SendPointShopVars(target)
        print("[TEBEX] SUKCES: Dodano " .. amount .. " DZP dla " .. target:Nick())
        if IsValid(target) then target:ChatPrint("[SKLEP PREMIUM] Спасибо! Вы получили его. " .. amount .. " DZP!") end
    else
        print("[TEBEX] ERROR: Игрок не найден или неверный номер.")
    end
end)