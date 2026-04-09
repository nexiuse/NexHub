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
local function loadGameScript()
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
-- JALUR PREMIUM: KEY SYSTEM BAWAAN VELARISUI
-- ============================================
local Analytics = game:GetService("RbxAnalyticsService")
local HWID = "Unknown"
pcall(function() 
    if gethwid then HWID = gethwid() else HWID = Analytics:GetClientId() end
end)

local Window = VelarisUI:Window({
    Title = "NexHub - " .. detectedGame.name,
    Footer = ".",
    Color = "Nex",
    Author = "developed by Nex",
    Folder = "NexHub-Auth",
    Icon = "rbxassetid://128795866459585",
    Size = UDim2.fromOffset(450, 280),
    Uitransparent = 0.35,
    NewElements = true,
    Keybind = Enum.KeyCode.LeftAlt,
    ShowUser = true,
    HideSearchBar = true,

    -- KEY SYSTEM BAWAAN VELARISUI
    KeySystem = {
        Title = "NexHub - Authentication",
        Icon = "lucide:key",
        Placeholder = "Masukkan Kunci NexHub",
        Default = "",
        DiscordText = "Bergabung ke Discord",
        DiscordUrl = "https://discord.gg/nexhub",
        Links = {
            { Name = "Dapatkan Kunci", Icon = "lucide:link", Url = "https://discord.gg/nexhub" },
        },
        Steps = {
            "Selamat Datang di NexHub!",
            "Game: " .. detectedGame.name .. " (Premium)",
            "Masukkan kunci eksklusif dari Discord untuk melanjutkan.",
        },
        Callback = function(keyInput)
            local isValid = false

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
                    isValid = true
                end
            end

            -- Jika valid, VelarisUI otomatis hilangkan key screen dan buka window
            -- Kita destroy window loader lalu load script game
            if isValid then
                task.spawn(function()
                    task.wait(1)
                    -- Destroy loader window (yang kosong)
                    pcall(function() Window:Destroy() end)
                    -- Hapus semua GUI sisa loader dari semua container
                    pcall(function()
                        local containers = {}
                        pcall(function() table.insert(containers, gethui and gethui() or game:GetService("CoreGui")) end)
                        pcall(function() table.insert(containers, game:GetService("CoreGui")) end)
                        pcall(function() table.insert(containers, game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")) end)
                        for _, parent in ipairs(containers) do
                            if parent then
                                for _, gui in ipairs(parent:GetChildren()) do
                                    if gui:IsA("ScreenGui") then
                                        local isLoader = false
                                        for _, desc in ipairs(gui:GetDescendants()) do
                                            if desc:IsA("TextLabel") and desc.Text and desc.Text:find("NexHub") and desc.Text:find(detectedGame.name) then
                                                isLoader = true
                                                break
                                            end
                                        end
                                        if isLoader then
                                            pcall(function() gui.Enabled = false; gui:Destroy() end)
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.5)
                    loadGameScript()
                end)
            end

            return isValid
        end,
    }
})
