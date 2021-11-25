ENT.Base        = "base_anim"
ENT.Type        = "anim"
ENT.PrintName   = "Keyboard Instrument Base"

ENT.Model       = Model("models/fishy/furniture/piano.mdl")
ENT.ChairModel  = Model("models/fishy/furniture/piano_seat.mdl")

ENT.SoundDir    = "generic/instruments/piano/note_"
ENT.SoundExt    = ".wav"

INSTNET_USE     = 1
INSTNET_HEAR    = 2
INSTNET_PLAY    = 3

//ENT.SoundNames = {}
//ENT.Keys = {}
ENT.ControlKeys = { 
    [KEY_TAB] = function(inst, bPressed)
        if not bPressed then return end
        RunConsoleCommand("instrument_leave", inst:EntIndex())
    end,
                
    [KEY_SPACE] = function(inst, bPressed) 
        if not bPressed then return end
        inst:ToggleSheetMusic()
    end,
    
    [KEY_LEFT] = function(inst, bPressed)
        if not bPressed then return end
        inst:SheetMusicBack()
    end,
    [KEY_RIGHT] = function(inst, bPressed)
        if not bPressed then return end
        inst:SheetMusicForward()
    end,
    
    [KEY_LCONTROL] = function(inst, bPressed)
        if not bPressed then return end
        inst:CtrlMod() 
    end,
    [KEY_RCONTROL] = function(inst, bPressed)
        if not bPressed then return end
        inst:CtrlMod() 
    end,
    
    [KEY_LSHIFT] = function(inst, bPressed)
        inst:ShiftMod()
    end,
}

function ENT:GetSoundPath(snd)
    if (snd == nil) or (snd == "") then
        return nil
    end
    return self.SoundDir .. snd .. self.SoundExt
end

if SERVER then
    function ENT:Intiailize()
        self:PrecacheSounds()
    end

    function ENT:PrecacheSounds()
        if self.SoundNames then
            for soundName in self.SoundNames do
                util.PrecacheSound(self:GetSoundPath(soundName))
            end
        end
    end
end

hook.Add("PhysgunPickup", "NoPickupInsturmentChair", function(ply, ent)
    local inst = ent:GetOwner()
    if IsValid(inst) and (inst.Base == "kbd_instrument_base") then
        return false
    end
end)