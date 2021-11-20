AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("KeyboardInstrumentNetwork")

function ENT:Initialize()
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:DrawShadow(true)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
    self:InitializeAfter()
end

function ENT:InitializeAfter()
end

local function HandleRollercoasterAnimation(vehicle, player)
    return player:SelectWeightedSequence(ACT_GMOD_SIT_ROLLERCOASTER)
end

function ENT:SetupChair(vecmdl, angmdl, vecvehicle, angvehicle)
    // Chair Model
    self.ChairMDL = ents.Create("prop_physics_multiplayer")
    self.ChairMDL:SetModel(self.ChairModel)
    self.ChairMDL:SetParent(self)
    self.ChairMDL:SetPos(self:GetPos() + vecmdl)
    self.ChairMDL:SetAngles(angmdl)
    self.ChairMDL:DrawShadow(false)
    self.ChairMDL:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
    self.ChairMDL:Spawn()
    self.ChairMDL:Activate()
    self.ChairMDL:SetOwner(self)
    local phys = self.ChairMDL:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:Sleep()
    end
    self.ChairMDL:SetKeyValue("minhealthdmg", "999999")
    
    // Chair Vehicle
    self.Chair = ents.Create("prop_vehicle_prisoner_pod")
    self.Chair:SetModel("models/nova/airboat_seat.mdl")
    self.Chair:SetKeyValue("vehiclescript","scripts/vehicles/prisoner_pod.txt")
    self.Chair:SetPos(self.ChairMDL:GetPos() + vecvehicle)
    self.Chair:SetParent(self.ChairMDL)
    self.Chair:SetAngles(angvehicle)
    self.Chair:SetNotSolid(true)
    self.Chair:SetNoDraw(true)
    self.Chair:DrawShadow(false)
    self.Chair:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
    self.Chair.HandleAnimation = HandleRollercoasterAnimation
    self.Chair:SetOwner(self)
    self.Chair:Spawn()
    self.Chair:Activate()
    local phys = self.Chair:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:Sleep()
    end
end

local function HookChair(ply, ent)
    local inst = ent:GetOwner()
    if IsValid(inst) && inst.Base == "kbd_instrument_base" then
        if !IsValid(inst.Owner) then
            inst:AddOwner(ply)
            return true
        else
            if inst.Owner == ply then
                return true
            end
        end
        return false
    end
    return true
end

// Quick fix for overriding the instrument chair seating
hook.Add("CanPlayerEnterVehicle", "InstrumentChairHook", HookChair)
hook.Add("PlayerUse", "InstrumentChairModelHook", HookChair)

function ENT:Use(ply)
    if !IsValid(self.Owner) then
        self:AddOwner(ply)
    end
end

function ENT:AddOwner(ply)
    if !IsValid(self.Owner) then
        net.Start("KeyboardInstrumentNetwork")
            net.WriteEntity(self)
            net.WriteInt(INSTNET_USE, 4)
        net.Send(ply)
        ply.EntryPoint = ply:GetPos()
        ply.EntryAngles = ply:EyeAngles()
        self.Owner = ply
        ply:EnterVehicle(self.Chair)
        self.Owner:SetEyeAngles(Angle(25, 90, 0))
    end
end

function ENT:RemoveOwner()
    if IsValid(self.Owner) then
        net.Start("KeyboardInstrumentNetwork")
            net.WriteEntity(nil)
            net.WriteInt(INSTNET_USE, 3)
        net.Send(self.Owner)
        self.Owner:ExitVehicle(self.Chair)
        self.Owner:SetPos(self.Owner.EntryPoint)
        self.Owner:SetEyeAngles(self.Owner.EntryAngles)
        self.Owner = nil
    end
end

function ENT:NetworkNote(semitone, velocity)
    if IsValid(self.Owner) then
        net.Start("KeyboardInstrumentNetwork")
            net.WriteEntity(self)
            net.WriteInt(INSTNET_HEAR, 3)
            net.WriteUInt(semitone, 8)
            net.WriteUInt(velocity, 8)
        net.Broadcast()
    end
end

// Returns the approximate "fitted" number based on linear regression.
function math.Fit(val, valMin, valMax, outMin, outMax)
    return (val - valMin) * (outMax - outMin) / (valMax - valMin) + outMin
end 

net.Receive("KeyboardInstrumentNetwork", function(length, client)
    local ent = net.ReadEntity()
    local cmd = net.ReadInt(3)

    // When the player plays notes
    if cmd == INSTNET_PLAY then
        // Filter out non-instruments
        if IsValid(ent) && ent.Base == "kbd_instrument_base" then
            // Check if the player is actually the owner of the instrument
            if IsValid(ent.Owner) && client == ent.Owner then
                // Gather note
                local semitone = net.ReadUInt(8)
                local velocity = net.ReadUInt(8)
                // Send it!!
                ent:NetworkNote(semitone, velocity)

                if (velocity > 0) then
                    // Offset the note effect
                    local pos = math.Fit(semitone, 1, ent.SemitonesNum, -3.8, 4)
                    // Note effect
                    local eff = EffectData()
                    eff:SetOrigin(client:GetPos() + Vector(-15, pos * 10, -5))
                    util.Effect("musicnotes", eff, true, true)
                end
            end
        end
    end
end)

concommand.Add("instrument_leave", function(ply, cmd, args)
    if #args < 1 then return end // no ent id
    // Get the instrument
    local entid = args[1]
    local ent = ents.GetByIndex(entid)

    // Filter out non-instruments
    if IsValid(ent) && ent.Base == "kbd_instrument_base" then
        // Leave instrument
        if IsValid(ent.Owner) && ply == ent.Owner then
            ent:RemoveOwner()
        end
    end
end)