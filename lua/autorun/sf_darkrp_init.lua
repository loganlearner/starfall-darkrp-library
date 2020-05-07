if SERVER then
    AddCSLuaFile("sf_darkrp/request_handling.lua")
end

if CLIENT then
    include("sf_darkrp/request_handling.lua")
end