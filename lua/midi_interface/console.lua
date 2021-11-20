local concommand = concommand
local midi

-- Generate callbacks for Derma_Query
local function midiOption(ports, i)
    return function()
        if ports[i] then
            midi.Open(i)
            piano_midi.print("Connected to device " .. ports[i])
        end
    end
end

local function midiClose()
    return function()
        if midi.IsOpened() then
            midi.Close()
            piano_midi.print("Disconnected")
        end
    end
end

concommand.Add("midi_reload", function(ply, cmd, args)
    piano_midi.print("Reloading...")
    piano_midi.load()
end)

hook.Add("piano_midi_init", "piano_midi_console", function(_midi)
    midi = _midi

    -- Pop up interface to let you select a midi device
    concommand.Add("midi_devices", function(ply, cmd, args)
        local ports = midi.GetPorts()
        local portsCount = table.Count(ports)

        if portsCount > 0 then
            piano_midi.print("Opening menu...")

            Derma_Query("Which device you would like to use?" .. (portsCount > 3 and " (Max. 3 devices)" or ""),
                "Device selection",
                "Disable", midiClose(),
                ports[0], midiOption(ports, 0),
                ports[1], midiOption(ports, 1),
                ports[2], midiOption(ports, 2)
            )
        else
            piano_midi.print("No devices connected.")
        end
    end)
    CreateConVar("midi_debug", "0", FCVAR_ARCHIVE, "Should MIDI events be printed to chat", 0, 1)
end)

