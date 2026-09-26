--[[
    Rivals Instrumentation Suite — Bootstrap Loader
    Target: Luau / Roblox Client Environment
    Execution:
        Direct Loadstring:
            loadstring(game:HttpGet("https://raw.githubusercontent.com/.../suite/main.luau"))()
        Local File Execution (Solara / Swift / Wave / MacSploit / etc.):
            loadfile("suite/main.luau")()
--]]

local function logInfo(message)
    print(string.format("[Rivals-Suite] [INFO] %s", tostring(message)))
end

local function logWarn(message)
    warn(string.format("[Rivals-Suite] [WARN] %s", tostring(message)))
end

-- 1. Capability & Environment Verification
logInfo("Validating executor runtime capabilities...")

local hasDrawing = (type(Drawing) == "table" or type(Drawing) == "userdata" or type(Drawing) == "function")
local hasHook = (type(hookmetamethod) == "function" or type(hookfunction) == "function")
local hasMouseRel = (type(mousemoverel) == "function")
local hasHui = (type(gethui) == "function")

if not hasDrawing then
    logWarn("Drawing API not found. 2D vector overlays will operate in fallback mode.")
else
    logInfo("Drawing API verified: Active.")
end

if not hasHook then
    logWarn("hookmetamethod not found. Silent raycast interception will be restricted.")
else
    logInfo("Metamethod hook verified: Active.")
end

if not hasMouseRel then
    logWarn("mousemoverel not found. Mouse cursor targeting will use camera lerp fallback.")
else
    logInfo("Hardware mouse input emulation verified: Active.")
end

if hasHui then
    logInfo("CoreGui isolation (gethui) verified: Active.")
end

-- 2. Bootstrap Execution
local suiteLoaded = false

-- Method A: Local File Loader (if in workspace or executor filesystem)
if type(readfile) == "function" then
    local candidates = {
        "suite/main.luau",
        "roblox/suite/main.luau",
        "main.luau"
    }

    for _, path in ipairs(candidates) do
        local success, content = pcall(readfile, path)
        if success and content and #content > 0 then
            logInfo("Loading suite from local file: " .. path)
            local fn, compileErr = loadstring(content)
            if fn then
                pcall(fn)
                suiteLoaded = true
                break
            else
                logWarn("Compilation failed for " .. path .. ": " .. tostring(compileErr))
            end
        end
    end
end

-- Method B: Direct URL Fetch (Standard Loadstring Pattern)
if not suiteLoaded then
    -- Remote repository bundle URL
    local RemoteSuiteUrl = "https://raw.githubusercontent.com/cylixstudios/rivals-instrumentation/main/main.luau"
    
    local success, response = pcall(function()
        return game:HttpGet(RemoteSuiteUrl)
    end)

    if success and response and #response > 0 then
        logInfo("Fetched remote suite bundle successfully. Executing...")
        local fn, compileErr = loadstring(response)
        if fn then
            pcall(fn)
            suiteLoaded = true
        else
            logWarn("Failed to compile remote bundle: " .. tostring(compileErr))
        end
    end
end

if suiteLoaded then
    logInfo("Instrumentation Suite successfully initialized. Press RightShift to toggle UI.")
else
    logWarn("Execution failed. Run suite/main.luau directly or verify network access.")
end
