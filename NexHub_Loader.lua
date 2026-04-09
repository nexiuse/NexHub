-- ============================================
-- NEXHUB UNIVERSAL LOADER v2.0 (VELARIS UI)
-- Satu Script Untuk Semua Game
-- ============================================
local VelarisUI
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/nhfudzfsrzggt/brigida/refs/heads/main/dist/main.lua", true))()
    end)
    VelarisUI = ok and result or nil
end

if not VelarisUI then
    warn("Gagal merender VelarisUI.")
    return
end

-- ============================================
-- THEME
-- ============================================
pcall(function()
    VelarisUI:AddTheme({
        Name = "Nex",
        Icon = Color3.fromHex("#ffffff"),
        Accent = Color3.fromHex("#14ADC7"),
        Dialog = Color3.fromHex("#ffffff"),
        Outline = Color3.fromHex("#0074D9"),
        Text = Color3.fromHex("#f8fafc"),
        Placeholder = Color3.fromHex("#94a3b8"),
        Button = Color3.fromHex("#1c1c1c"),
        WindowBackground = Color3.fromHex("#0f0f0f")
    })
end)

-- ============================================
-- KONFIGURASI GAME & API
-- ============================================
local API_URL = "https://nexhubser-api-production.up.railway.app/api/verify"
local HttpService = game:GetService("HttpService")
local currentPlaceId = game.PlaceId
local currentGameId = game.GameId

-- Daftar game yang didukung
local GameList = {
    -- FREE GAMES
    { name = "FishZar", placeIds = {121442629947656}, type = "free", scriptUrl = "https://raw.githubusercontent.com/nexiuse/NexHub/main/NexHubFishZar.lua" },
    { name = "Fish God", placeIds = {121500015379301}, type = "free", scriptUrl = "https://raw.githubusercontent.com/nexiuse/NexHub/main/NexHubFishGod.lua" },
    { name = "Survive The Apocalypse", placeIds = {90148635862803}, gameIds = {9098570654}, type = "free", scriptUrl = "https://raw.githubusercontent.com/nexiuse/NexHub/refs/heads/main/NexHubSurviveTheApocalypse.lua" },

    -- PREMIUM GAMES (Butuh Key)
    { name = "Blox Fruits", placeIds = {2753915549, 4442272183, 7449423635}, type = "premium", scriptUrl = "https://raw.githubusercontent.com/nexiuse/NexHub/main/BloxFruitsLuxv'SHubXNex_protected.lua" },
    { name = "Violence District", placeIds = {93978595733734}, type = "premium", scriptUrl = "https://raw.githubusercontent.com/nexiuse/NexHub/main/NexHubVD.lua" },
    { name = "Sailor Piece", placeIds = {77747658251236}, type = "premium", scriptUrl = "https://raw.githubusercontent.com/nexiuse/NexHub/refs/heads/main/NexHubSailorPiece.lua" },
}

-- ============================================
-- DETEKSI GAME OTOMATIS
-- ============================================
local detectedGame = nil

for _, gameInfo in ipairs(GameList) do
    if gameInfo.placeIds then
        for _, pid in ipairs(gameInfo.placeIds) do
            if currentPlaceId == pid then detectedGame = gameInfo break end
        end
    end
    if not detectedGame and gameInfo.gameIds then
        for _, gid in ipairs(gameInfo.gameIds) do
            if currentGameId == gid then detectedGame = gameInfo break end
        end
    end
    if detectedGame then break end
end

-- ============================================
-- GAME TIDAK DIKENALI
-- ============================================
if not detectedGame then
    VelarisUI:MakeNotify({
        Title = "NexHub Loader",
        Content = "Game tidak dikenali.\nPlaceId: " .. tostring(currentPlaceId) .. "\nGameId: " .. tostring(currentGameId),
        Duration = 10
    })
    return
end

-- ============================================
-- FUNGSI: MUAT SCRIPT GAME
-- ============================================
local _authTitle = nil -- will be set when auth window created
local _authGuiRef = nil -- captured reference to auth ScreenGui

local function findAndDestroyAuthGui()
    if not _authTitle then return end
    
    -- Collect all possible GUI parents
    local parents = {}
    pcall(function() table.insert(parents, gethui and gethui() or game:GetService("CoreGui")) end)
    pcall(function() table.insert(parents, game:GetService("CoreGui")) end)
    pcall(function() table.insert(parents, game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")) end)
    
    for _, parent in ipairs(parents) do
        if parent then
            pcall(function()
                for _, gui in ipairs(parent:GetChildren()) do
                    if gui:IsA("ScreenGui") then
                        for _, desc in ipairs(gui:GetDescendants()) do
                            if desc:IsA("TextLabel") and desc.Text and desc.Text:find(_authTitle) then
                                gui.Enabled = false
                                gui:Destroy()
                                break
                            end
                        end
                    end
                end
            end)
        end
    end
    
    -- Also try direct reference
    if _authGuiRef then
        pcall(function() _authGuiRef.Enabled = false end)
        pcall(function() _authGuiRef:Destroy() end)
    end
end

local function loadGameScript()
    -- Hapus auth UI DULU sebelum apapun
    findAndDestroyAuthGui()
    task.wait(0.5)

    -- Eksekusi script game
    task.wait(0.5)
    local success, err = pcall(function()
        loadstring(game:HttpGet(detectedGame.scriptUrl))()
    end)

    if not success then
        local errMsg = tostring(err)
        if errMsg:find("404") then
            errMsg = "File tidak ditemukan di GitHub! Cek URL: " .. detectedGame.scriptUrl
        end
        warn("NexHub Loader Error: " .. errMsg)
        VelarisUI:MakeNotify({
            Title = "NexHub Error",
            Content = errMsg,
            Duration = 10
        })
    end
end

-- ============================================
-- JALUR FREE: LANGSUNG MUAT
-- ============================================
if detectedGame.type == "free" then
    VelarisUI:MakeNotify({
        Title = "NexHub - Free Access",
        Content = "Game: " .. detectedGame.name .. " (Gratis). Memuat otomatis...",
        Duration = 3
    })
    task.wait(1)
    loadGameScript()
    return
end

-- ============================================
-- JALUR PREMIUM: VERIFIKASI KEY DULU
-- ============================================
local Analytics = game:GetService("RbxAnalyticsService")

_G.Authenticated = false
local HWID = "Unknown"
pcall(function() 
    if gethwid then HWID = gethwid() else HWID = Analytics:GetClientId() end
end)

-- Set auth title untuk cleanup nanti
_authTitle = "NexHub - " .. detectedGame.name

local AuthWindow = VelarisUI:Window({
    Title = _authTitle,
    Footer = ".",
    Color = "Nex",
    Author = "Premium Access Required",
    Folder = "NexHub-Auth",
    Icon = "rbxassetid://128795866459585",
    Size = UDim2.fromOffset(450, 280),
    Uitransparent = 0.35,
    NewElements = true,
    ToggleKey = Enum.KeyCode.LeftAlt,
    User = {Enabled = true, Anonymous = true},
    HideSearchBar = true,
    Topbar = {Height = 43, ButtonsType = "Default"},
})

-- Capture referensi ScreenGui auth window
task.delay(1, function()
    local locations = {}
    pcall(function() table.insert(locations, gethui and gethui() or game:GetService("CoreGui")) end)
    pcall(function() table.insert(locations, game:GetService("CoreGui")) end)
    pcall(function() table.insert(locations, game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")) end)
    for _, parent in ipairs(locations) do
        if parent and not _authGuiRef then
            pcall(function()
                for _, gui in ipairs(parent:GetChildren()) do
                    if gui:IsA("ScreenGui") and not _authGuiRef then
                        for _, desc in ipairs(gui:GetDescendants()) do
                            if desc:IsA("TextLabel") and desc.Text and desc.Text:find(_authTitle) then
                                _authGuiRef = gui
                                break
                            end
                        end
                    end
                end
            end)
        end
    end
end)

AuthWindow:Tag({
    Title = "Premium",
    Color = Color3.fromRGB(68, 48, 221),
    TextColor = Color3.fromRGB(255, 255, 255),
})

local AuthTab = AuthWindow:AddTab({Name = "Key System", Title = "Key System", Border = true})
local AuthSection = AuthTab:AddSection({Title = "Verifikasi Kunci"})

local keyInput = ""

AuthSection:AddParagraph({
    Title = "Game Terdeteksi",
    Desc = detectedGame.name .. " (Premium)\nMasukkan kunci NexHub untuk melanjutkan."
})

AuthSection:AddInput({
    Title = "Masukkan Kunci",
    Placeholder = "NEXHUB-XXXX-XXXX",
    Callback = function(v) keyInput = v end
})

AuthSection:AddButton({
    Title = "Verifikasi Kunci",
    Callback = function()
        VelarisUI:MakeNotify({Title = "Status", Content = "Menghubungi Server NexHub...", Duration = 2})
        task.spawn(function()
            local success, response = pcall(function()
                local httpReq = (syn and syn.request) or request or http_request or (fluxus and fluxus.request)
                if httpReq then
                    local res = httpReq({
                        Url = API_URL,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode({ 
                            key = keyInput, 
                            hwid = HWID, 
                            userid = tostring(game:GetService("Players").LocalPlayer.UserId) 
                        })
                    })
                    return HttpService:JSONDecode(res.Body)
                else
                    error("Executor tidak mendukung HTTP Request")
                end
            end)

            if success and response then
                if response.success then
                    VelarisUI:MakeNotify({Title = "Berhasil", Content = response.message or "Kunci Valid! Membuka script...", Duration = 3})
                    _G.Authenticated = true
                else
                    VelarisUI:MakeNotify({Title = "Ditolak", Content = response.message or "Kunci tidak valid.", Duration = 3})
                end
            else
                VelarisUI:MakeNotify({Title = "Error", Content = "Server Offline / Diblokir Executor.", Duration = 3})
            end
        end)
    end
})

AuthSection:AddButton({
    Title = "Dapatkan Kunci",
    Callback = function()
        pcall(function() setclipboard("https://discord.gg/nexhub") end)
        VelarisUI:MakeNotify({Title = "Info", Content = "Link Discord disalin ke clipboard!", Duration = 3})
    end
})

-- Tunggu sampai kunci valid, lalu muat skrip game
task.spawn(function()
    repeat task.wait(0.5) until _G.Authenticated
    task.wait(1)
    loadGameScript()
end)
