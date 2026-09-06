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
  const fullChars =
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
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
  const scrambledCode = localObfuscate(
    stripComments(code),
    decName,
    encryptionKey
  );

  const clean = scrambledCode;

  let seed = 5381;
  for (let i = 0; i < licenseKey.length; i++) {
    seed = (seed * 33 + licenseKey.charCodeAt(i)) % 2147483647;
  }
  if (seed === 0) seed = 123456789;

  let hexString = "";
  const buf = Buffer.from(clean, "utf8");
  let currentSeed = seed;

  for (let i = 0; i < buf.length; i++) {
    currentSeed = (currentSeed * 48271) % 2147483647;
    const keyByte = currentSeed % 256;
    const encryptedByte = buf[i] ^ keyByte;
    hexString += encryptedByte.toString(16).padStart(2, "0");
  }

  const varSeed    = makeId(10);
  const varPayload = makeId(10);
  const varSource  = makeId(10);
  const varIndex   = makeId(10);
  const varFunc    = makeId(10);
  const varErr     = makeId(10);
  const varKeyByte = makeId(10);
  const varByteStr = makeId(10);
  const varVal     = makeId(10);

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

function getErrorGuiLua(errorMessage: string): string {
  return `
local player = game:GetService("Players").LocalPlayer
local errGui = Instance.new("ScreenGui")
errGui.Name = "HipHubError"
errGui.ResetOnSpawn = false
errGui.DisplayOrder = 2147483647
pcall(function()
    local parentGui = player:WaitForChild("PlayerGui")
    errGui.Parent = parentGui
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 380, 0, 120)
    main.Position = UDim2.new(0.5, -190, 0.5, -60)
    main.BackgroundColor3 = Color3.fromRGB(12, 22, 34)
    main.BorderSizePixel = 0
    main.Parent = errGui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundTransparency = 1
    title.Text = "HipHub DQR - Error"
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
        `-- HipHub DQR Script Server\n-- Execute via: loadstring(game:HttpGet("${request.url}"))()`,
        {
          status: 403,
          headers: { "Content-Type": "text/plain" },
        }
      );
    }

    // ── Read all module files ──
    const dqrDir = path.join(
      process.cwd(),
      "app",
      "api",
      "script-roblox",
      "dqr"
    );

    const moduleFiles = [
      "core.lua",
      "tab_info.lua",
      "tab_farm.lua",
      "tab_boss.lua",
      "tab_esp.lua",
      "tab_move.lua",
      "tab_sell.lua",
      "tab_misc.lua",
    ];

    const modules: Record<string, string> = {};

    for (const file of moduleFiles) {
      try {
        modules[file] = fs
          .readFileSync(path.join(dqrDir, file), "utf8")
          .replace(/^\uFEFF/, "");
      } catch {
        console.error(`Failed to read DQR module: ${file}`);
        return new NextResponse(
          getErrorGuiLua(`Failed to load module: ${file}`),
          { headers: { "Content-Type": "text/plain" } }
        );
      }
    }

    // ── Bundle all modules ──
    const bundledLua = `
-- ==============================================================================
-- ⚔ HipHub — Dungeon Quest Reborn (DQR) Automation Suite
-- PlaceId: 77649408247578
-- Bundled: ${new Date().toISOString()}
-- ==============================================================================

-- [Module 1: Core — Bootstrap, UI Helpers, Tab System]
${modules["core.lua"]}

-- [Module 2: Tab — Info]
${modules["tab_info.lua"]}

-- [Module 3: Tab — Farm]
${modules["tab_farm.lua"]}

-- [Module 4: Tab — Boss]
${modules["tab_boss.lua"]}

-- [Module 5: Tab — ESP]
${modules["tab_esp.lua"]}

-- [Module 6: Tab — Move]
${modules["tab_move.lua"]}

-- [Module 7: Tab — Sell]
${modules["tab_sell.lua"]}

-- [Module 8: Tab — Misc + Init]
${modules["tab_misc.lua"]}
`;

    // ── Raw mode (debug) ──
    if (isRaw) {
      return new NextResponse(bundledLua, {
        headers: {
          "Content-Type": "text/plain",
          "Cache-Control": "no-store, no-cache, must-revalidate",
        },
      });
    }

    // ── Hash for in-memory cache ──
    const sourceHash = crypto
      .createHash("sha256")
      .update(bundledLua)
      .digest("hex");

    if (globalCache && globalCache.sourceHash === sourceHash) {
      return new NextResponse(globalCache.obfuscatedCode, {
        headers: {
          "Content-Type": "text/plain",
          "Cache-Control": "no-store, no-cache, must-revalidate",
        },
      });
    }

    // ── Obfuscate ──
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
    console.error("DQR script delivery error:", err);
    return new NextResponse(
      getErrorGuiLua("Server delivery failure. Please try again!"),
      { headers: { "Content-Type": "text/plain" } }
    );
  }
}
