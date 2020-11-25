ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Bus Stop"
ENT.Author = "Whiskee"
ENT.Contact = "dev@whiskee.me"
ENT.Category = "Wsky Fast Travel"
ENT.Spawnable = true

if CLIENT then
  function createBasicFrame (width, height, title, draggable)
    local Frame = vgui.Create( "DFrame" )
    Frame:SetSize(width, height)
    Frame:SetTitle( "" )
    Frame:SetVisible(true)
    Frame:SetDraggable(draggable)
    Frame:ShowCloseButton(false)
    Frame:Center()
    Frame.Paint = function(self, w, h)
      draw.RoundedBox(0, 0, 0, w, h, Color(65, 65, 65, 225))
      draw.RoundedBox(0, 0, 0, w, 32, Color(0, 0, 0, 225))
      draw.SimpleText(title, "DermaLarge", 4, 0)
    end
    Frame:MakePopup()

    local CloseBtn = vgui.Create("DButton", Frame)
    CloseBtn:SetText( "X" )
    CloseBtn:SetTextColor( Color(255, 255, 255) )
    CloseBtn:SetPos(width - 32, 0)
    CloseBtn:SetSize(32, 32)
    CloseBtn.Paint = function(self, w, h)
      draw.RoundedBox(0, 0, 0, w, h, Color(0,0,0,255))
    end
    CloseBtn.DoClick = function()
      Frame:Close()
    end

    return Frame
  end
end