include("shared.lua")

local aVar = nil
local transitionDraw = false
local transitionStartTime, transitionEndTime, transitionHalfTime = nil, nil, nil

function ENT:Draw()
  self:DrawModel()

  -- standard cam2d3d shite
  local camWidth, camHeight = 150, 40
  local pos = self:GetPos()
  local ang = self:GetAngles()

  ang:RotateAroundAxis(self:GetAngles():Forward(), 90)
  pos:Add(Vector(0, 0, 70))
  cam.Start3D2D(pos, ang, 0.5)

    surface.SetFont("DermaLarge")
    local text ="Bus Stop #" .. self:GetNWInt("WskyFastTravel_BusStopNumber", "~")
    local textWidth, textHeight = surface.GetTextSize(text)

    local widthOffset = math.max(0, textWidth - camWidth)
    local heightOffset = math.max(0, textHeight - camHeight)

    if widthOffset then widthOffset = widthOffset + 8 end
    if heightOffset then heightOffset = heightOffset + 8 end

    local newWidth, newHeight = camWidth + widthOffset, camHeight + heightOffset
    local x, y = newWidth / 2 * -1, 0

    draw.RoundedBox(0, x, y, newWidth, newHeight, Color(0, 0, 0, 80))
    draw.SimpleText(text, "DermaLarge", x + newWidth / 2, newHeight / 2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  
    cam.End3D2D()
end

function ENT:Initialize()
  aVar = LocalPlayer():GetName()
  print(aVar)
end

-- UI shit, move this into it's own file at some point before things get too messy

local width, height = ScrW() / 2, ScrH() / 2
local margin = 8
local padding = 8
local titleBarHeight = 32

function getStops(removeCurrentStop, currentStopID)
  local stops = ents.FindByClass("bus_stop")
  local output = {}
  for _, stop in pairs(stops) do
    stop.BusStopNumber = stop:GetNWInt("WskyFastTravel_BusStopNumber")
    if removeCurrentStop then
      if stop.BusStopNumber ~= currentStopID then table.insert(output, stop) end
    else
      table.insert(output, stop)
    end
  end
  return output
end

function drawTransitionEffect(self)

end

net.Receive("WskyFastTravel_OpenSelectionMenu", function ()
  local curBusStopNumber = net.ReadInt(32)
  local frame = createBasicFrame(width, height, "Bus Stops", false)
  local stops = getStops(true, curBusStopNumber)
  if table.Count(stops) < 1 then frame:Close() return end

  local scroller = vgui.Create("DScrollPanel", frame)
  scroller:SetPos(0,titleBarHeight)
  scroller:SetSize(width, height - titleBarHeight)

  for _, stop in pairs(stops) do
    local stopPanel = vgui.Create("DButton", scroller)
    stopPanel:Dock(TOP)
    stopPanel:SetHeight(100)
    stopPanel:DockMargin(padding, padding, padding, 0)
    stopPanel:SetText("")
    stopPanel.Paint = function (self, w, h)
      draw.RoundedBox(0, 0, 0, w, h, Color(180, 180, 180))
      draw.SimpleText("Bus Stop #" .. stop.BusStopNumber, "DermaLarge", 0, h / 2, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    stopPanel.DoClick = function ()
      frame:Close()
      net.Start("WskyFastTravel_Travel")
        net.WriteInt(curBusStopNumber, 32)
        net.WriteInt(stop.BusStopNumber, 32)
      net.SendToServer()
    end
  end
end)

net.Receive("WskyFastTravel_BeginTransition", function ()
  local transitionDuration = net.ReadInt(32)
  transitionStartTime = SysTime()
  transitionEndTime = SysTime() + transitionDuration * 1.5
  transitionHalfTime = transitionStartTime + ((transitionEndTime - transitionStartTime) / 2)
  transitionDraw = true
  timer.Simple(transitionDuration * 0.35, function ()
    LocalPlayer():EmitSound("bus_doors.wav", 75, 140, 0.1)
  end)
  timer.Simple(transitionDuration * 0.70, function ()
    LocalPlayer():EmitSound("bus_bell_ring.wav", 75, 100, 0.1)
  end)
end)

-- End of UI shite

hook.Add("PreDrawViewModel", "WskyFastTravel_HideViewModel", function ()
  return LocalPlayer():GetNWBool("WskyFastTravel_HideViewModel", false)
end)

hook.Add("HUDPaint", "WskyFastTravel_FadeOut", function ()
  if transitionDraw then
    local width, height = ScrW(), ScrH()
    local buffer = 1
    local alpha = 255
    local mult = 1
    if SysTime() < transitionHalfTime + buffer then
      alpha = Lerp(transitionHalfTime - SysTime(), 128, 0)
      mult = 2
    elseif SysTime() > transitionHalfTime + buffer then
      alpha = Lerp(transitionEndTime - SysTime(), 0, 300)
    else
    end

    draw.RoundedBox(0, 0,0, width, height, Color(0, 0, 0, alpha * mult))

    if transitionStartTime > transitionEndTime then transitionDraw = false end
  end
end)