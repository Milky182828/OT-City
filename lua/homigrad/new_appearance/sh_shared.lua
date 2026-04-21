hg.Appearance = hg.Appearance or {}
hg.PointShop = hg.PointShop or {}
local PLUGIN = hg.PointShop
PLUGIN.Items = PLUGIN.Items or {}

local allowed = {
    " ",
    "а", "б", "в", "г", "д", "е", "ё", "ж", "з", "и", "й", "к", "л", "м", "н", "о", "п", "р", "с", "т", "у", "ф", "х", "ц", "ч", "ш", "щ", "ъ", "ы", "ь", "э", "ю", "я",
    "А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й", "К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я",
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
}

local function IsInvalidName(name)
    local trimmedName = string.Trim(name)
    if trimmedName == "" then return true end
    if #trimmedName < 2 then return true end
    if utf8.len(name) > 25 then return true end

    local symbols = utf8.len(name)
    for k = 1, symbols do
        if not table.HasValue(allowed, utf8.GetChar(name, k)) then
            return true
        end
    end

    local ret = hook.Run("ZB_IsInvalidName", name)
    if ret ~= nil then return ret end
    return false
end
hg.Appearance.IsInvalidName = IsInvalidName

local function GenerateRandomName(iSex)
    local sex = iSex or math.random(1, 2)
    local randomName = hg.Appearance.RandomNames[sex][math.random(1, #hg.Appearance.RandomNames[sex])]
    return randomName
end
hg.Appearance.GenerateRandomName = GenerateRandomName

local access = {}

local hg_appearance_access_for_all = ConVarExists("hg_appearance_access_for_all") and GetConVar("hg_appearance_access_for_all") or CreateConVar("hg_appearance_access_for_all", 1, {FCVAR_REPLICATED, FCVAR_NEVER_AS_STRING, FCVAR_ARCHIVE}, "Включить бесплатный доступ ко всем предметам внешности", 0, 1)

if SERVER then
    cvars.AddChangeCallback("hg_appearance_access_for_all", function()
        SetGlobalBool("hg_appearance_access_for_all", hg_appearance_access_for_all:GetBool())
    end)

    SetGlobalBool("hg_appearance_access_for_all", hg_appearance_access_for_all:GetBool())
end

local function GetAccessToAll(ply)
    return GetGlobalBool("hg_appearance_access_for_all") or ply:IsSuperAdmin() or ply:IsAdmin() or access[ply:SteamID()]
end
hg.Appearance.GetAccessToAll = GetAccessToAll

local PlayerModels = {
    [1] = {},
    [2] = {}
}

local function AppAddModel(strName, strMdl, bFemale, tSubmaterialSlots)
    PlayerModels[bFemale and 2 or 1][strName] = {
        mdl = strMdl,
        submatSlots = tSubmaterialSlots,
        sex = bFemale
    }
end

AppAddModel("Мужчина 01", "models/zcityadodser/m/male_01.mdl", false, {
    main = "models/humans/male/group01/players_sheet",
    pants = "distac/gloves/pants",
    boots = "distac/gloves/cross",
    hands = "distac/gloves/hands"
})
AppAddModel("Мужчина 02", "models/zcityadodser/m/male_02.mdl", false, {
    main = "models/humans/male/group01/players_sheet",
    pants = "distac/gloves/pants",
    boots = "distac/gloves/cross",
    hands = "distac/gloves/hands"
})
AppAddModel("Мужчина 03", "models/zcityadodser/m/male_03.mdl", false, {
    main = "models/humans/male/group01/players_sheet",
    pants = "distac/gloves/pants",
    boots = "distac/gloves/cross",
    hands = "distac/gloves/hands"
})
AppAddModel("Мужчина 04", "models/zcityadodser/m/male_04.mdl", false, {
    main = "models/humans/male/group01/players_sheet",
    pants = "distac/gloves/pants",
    boots = "distac/gloves/cross",
    hands = "distac/gloves/hands"
})
AppAddModel("Мужчина 05", "models/zcityadodser/m/male_05.mdl", false, {
    main = "models/humans/male/group01/players_sheet",
    pants = "distac/gloves/pants",
    boots = "distac/gloves/cross",
    hands = "distac/gloves/hands"
})
AppAddModel("Мужчина 06", "models/zcityadodser/m/male_06.mdl", false, {
    main = "models/humans/male/group01/players_sheet",
    pants = "distac/gloves/pants",
    boots = "distac/gloves/cross",
    hands = "distac/gloves/hands"
})
AppAddModel("Мужчина 07", "models/zcityadodser/m/male_07.mdl", false, {
    main = "models/humans/male/group01/players_sheet",
    pants = "distac/gloves/pants",
    boots = "distac/gloves/cross",
    hands = "distac/gloves/hands"
})
AppAddModel("Мужчина 08", "models/zcityadodser/m/male_08.mdl", false, {
    main = "models/humans/male/group01/players_sheet",
    pants = "distac/gloves/pants",
    boots = "distac/gloves/cross",
    hands = "distac/gloves/hands"
})
AppAddModel("Мужчина 09", "models/zcityadodser/m/male_09.mdl", false, {
    main = "models/humans/male/group01/players_sheet",
    pants = "distac/gloves/pants",
    boots = "distac/gloves/cross",
    hands = "distac/gloves/hands"
})

AppAddModel("Женщина 01", "models/zcityadodser/f/female_01.mdl", true, {
    main = "models/humans/female/group01/players_sheet",
    pants = "distac/gloves/pants",
    boots = "distac/gloves/cross",
    hands = "distac/gloves/hands"
})
AppAddModel("Женщина 02", "models/zcityadodser/f/female_02.mdl", true, {
    main = "models/humans/female/group01/players_sheet",
    pants = "distac/gloves/pants",
    boots = "distac/gloves/cross",
    hands = "distac/gloves/hands"
})
AppAddModel("Женщина 03", "models/zcityadodser/f/female_03.mdl", true, {
    main = "models/humans/female/group01/players_sheet",
    pants = "distac/gloves/pants",
    boots = "distac/gloves/cross",
    hands = "distac/gloves/hands"
})
AppAddModel("Женщина 04", "models/zcityadodser/f/female_04.mdl", true, {
    main = "models/humans/female/group01/players_sheet",
    pants = "distac/gloves/pants",
    boots = "distac/gloves/cross",
    hands = "distac/gloves/hands"
})
AppAddModel("Женщина 05", "models/zcityadodser/f/female_07.mdl", true, {
    main = "models/humans/female/group01/players_sheet",
    pants = "distac/gloves/pants",
    boots = "distac/gloves/cross",
    hands = "distac/gloves/hands"
})
AppAddModel("Женщина 06", "models/zcityadodser/f/female_06.mdl", true, {
    main = "models/humans/female/group01/players_sheet",
    pants = "distac/gloves/pants",
    boots = "distac/gloves/cross",
    hands = "distac/gloves/hands"
})

hg.Appearance.PlayerModels = PlayerModels

hg.Appearance.FuckYouModels = {{}, {}}
for _, tbl in pairs(hg.Appearance.PlayerModels[1]) do
    hg.Appearance.FuckYouModels[1][tbl.mdl] = tbl
end
for _, tbl in pairs(hg.Appearance.PlayerModels[2]) do
    hg.Appearance.FuckYouModels[2][tbl.mdl] = tbl
end

hg.Appearance.Clothes = {}
hg.Appearance.Clothes[1] = {
    normal = "models/humans/male/group01/normal",
    formal = "models/humans/male/group01/formal",
    plaid = "models/humans/male/group01/plaid",
    striped = "models/humans/male/group01/striped",
    young = "models/humans/male/group01/young",
    cold = "models/humans/male/group01/cold",
    casual = "models/humans/male/group01/casual",
    sweater_xmas = "models/humans/male/group01/sweater",
    worker = "models/humans/male/group01/worker",
    bomber_jacket1 = "models/humans/male/group01/bomberjacket1",
    camo_variant2 = "models/humans/male/group01/camo2",
    pilot_jacket = "models/humans/male/group01/pilotjacket",
    tactical_outfit = "models/humans/male/group01/tacticalgop",
    hussar_jacket = "models/humans/male/group01/hussar",
    Tshirt3 = "models/humans/male/group01/bersk",
    leather_jacket = "models/humans/male/group01/jacket",
    Tshirt1 = "models/humans/male/group01/promised",
    Tshirt2 = "models/humans/male/group01/simon",
    alpha_bomber = "models/humans/male/group01/alphaindustry",
    alpha_hoodie = "models/humans/male/group01/alphahoodie",
    lonsdale_hoodie = "models/humans/male/group01/LondsdaleHoodie",
    golden_adidas = "models/humans/male/group01/goldenadidas",
    wagner_group = "models/humans/male/group01/wagner",
    russian_army = "models/humans/male/group01/russianarmy",
    Hello_Kitty = "models/humans/male/group01/hello_kitty",
    Office_Worker = "models/humans/male/group01/OfficeWorker",
    Security_Officer = "models/humans/male/group01/Security_Officer",
    Zcity_Hoodie = "models/humans/male/group01/zcityhoodie",
    Flecktarn = "models/humans/male/group01/flecktarn",
    Hawaiian_Shirt = "models/humans/male/group01/tommy",
    Hawaiian_Shirt2 = "models/humans/male/group01/Hawaiian1",
    Sadsalat = "models/humans/male/group01/sadsalat",
    Army_Shirt = "models/humans/male/group01/armyshirt",
    Lambda = "models/humans/male/group01/lambda",
    bean = "models/humans/male/group01/bean",
    y2k = "models/humans/male/group01/y2k",
    medic1 = "models/humans/male/group01/medic1",
    antisocial = "models/humans/male/group01/antisocial",
    peacefulhooligan = "models/humans/male/group01/peacefulhooligan"
}
hg.Appearance.Clothes[2] = {
    normal = "models/humans/female/group01/normal",
    formal = "models/humans/female/group01/formal",
    plaid = "models/humans/female/group01/plaid",
    striped = "models/humans/female/group01/striped",
    young = "models/humans/female/group01/young",
    cold = "models/humans/female/group01/cold",
    casual = "models/humans/female/group01/casual",
    sweater_xmas = "models/humans/female/group01/sweater",
    adidas_tracksuit = "models/humans/female/group01/adidas",
    Tshirt1 = "models/humans/female/group01/flowers",
    Tshirt2 = "models/humans/female/group01/skullshirt",
    Tshirt3 = "models/humans/female/group01/skeletal",
    Tshirt4 = "models/humans/female/group01/redskull",
    Hawaiian_Shirt1 = "models/humans/female/group01/Hawaiian1",
    swiss = "models/humans/female/group01/swiss"
}

hg.Appearance.ClothesDesc = {
    normal = { desc = "Стандартная одежда гражданина Garry's Mod" },
    formal = { desc = "Из оригинального режима Jack's Homicide.\nНавсегда." },
    plaid = { desc = "Из оригинального режима Jack's Homicide.\nНавсегда." },
    striped = { desc = "Из оригинального режима Jack's Homicide.\nНавсегда." },
    young = { desc = "Из оригинального режима Jack's Homicide.\nНавсегда." },
    cold = { desc = "Из оригинального режима Jack's Homicide.\nНавсегда." },
    casual = { desc = "Из оригинального режима Jack's Homicide.\nНавсегда." },
    sweater_xmas = {
        desc = "Автор Wontairr из мастерской Steam\nПКМ, чтобы открыть ссылку",
        link = "https://steamcommunity.com/sharedfiles/filedetails/?id=3621630161"
    },
    worker = {
        desc = "Автор Chervo93 из мастерской Steam\nПКМ, чтобы открыть ссылку",
        link = "https://steamcommunity.com/sharedfiles/filedetails/?id=3540506879"
    },
    Sadsalat = {
        desc = "Да, именно sadsalat. Так задумано."
    }
}

hg.Appearance.FacemapsSlots = hg.Appearance.FacemapsSlots or {}
hg.Appearance.FacemapsModels = hg.Appearance.FacemapsModels or {}

local function AddFacemap(matOverride, strName, matMaterial, model)
    hg.Appearance.FacemapsSlots[matOverride] = hg.Appearance.FacemapsSlots[matOverride] or {}
    local tbl = hg.Appearance.FacemapsSlots[matOverride]
    tbl[strName] = matMaterial
    if model then
        hg.Appearance.FacemapsModels[model] = matOverride
    end
end

local female01facemap = "models/humans/female/group01/joey_facemap"
AddFacemap(female01facemap, "По умолчанию", "", "models/zcityadodser/f/female_01.mdl")
AddFacemap(female01facemap, "Лицо 1", "models/bloo_ltcom_zel/citizens/facemaps/joey_facemap")
for i = 2, 6 do
    AddFacemap(female01facemap, "Лицо " .. i, "models/bloo_ltcom_zel/citizens/facemaps/joey_facemap" .. i)
end

local female02facemap = "models/humans/female/group01/kanisha_cylmap"
AddFacemap(female02facemap, "По умолчанию", "", "models/zcityadodser/f/female_02.mdl")
AddFacemap(female02facemap, "Лицо 1", "models/bloo_ltcom_zel/citizens/facemaps/kanisha_cylmap")
for i = 2, 6 do
    AddFacemap(female02facemap, "Лицо " .. i, "models/bloo_ltcom_zel/citizens/facemaps/kanisha_cylmap" .. i)
end

local female03facemap = "models/humans/female/group01/kim_facemap"
AddFacemap(female03facemap, "По умолчанию", "", "models/zcityadodser/f/female_03.mdl")
AddFacemap(female03facemap, "Лицо 1", "models/bloo_ltcom_zel/citizens/facemaps/kim_facemap")
AddFacemap(female03facemap, "Лицо 5", "models/bloo_ltcom_zel/citizens/facemaps/kim_facemap6")
for i = 2, 4 do
    AddFacemap(female03facemap, "Лицо " .. i, "models/bloo_ltcom_zel/citizens/facemaps/kim_facemap" .. i)
end

local female04facemap = "models/humans/female/group01/chau_facemap"
AddFacemap(female04facemap, "По умолчанию", "", "models/zcityadodser/f/female_04.mdl")
AddFacemap(female04facemap, "Лицо 1", "models/bloo_ltcom_zel/citizens/facemaps/chau_facemap")
for i = 2, 6 do
    AddFacemap(female04facemap, "Лицо " .. i, "models/bloo_ltcom_zel/citizens/facemaps/chau_facemap" .. i)
end

local female05facemap = "models/humans/female/group01/miranda_facemap"
AddFacemap(female05facemap, "По умолчанию", "", "models/zcityadodser/f/female_07.mdl")
AddFacemap(female05facemap, "Лицо 1", "models/bloo_ltcom_zel/citizens/facemaps/miranda_facemap")
for i = 2, 6 do
    AddFacemap(female05facemap, "Лицо " .. i, "models/bloo_ltcom_zel/citizens/facemaps/miranda_facemap" .. i)
end

local female06facemap = "models/humans/female/group01/lake_facemap"
AddFacemap(female06facemap, "По умолчанию", "", "models/zcityadodser/f/female_06.mdl")
AddFacemap(female06facemap, "Лицо 1", "models/bloo_ltcom_zel/citizens/facemaps/lake_facemap")
for i = 2, 6 do
    AddFacemap(female06facemap, "Лицо " .. i, "models/bloo_ltcom_zel/citizens/facemaps/lake_facemap" .. i)
end

local male01facemap = "models/humans/male/group01/eric_facemap"
AddFacemap(male01facemap, "По умолчанию", "", "models/zcityadodser/m/male_01.mdl")
AddFacemap(male01facemap, "Лицо 1", "models/bloo_ltcom_zel/citizens/facemaps/eric_facemap")
for i = 2, 9 do
    AddFacemap(male01facemap, "Лицо " .. i, "models/bloo_ltcom_zel/citizens/facemaps/eric_facemap" .. i)
end

local male02facemap = "models/humans/male/group01/ted_facemap"
AddFacemap(male02facemap, "По умолчанию", "", "models/zcityadodser/m/male_02.mdl")
AddFacemap(male02facemap, "Лицо 1", "models/bloo_ltcom_zel/citizens/facemaps/ted_facemap")
for i = 2, 9 do
    AddFacemap(male02facemap, "Лицо " .. i, "models/bloo_ltcom_zel/citizens/facemaps/ted_facemap" .. i)
end

local male03facemap = "models/humans/male/group01/joe_facemap"
AddFacemap(male03facemap, "По умолчанию", "", "models/zcityadodser/m/male_03.mdl")
AddFacemap(male03facemap, "Лицо 1", "models/bloo_ltcom_zel/citizens/facemaps/joe_facemap")
for i = 2, 9 do
    AddFacemap(male03facemap, "Лицо " .. i, "models/bloo_ltcom_zel/citizens/facemaps/joe_facemap" .. i)
end

local male04facemap = "models/humans/male/group01/art_facemap"
AddFacemap(male04facemap, "По умолчанию", "", "models/zcityadodser/m/male_04.mdl")
AddFacemap(male04facemap, "Лицо 1", "models/bloo_ltcom_zel/citizens/facemaps/art_facemap")
for i = 2, 9 do
    AddFacemap(male04facemap, "Лицо " .. i, "models/bloo_ltcom_zel/citizens/facemaps/art_facemap" .. i)
end

local male05facemap = "models/humans/male/group01/ross_facemap"
AddFacemap(male05facemap, "По умолчанию", "", "models/zcityadodser/m/male_05.mdl")
AddFacemap(male05facemap, "Лицо 1", "models/bloo_ltcom_zel/citizens/facemaps/ross_facemap")
for i = 2, 9 do
    AddFacemap(male05facemap, "Лицо " .. i, "models/bloo_ltcom_zel/citizens/facemaps/ross_facemap" .. i)
end

local male06facemap = "models/humans/male/group01/sandro_facemap"
AddFacemap(male06facemap, "По умолчанию", "", "models/zcityadodser/m/male_06.mdl")
AddFacemap(male06facemap, "Лицо 1", "models/bloo_ltcom_zel/citizens/facemaps/sandro_facemap")
for i = 2, 10 do
    AddFacemap(male06facemap, "Лицо " .. i, "models/bloo_ltcom_zel/citizens/facemaps/sandro_facemap" .. i)
end

local male07facemap = "models/humans/male/group01/mike_facemap"
AddFacemap(male07facemap, "По умолчанию", "", "models/zcityadodser/m/male_07.mdl")
AddFacemap(male07facemap, "Лицо 1", "models/bloo_ltcom_zel/citizens/facemaps/mike_facemap")
for i = 2, 8 do
    AddFacemap(male07facemap, "Лицо " .. i, "models/bloo_ltcom_zel/citizens/facemaps/mike_facemap" .. i)
end

local male08facemap = "models/humans/male/group01/vance_facemap"
AddFacemap(male08facemap, "По умолчанию", "", "models/zcityadodser/m/male_08.mdl")
AddFacemap(male08facemap, "Лицо 1", "models/bloo_ltcom_zel/citizens/facemaps/vance_facemap")
for i = 2, 9 do
    AddFacemap(male08facemap, "Лицо " .. i, "models/bloo_ltcom_zel/citizens/facemaps/vance_facemap" .. i)
end

local male09facemap = "models/humans/male/group01/erdim_cylmap"
AddFacemap(male09facemap, "По умолчанию", "", "models/zcityadodser/m/male_09.mdl")
AddFacemap(male09facemap, "Лицо 1", "models/bloo_ltcom_zel/citizens/facemaps/erdim_facemap")
for i = 2, 11 do
    AddFacemap(male09facemap, "Лицо " .. i, "models/bloo_ltcom_zel/citizens/facemaps/erdim_facemap" .. i)
end

hg.Appearance.Bodygroups = hg.Appearance.Bodygroups or {
    TORSO = { [1] = {}, [2] = {} },
    LEGS = { [1] = {}, [2] = {} },
    HANDS = {
        [1] = { ["Без перчаток"] = {"hands", false} },
        [2] = { ["Без перчаток"] = {"hands", false} }
    },
    gloves2 = { [1] = {}, [2] = {} }
}

local function AppAddBodygroup(strBodyGroup, strName, strStringID, bFemale, bPointShop, bDonateOnly, fCost, psModel, psBodygroups, psSubmats, psStrNameOveride)
    local pointShopID = "Standard_BodyGroups_" .. (psStrNameOveride or strName)
    hg.Appearance.Bodygroups[strBodyGroup] = hg.Appearance.Bodygroups[strBodyGroup] or {}
    hg.Appearance.Bodygroups[strBodyGroup][bFemale and 2 or 1] = hg.Appearance.Bodygroups[strBodyGroup][bFemale and 2 or 1] or {}
    hg.Appearance.Bodygroups[strBodyGroup][bFemale and 2 or 1][strName] = {
        strStringID,
        bPointShop,
        ID = pointShopID
    }
    PLUGIN:CreateItem(pointShopID, string.NiceName(strName), psModel or "models/zcity/gloves/degloves.mdl", psBodygroups, 0, Vector(0, 0, 0), fCost, bDonateOnly, psSubmats or {})
end

local function AddBodygroupsFunc()
    AppAddBodygroup("HANDS", "Перчатки", "reggloves_FIN_M", false, true, true, 300, "models/zcity/gloves/degloves.mdl", 0)
    AppAddBodygroup("HANDS", "Перчатки", "reggloves_FIN_F", true, true, true, 300, "models/zcity/gloves/degloves.mdl", 0)
    AppAddBodygroup("HANDS", "Перчатки без пальцев", "reggloves_outFIN_M", false, true, true, 300, "models/zcity/gloves/degloves.mdl", 1)
    AppAddBodygroup("HANDS", "Перчатки без пальцев", "reggloves_outFIN_F", true, true, true, 300, "models/zcity/gloves/degloves.mdl", 1)
    AppAddBodygroup("HANDS", "Скелет", "sceletgloves_FIN_M", false, true, true, 399, "models/zcity/gloves/degloves.mdl", 0, { [0] = "distac/gloves/sceletgloves" })
    AppAddBodygroup("HANDS", "Скелет", "sceletgloves_FIN_F", true, true, true, 399, "models/zcity/gloves/degloves.mdl", 0, { [0] = "distac/gloves/sceletgloves" })
    AppAddBodygroup("HANDS", "Скелет без пальцев", "sceletgloves_outFIN_M", false, true, true, 399, "models/zcity/gloves/degloves.mdl", 1, { [0] = "distac/gloves/sceletgloves" })
    AppAddBodygroup("HANDS", "Скелет без пальцев", "sceletgloves_outFIN_F", true, true, true, 399, "models/zcity/gloves/degloves.mdl", 1, { [0] = "distac/gloves/sceletgloves" })
    AppAddBodygroup("HANDS", "Зимние", "wingloves_FIN_M", false, true, true, 300, "models/zcity/gloves/degloves.mdl", 2, nil, "Байкерские")
    AppAddBodygroup("HANDS", "Зимние", "wingloves_FIN_F", true, true, true, 300, "models/zcity/gloves/degloves.mdl", 2, nil, "Байкерские")
    AppAddBodygroup("HANDS", "Зимние без пальцев", "wingloves_outFIN_M", false, true, true, 300, "models/zcity/gloves/degloves.mdl", 3, nil, "Байкерские без пальцев")
    AppAddBodygroup("HANDS", "Зимние без пальцев", "wingloves_outFIN_F", true, true, true, 300, "models/zcity/gloves/degloves.mdl", 3, nil, "Байкерские без пальцев")
    AppAddBodygroup("HANDS", "Байкерские перчатки", "biker_gloves_M", false, true, true, 300, "models/zcity/gloves/degloves.mdl", 5)
    AppAddBodygroup("HANDS", "Байкерские перчатки", "biker_gloves_F", true, true, true, 300, "models/zcity/gloves/degloves.mdl", 5)
    AppAddBodygroup("HANDS", "Байкерская шерсть", "bikerwool_gloves_M", false, true, true, 399, "models/zcity/gloves/degloves.mdl", 6, nil)
    AppAddBodygroup("HANDS", "Байкерская шерсть", "bikerwool_gloves_F", true, true, true, 399, "models/zcity/gloves/degloves.mdl", 6, nil)
    AppAddBodygroup("HANDS", "Шерстяные без пальцев", "wool_glove_M", false, true, true, 300, "models/zcity/gloves/degloves.mdl", 7, nil)
    AppAddBodygroup("HANDS", "Шерстяные без пальцев", "wool_gloves_F", true, true, true, 300, "models/zcity/gloves/degloves.mdl", 7, nil)
    AppAddBodygroup("HANDS", "Шерстяные варежки", "mittenwool_M", false, true, true, 300, "models/zcity/gloves/degloves.mdl", 8, nil)
    AppAddBodygroup("HANDS", "Шерстяные варежки", "mittenwool_F", true, true, true, 300, "models/zcity/gloves/degloves.mdl", 8, nil)

    AppAddBodygroup("TORSO", "Стандартный верх", "male_standart_top.smd", false, false, false, 0, nil, 0)
    AppAddBodygroup("TORSO", "Широкий верх", "male_standart_top_wide.smd", false, false, false, 0, nil, 0)
    AppAddBodygroup("TORSO", "Очень широкий верх", "male_standart_top_wide_more.smd", false, false, false, 0, nil, 0)
    AppAddBodygroup("TORSO", "Футболка", "male_standart_tshirt.smd", false, false, false, 0, nil, 0)
    AppAddBodygroup("TORSO", "Закрытый воротник", "male_standart_closed_collar.smd", false, false, false, 0, nil, 0)
    AppAddBodygroup("HANDS", "Руки для футболки", "handsfortshirt", false, false, false, 0, nil, 0)
    AppAddBodygroup("HANDS", "Роботизированная рука", "robotichands", false, false, false, 0, nil, 0)
    AppAddBodygroup("HANDS", "Медицинские перчатки", "medical_gloves", false, false, false, 0, nil, 0)
    AppAddBodygroup("TORSO", "Куртка Одессы", "male_odessa_jacket.smd", false, false, false, 0, nil, 0)
    AppAddBodygroup("TORSO", "Роботизированная рука", "male_robotic_arm.smd", false, false, false, 0, nil, 0)

    AppAddBodygroup("LEGS", "Стандартный низ", "male_reference_bottom.smd", false, false, false, 0, nil, 0)
    AppAddBodygroup("LEGS", "Широкий низ", "male_reference_wide_bottom.smd", false, false, false, 0, nil, 0)
    AppAddBodygroup("LEGS", "Ботинки", "male_reference_boots.smd", false, false, false, 0, nil, 0)
    AppAddBodygroup("LEGS", "Шорты", "male_reference_bottom_shorts.smd", false, false, false, 0, nil, 0)
    AppAddBodygroup("LEGS", "Ботинки пошире", "male_reference_boots_wider.smd", false, false, false, 0, nil, 0)

    AppAddBodygroup("TORSO", "Стандартный верх", "female_standart_top.smd", true, false, false, 0, nil, 0)
    AppAddBodygroup("TORSO", "Широкий верх", "female_standart_top_wide.smd", true, false, false, 0, nil, 0)
    AppAddBodygroup("TORSO", "Очень широкий верх", "female_standart_top_wide_more.smd", true, false, false, 0, nil, 0)
    AppAddBodygroup("TORSO", "Куртка Моссман", "female_mossman_jacket.smd", true, false, false, 0, nil, 0)

    AppAddBodygroup("LEGS", "Стандартный низ", "female_reference_bottom.smd", true, false, false, 0, nil, 0)
    AppAddBodygroup("LEGS", "Широкий низ", "female_reference_wide_bottom.smd", true, false, false, 0, nil, 0)
    AppAddBodygroup("LEGS", "Ботинки", "female_reference_boots.smd", true, false, false, 0, nil, 0)
end
hook.Add("ZPointshopLoaded", "AddBodygroups", AddBodygroupsFunc)

hg.Appearance.SkeletonAppearanceTable = {
    AModel = "Мужчина 07",
    AClothes = { main = "normal" },
    AName = "Иван Z-City",
    AColor = Color(180, 0, 0),
    AAttachments = {},
    ABodygroups = {},
    AFacemap = "По умолчанию"
}

function hg.Appearance.GetRandomAppearance()
    local randomAppearance = table.Copy(hg.Appearance.SkeletonAppearanceTable)
    local iSex = math.random(1, 2)
    local tMdl, str = table.Random(PlayerModels[iSex])
    randomAppearance.AModel = str
    _, str = table.Random(hg.Appearance.Clothes[iSex])
    randomAppearance.AClothes = {
        main = str,
        pants = str,
        boots = str
    }
    randomAppearance.AName = GenerateRandomName(iSex)
    randomAppearance.AColor = ColorRand(false)

    for i = 1, 1 do
        local data, k = table.Random(hg.Accessories or {})
        for _, name in ipairs(randomAppearance.AAttachments) do
            if hg.Accessories[name] and hg.Accessories[name].placement == data.placement then
                k = "none"
            end
        end
        if data.disallowinappearance then
            k = "none"
        end
        randomAppearance.AAttachments[i] = k
    end

    local _, facemap = table.Random(hg.Appearance.FacemapsSlots[hg.Appearance.FacemapsModels[tMdl.mdl]] or {})
    randomAppearance.AFacemap = facemap
    return randomAppearance
end

hg.Appearance.ValidateFunctions = {
    AModel = function(str)
        if not isstring(str) then return false end
        if not PlayerModels[1][str] and not PlayerModels[2][str] then return false end
        return true
    end,
    AClothes = function(tbl)
        if not istable(tbl) then return false end
        if table.Count(tbl) > 3 then return false end
        return true
    end,
    AName = function(str)
        if not isstring(str) then return false end
        return not IsInvalidName(str)
    end,
    AColor = function()
        return true
    end,
    AAttachments = function(tbl)
        if not istable(tbl) then return false end
        if table.Count(tbl) > 3 then return false end

        local occupatedSlots = {}
        for k, v in ipairs(tbl) do
            if not hg.Accessories[v] then continue end
            if occupatedSlots[hg.Accessories[v].placement] then
                tbl[k] = ""
                continue
            end
            if hg.Accessories[v].placement then
                occupatedSlots[hg.Accessories[v].placement] = true
            end
        end

        return true
    end,
    ABodygroups = function(tbl)
        if not istable(tbl) then return false end
        if table.Count(tbl) > 3 then return false end
        return true
    end,
    AFacemap = function(str)
        if not isstring(str) then return false end
        return true
    end
}

local function AppearanceValidater(tblAppearance)
    if not istable(tblAppearance) then return false end

    local VaildFuncs = hg.Appearance.ValidateFunctions
    local bValidAModel = VaildFuncs.AModel(tblAppearance.AModel)
    local bValidAClothes = VaildFuncs.AClothes(tblAppearance.AClothes)
    local bValidAName = VaildFuncs.AName(tblAppearance.AName)
    local bValidAColor = VaildFuncs.AColor(tblAppearance.AColor)
    local bValidAAttachments = VaildFuncs.AAttachments(tblAppearance.AAttachments)
    local bValidABodygroups = VaildFuncs.ABodygroups(tblAppearance.ABodygroups or {})
    local bValidAFacemap = VaildFuncs.AFacemap(tblAppearance.AFacemap or "")

    if bValidAModel and bValidAClothes and bValidAName and bValidAColor and bValidAAttachments and bValidABodygroups and bValidAFacemap then
        return true
    end

    return false
end
hg.Appearance.AppearanceValidater = AppearanceValidater

function ThatPlyIsFemale(ply)
    ply.CahceModel = ply.CahceModel or ""
    if ply.CahceModel == ply:GetModel() then return ply.bSex end
    local tSubModels = ply:GetSubModels()
    if not tSubModels then return false end
    ply.CahceModel = ply:GetModel()
    for i = 1, #tSubModels do
        local name = tSubModels[i].name
        if name == "models/m_anm.mdl" then
            ply.bSex = false
            return false
        end
        if name == "models/f_anm.mdl" then
            ply.bSex = true
            return true
        end
    end
    return false
end

local plymeta = FindMetaTable("Player")
function plymeta:GetZCAppearanceSubSlots()
    local tMdl = hg.Appearance.FuckYouModels[1][self:GetModel()] or hg.Appearance.FuckYouModels[2][self:GetModel()]
    local mats = self:GetMaterials()
    local slots = {}
    if istable(tMdl) then
        for _, v in pairs(tMdl.submatSlots) do
            local slot = 0
            for i = 1, #mats do
                if mats[i] == v then
                    slot = i - 1
                    break
                end
            end
            slots[#slots + 1] = slot
        end
    end
    return slots
end

local entmeta = FindMetaTable("Entity")
function entmeta:GetZCSubMaterialIndexByName(strName)
    local mats = self:GetMaterials()
    local id = nil
    for i = 1, #mats do
        if mats[i] == strName then
            id = i - 1
            break
        end
    end
    return id
end