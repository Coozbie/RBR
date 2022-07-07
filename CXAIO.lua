local SCRIPT_NAME, VERSION, LAST_UPDATE = "CXAIO", "1.0.1", "07/07/2022"
_G.CoreEx.AutoUpdate("https://raw.githubusercontent.com/Coozbie/RBR/main/CXAIO.lua", VERSION)
module(SCRIPT_NAME, package.seeall, log.setup)
clean.module(SCRIPT_NAME, clean.seeall, log.setup)

local Player = _G.Player

local supportedChamp = {
    Zed = true,
}

if supportedChamp[Player.CharName] then
    LoadEncrypted("CX"..Player.CharName)
end