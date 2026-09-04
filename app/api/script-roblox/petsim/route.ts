import { NextRequest, NextResponse } from "next/server";
import fs from "fs";
import path from "path";
import crypto from "crypto";

// Fast in-memory cache for warm serverless containers
let globalCache: { sourceHash: string; obfuscatedCode: string } | null = null;

function makeId(length = 8): string {
  let result = "";
  const characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  result += characters.charAt(Math.floor(Math.random() * characters.length));
  const fullChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
  for (let i = 1; i < length; i++) {
    result += fullChars.charAt(Math.floor(Math.random() * fullChars.length));
  }
  return result;
}

function stripComments(code: string): string {
  // Strip multi-line comments: --[[ ... ]]
  let clean = code.replace(/--\[\[[\s\S]*?\]\]/g, "");
  // Strip single-line comments: -- ...
  clean = clean
    .split("\n")
    .map((line) => {
      let inDouble = false;
      let inSingle = false;
      for (let i = 0; i < line.length; i++) {
        const c = line[i];
        if (c === '"' && line[i - 1] !== "\\") inDouble = !inDouble;
        if (c === "'" && line[i - 1] !== "\\") inSingle = !inSingle;
        if (c === "-" && line[i + 1] === "-" && !inDouble && !inSingle) {
          return line.substring(0, i);
        }
      }
      return line;
    })
    .join("\n");
  return clean;
}

function unescapeLuaString(s: string): string {
  return s
    .replace(/\\n/g, "\n")
    .replace(/\\t/g, "\t")
    .replace(/\\r/g, "\r")
    .replace(/\\b/g, "\b")
    .replace(/\\f/g, "\f")
    .replace(/\\v/g, "\v")
    .replace(/\\\\/g, "\\")
    .replace(/\\"/g, '"')
    .replace(/\\'/g, "'")
    .replace(/\\(\d{1,3})/g, (_match, p1) => {
      return String.fromCharCode(parseInt(p1, 10));
    })
    .replace(/\\x([0-9a-fA-F]{2})/g, (_match, p1) => {
      return String.fromCharCode(parseInt(p1, 16));
    });
}

function localObfuscate(code: string, decName: string, key: number): string {
  const strings: string[] = [];
  const stringRegex = /"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/g;

  const result = code.replace(stringRegex, (match) => {
    const content = match.slice(1, -1);
    const unescaped = unescapeLuaString(content);
    strings.push(unescaped);
    return `${decName}(${strings.length})`;
  });

  const arrayName = makeId(8);
  const encryptedStrings = strings.map((s) => {
    const bytes: number[] = [];
    const buf = Buffer.from(s, "utf8");
    for (let i = 0; i < buf.length; i++) {
      bytes.push(buf[i] ^ key);
    }
    return bytes.join(",");
  });

  const finalCode = `
local ${arrayName} = {
  ${encryptedStrings.map((s, idx) => `[${idx + 1}] = {${s}}`).join(",\n  ")}
}
local function ${decName}(idx)
  local data = ${arrayName}[idx]
  if not data then return "" end
  local chars = {}
  for i = 1, #data do
    table.insert(chars, string.char(bit32.bxor(data[i], ${key})))
  end
  return table.concat(chars)
end

${result}
`;

  return finalCode;
}

function obfuscateLuaXor(code: string, licenseKey = "KEYLESS"): string {
  const decName = makeId(8);
  const encryptionKey = Math.floor(Math.random() * 254) + 1;
  const scrambledCode = localObfuscate(stripComments(code), decName, encryptionKey);

  const clean = scrambledCode;

  let seed = 5381;
  for (let i = 0; i < licenseKey.length; i++) {
    seed = (seed * 33 + licenseKey.charCodeAt(i)) % 2147483647;
  }
  if (seed === 0) {
    seed = 123456789;
  }

  let hexString = "";
  const buf = Buffer.from(clean, "utf8");
  let currentSeed = seed;

  for (let i = 0; i < buf.length; i++) {
    currentSeed = (currentSeed * 48271) % 2147483647;
    const keyByte = currentSeed % 256;
    const encryptedByte = buf[i] ^ keyByte;
    hexString += encryptedByte.toString(16).padStart(2, "0");
  }

  const varSeed = makeId(10);
  const varPayload = makeId(10);
  const varSource = makeId(10);
  const varIndex = makeId(10);
  const varFunc = makeId(10);
  const varErr = makeId(10);
  const varKeyByte = makeId(10);
  const varByteStr = makeId(10);
  const varVal = makeId(10);

  const obfuscated = `
local ${varSeed} = ${seed}
local ${varPayload} = "${hexString}"
local ${varSource} = {}
for ${varIndex} = 1, #${varPayload}, 2 do
    local ${varByteStr} = string.sub(${varPayload}, ${varIndex}, ${varIndex} + 1)
    local ${varVal} = tonumber(${varByteStr}, 16)
    ${varSeed} = (${varSeed} * 48271) % 2147483647
    local ${varKeyByte} = ${varSeed} % 256
    table.insert(${varSource}, string.char(bit32.bxor(${varVal}, ${varKeyByte})))
end
local ${varFunc}, ${varErr} = loadstring(table.concat(${varSource}))
if not ${varFunc} then
    error("HipHub Boot Error: Connection payload is corrupted: " .. tostring(${varErr}))
end
${varFunc}()
`;
  return obfuscated;
}

function getErrorGuiLua(errorMessage: string, keyUrl: string): string {
  return `
local player = game:GetService("Players").LocalPlayer
local errGui = Instance.new("ScreenGui")
errGui.Name = "HipHubError"
errGui.ResetOnSpawn = false
errGui.DisplayOrder = 2147483647

local function findGuiInParents(name)
    if gethui then
        local g = gethui():FindFirstChild(name)
        if g then return g end
    end
    local c = game:GetService("CoreGui"):FindFirstChild(name)
    if c then return c end
    local p = player:WaitForChild("PlayerGui"):FindFirstChild(name)
    if p then return p end
    return nil
end

pcall(function()
    local oldErr = findGuiInParents("HipHubError")
    if oldErr then oldErr:Destroy() end
end)

pcall(function()
    local parentGui
    if gethui then
        parentGui = gethui()
    else
        local coreGui = game:GetService("CoreGui")
        local successCore, _ = pcall(function()
            local test = Instance.new("Folder")
            test.Parent = coreGui
            test:Destroy()
        end)
        if successCore then
            parentGui = coreGui
        else
            parentGui = player:WaitForChild("PlayerGui")
        end
    end
    errGui.Parent = parentGui
    
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 380, 0, 160)
    main.Position = UDim2.new(0.5, -190, 0.5, -80)
    main.BackgroundColor3 = Color3.fromRGB(12, 22, 34)
    main.BorderSizePixel = 0
    main.Parent = errGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = main
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundTransparency = 1
    title.Text = "🐾 HipHub - Pet Simulator 99"
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = main
    
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -20, 0, 60)
    msg.Position = UDim2.new(0, 10, 0, 40)
    msg.BackgroundTransparency = 1
    msg.Text = "${errorMessage}"
    msg.TextColor3 = Color3.fromRGB(230, 245, 255)
    msg.Font = Enum.Font.GothamMedium
    msg.TextSize = 12
    msg.TextWrapped = true
    msg.Parent = main
end)
`;
}

export async function GET(request: NextRequest) {
  try {
    const userAgent = (request.headers.get("user-agent") || "").toLowerCase();
    const isRoblox =
      userAgent.includes("roblox") ||
      userAgent.includes("okhttp") ||
      userAgent.includes("delta") ||
      userAgent.includes("codex") ||
      userAgent.includes("hydrogen") ||
      userAgent.includes("arceus") ||
      userAgent.includes("vega") ||
      userAgent.includes("dalvik") ||
      userAgent.includes("darwin") ||
      userAgent.includes("executor") ||
      userAgent.includes("postman") ||
      userAgent.includes("insomnia") ||
      userAgent.includes("curl") ||
      userAgent.includes("python-requests");

    const { searchParams } = new URL(request.url);
    const isRaw = searchParams.get("raw") === "true";

    if (!isRoblox && !isRaw) {
      return new NextResponse(
        `-- 🐾 HipHub Script Server - Pet Simulator 99
-- Error: Direct browser access is not allowed. Please execute via your Roblox script executor:
-- loadstring(game:HttpGet("${request.url}"))()`,
        {
          status: 403,
          headers: { "Content-Type": "text/plain" },
        }
      );
    }

    // Bundle script modules
    const petsimDir = path.join(process.cwd(), "app", "api", "script-roblox", "petsim");
    const uiPath = path.join(petsimDir, "ui.lua");
    const settingsPath = path.join(petsimDir, "settings.lua");
    const featuresPath = path.join(petsimDir, "features.lua");
    const mainPath = path.join(petsimDir, "main.lua");

    let uiLua = "";
    let settingsLua = "";
    let featuresLua = "";
    let mainLua = "";

    try {
      uiLua = fs.readFileSync(uiPath, "utf8");
      settingsLua = fs.readFileSync(settingsPath, "utf8");
      featuresLua = fs.readFileSync(featuresPath, "utf8");
      mainLua = fs.readFileSync(mainPath, "utf8");
    } catch (readErr) {
      console.error("Failed to read petsim script components:", readErr);
      return new NextResponse(
        getErrorGuiLua("Failed to load Pet Simulator 99 modules from server.", "https://hiphub.cloud/"),
        { headers: { "Content-Type": "text/plain" } }
      );
    }

    const bundledLua = `
-- ==============================================================================
-- 🐾 HipHub — Pet Simulator 99 Complete Automation Suite
-- Theme: Liquid Glass Futuristic UI with Cyan-Violet Neon Accents
-- ==============================================================================

-- [Module 1: UI Engine]
${uiLua}

-- [Module 2: Settings Engine]
${settingsLua}

-- [Module 3: Features & Automation Engine]
${featuresLua}

-- [Module 4: Main Controller Engine]
${mainLua}
`;

    if (isRaw) {
      return new NextResponse(bundledLua, {
        headers: {
          "Content-Type": "text/plain",
          "Cache-Control": "no-store, no-cache, must-revalidate",
        },
      });
    }

    // Hash source for caching
    const sourceHash = crypto.createHash("sha256").update(bundledLua).digest("hex");

    if (globalCache && globalCache.sourceHash === sourceHash) {
      return new NextResponse(globalCache.obfuscatedCode, {
        headers: {
          "Content-Type": "text/plain",
          "Cache-Control": "no-store, no-cache, must-revalidate",
        },
      });
    }

    // Obfuscate with XOR stream cipher
    const finalScript = obfuscateLuaXor(bundledLua, "KEYLESS");
    globalCache = { sourceHash, obfuscatedCode: finalScript };

    return new NextResponse(finalScript, {
      headers: {
        "Content-Type": "text/plain",
        "Cache-Control": "no-store, no-cache, must-revalidate",
      },
    });
  } catch (error: unknown) {
    const err = error as Error;
    console.error("PetSim script delivery error:", err);
    return new NextResponse(
      getErrorGuiLua("Server delivery failure. Please try again later!", "https://hiphub.cloud/"),
      { headers: { "Content-Type": "text/plain" } }
    );
  }
}
