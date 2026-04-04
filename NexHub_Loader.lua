-- ============================================
-- NEXHUB UNIVERSAL LOADER v1.0
-- Satu Script Untuk Semua Game
-- ============================================
local WindUI
do
    local ok, result = pcall(require, "./src/Init")
    WindUI = ok and result or loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end

WindUI:AddTheme({
    Name = "Nex",
    Icon = Color3.fromHex("#ffffff"),
    Accent = WindUI:Gradient({
        ["0"] = { Color = Color3.fromRGB(0, 0, 0), Transparency = 0.4 },
        ["100"] = { Color = Color3.fromRGB(0, 0, 0), Transparency = 0.4 },
    }),
    Dialog = Color3.fromHex("#ffffff"),
    Outline = Color3.fromHex("#0074D9"),
    Text = Color3.fromHex("#f8fafc"),
    Placeholder = Color3.fromHex("#94a3b8"),
    Button = WindUI:Gradient({
        ["0"] = { Color = Color3.fromRGB(0, 0, 0), Transparency = 0.4 },
        ["100"] = { Color = Color3.fromRGB(0, 0, 0), Transparency = 0.4 },
    }),
    WindowBackground = WindUI:Gradient({
        ["0"] = { Color = Color3.fromRGB(0, 0, 0), Transparency = 0.4 },
        ["100"] = { Color = Color3.fromRGB(0, 0, 0), Transparency = 0.4 },
    }, {Rotation = 45}),
})

-- ============================================
-- KONFIGURASI GAME
-- ============================================
-- Ganti URL_API_SERVER dengan URL Railway-mu yang asli
local API_URL = "https://nexhubser-api-production.up.railway.app/api/verify"

local HttpService = game:GetService("HttpService")
local currentPlaceId = game.PlaceId

-- Daftar game yang didukung
-- type = "free" : langsung masuk tanpa key
-- type = "premium" : harus verifikasi key dulu
local GameList = {
    -- FREE GAMES
    { name = "FishZar",           placeIds = {121442629947656},                    type = "free",    scriptUrl = "https://raw.githubusercontent.com/nexiuse/NexHub/main/NexHubFishZar.lua" },
    { name = "Fish God",          placeIds = {121500015379301},                    type = "free",    scriptUrl = "https://raw.githubusercontent.com/nexiuse/NexHub/main/NexHubFishGod.lua" },

    -- PREMIUM GAMES (Butuh Key)
    { name = "Blox Fruits",       placeIds = {2753915549, 4442272183, 7449423635}, type = "premium", scriptUrl = "https://raw.githubusercontent.com/nexiuse/NexHub/main/BloxFruitsLuxv'SHubXNex_protected.lua" },
    { name = "Violence District", placeIds = {93978595733734},                    type = "premium", scriptUrl = "https://raw.githubusercontent.com/nexiuse/NexHub/main/NexHubVD.lua" },
}

-- ============================================
-- DETEKSI GAME OTOMATIS
-- ============================================
local detectedGame = nil

for _, gameInfo in ipairs(GameList) do
    for _, pid in ipairs(gameInfo.placeIds) do
        if currentPlaceId == pid then
            detectedGame = gameInfo
            break
        end
    end
    if detectedGame then break end
end

-- ============================================
-- GAME TIDAK DIKENALI
-- ============================================
if not detectedGame then
    WindUI:Notify({
        Title = "NexHub Loader",
        Content = "Game ini tidak didukung oleh NexHub. (PlaceId: " .. tostring(currentPlaceId) .. ")",
        Duration = 10
    })
    return
end

-- ============================================
-- FUNGSI: MUAT SCRIPT GAME
-- ============================================
local function loadGameScript()
    WindUI:Notify({
        Title = "NexHub",
        Content = "Memuat " .. detectedGame.name .. "...",
        Duration = 3
    })
    
    -- Hapus semua UI loader
    task.wait(1)
    local targetGui = gethui and gethui() or game:GetService("CoreGui")
    for _, gui in ipairs(targetGui:GetChildren()) do
        if gui:IsA("ScreenGui") and (gui.Name == "WindUI" or gui:FindFirstChild("MainFrame")) then
            gui:Destroy()
        end
    end
    
    -- Eksekusi script game
    task.wait(0.5)
    local success, err = pcall(function()
        loadstring(game:HttpGet(detectedGame.scriptUrl))()
    end)
    
    if not success then
        warn("NexHub Loader Error: " .. tostring(err))
    end
end

-- ============================================
-- JALUR FREE: LANGSUNG MUAT
-- ============================================
if detectedGame.type == "free" then
    WindUI:Notify({
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

local AuthWindow = WindUI:CreateWindow({
    Title = "NexHub - " .. detectedGame.name,
    Theme = "Nex",
    Author = "Premium Access Required",
    Folder = "NexHub-Auth",
    Size = UDim2.fromOffset(350, 200),
    Transparent = true,
    HideSearchBar = true,
})

local AuthTab = AuthWindow:Tab({ Title = "Key System", Icon = "key" })
local keyInput = ""

AuthTab:Paragraph({
    Title = "Game Terdeteksi",
    Content = detectedGame.name .. " (Premium)\nMasukkan kunci NexHub untuk melanjutkan."
})

AuthTab:Input({
    Title = "Masukkan Kunci",
    Placeholder = "NEXHUB-XXXX-XXXX",
    Callback = function(v) keyInput = v end
})

AuthTab:Button({
    Title = "Verifikasi Kunci",
    Callback = function()
        WindUI:Notify({Title = "Status", Content = "Menghubungi Server NexHub...", Duration = 2})
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
                    WindUI:Notify({Title = "Berhasil", Content = response.message, Duration = 3})
                    _G.Authenticated = true
                else
                    WindUI:Notify({Title = "Ditolak", Content = response.message, Duration = 3})
                end
            else
                WindUI:Notify({Title = "Error", Content = "Server Offline / Diblokir Executor.", Duration = 3})
            end
        end)
    end
})

AuthTab:Button({
    Title = "Dapatkan Kunci",
    Callback = function()
        pcall(function() setclipboard("https://discord.gg/nexhub") end)
        WindUI:Notify({Title = "Info", Content = "Link Discord disalin ke clipboard!", Duration = 3})
    end
})

-- Tunggu sampai kunci valid, lalu muat skrip game
task.spawn(function()
    repeat task.wait(0.5) until _G.Authenticated
    task.wait(1)
    loadGameScript()
end)
