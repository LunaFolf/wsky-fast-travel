AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString("WskyFastTravel_OpenSelectionMenu")
util.AddNetworkString("WskyFastTravel_Travel")
util.AddNetworkString("WskyFastTravel_Freeze")
util.AddNetworkString("WskyFastTravel_BeginTransition")

local stops = {}

local existingStops = ents.FindByClass("wsky_bus_stop")
for _, stop in pairs(existingStops) do
  local busStopNumber = table.Count(stops) + 1
  stop:SetNWInt("WskyFastTravel_BusStopNumber", busStopNumber)
  table.insert(stops, busStopNumber, stop)
end

function ENT:Initialize()
  self:SetModel("models/wsky_bus_stop/wsky_bus_stop.mdl")
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)
  self:SetUseType(SIMPLE_USE)
  -- self:SetAngles(self:GetAngles() + Angle(0,90,0))

  local phys = self:GetPhysicsObject()
  if (phys:IsValid()) then phys:Wake() end

  self:SetNWEntity("WskyBusStopCurrentUser", NULL)

  local busStopNumber = table.Count(stops) + 1
  self:SetNWInt("WskyFastTravel_BusStopNumber", busStopNumber)
  table.insert(stops, busStopNumber, self)
end

function ENT:OnRemove()
  local busStopNumber = self:GetNWInt("WskyFastTravel_BusStopNumber", nil)
  print(busStopNumber)
  if busStopNumber then table.remove(stops, busStopNumber) end
end

function ENT:Use(activator)
  net.Start("WskyFastTravel_OpenSelectionMenu")
    net.WriteInt(self:GetNWInt("WskyFastTravel_BusStopNumber"), 32)
  net.Send(activator)
end

function travel(ply, currentStop, newStop)
  if not ply then return end
  if not currentStop then return end
  if not newStop then newStop = currentStop end

  local transitionDuration = 3

  local heightOffset = Vector(0, 0, -65)

  -- Freeze user in place
  ply:SetNWBool("WskyFastTravel_HideViewModel", true)
  ply:SetMoveType(MOVETYPE_NONE)
  -- ply:SetPos(currentStop:GetPos() + Vector(150,0,50))
  ply:SetPos(currentStop:GetPos() + heightOffset + (currentStop:GetAngles():Forward() * 20))
  -- ply:SetEyeAngles(currentStop:GetAngles() + Angle((ply:GetPos()[1] - currentStop:GetPos()[1]) / 10,90,0))
  ply:SetEyeAngles(currentStop:GetAngles())
  ply:Freeze(true)

  -- Animate bus sliding in for departure
  net.Start("WskyFastTravel_BeginTransition")
    net.WriteInt(transitionDuration, 32)
  net.Send(ply)

  -- Brief pause to symbolize the player getting on the bus

  -- Animate the bus leaving

  -- Arrive at the new bus stop and unfreeze
  timer.Simple(transitionDuration, function ()
    ply:Freeze(false)
    ply:SetPos(newStop:GetPos() + heightOffset + (newStop:GetAngles():Forward() * 20))
    ply:SetEyeAngles(newStop:GetAngles())
    timer.Simple(1, function ()
      ply:SetNWBool("WskyFastTravel_HideViewModel", false)
      ply:SetMoveType(MOVETYPE_WALK)
    end)
  end)
end

net.Receive("WskyFastTravel_Travel", function (len, ply)
    local currentStopId = net.ReadInt(32)
    local newStopId = net.ReadInt(32)

    local currentStop, newStop = stops[currentStopId], stops[newStopId]

    print(currentStop, newStop)

    if (not currentStop or not newStop) then return end
    travel(ply, currentStop, newStop)
end)

net.Receive("WskyFastTravel_Freeze", function (len, ply)
    local state = net.ReadBool()
    freezePlayer(ply, state)
end)

function freezePlayer(ply, state)
  ply:Freeze(state)
end