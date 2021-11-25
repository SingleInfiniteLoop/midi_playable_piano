piano_midi = {}

include("midi_interface/console.lua")

local table = table

function piano_midi.sendNote(instrument, note, velocity)
    if not instrument.RegisterNoteEvent then
        error("Invalid instrument entity.")
    end
    if note < 1 or note > instrument.SemitonesNum then
        error("Note out of range. (1-" .. instrument.SemitonesNum .. ")")
    end
    instrument:RegisterNoteEvent(note, velocity)
end

-- To string everything and add tabs, as normal print would
local function printPre(addNewl, ...)
    local d = {...}
    local last = #d
    local out = {}

    for k, v in ipairs(d) do
        table.insert(out, tostring(v))

        if k ~= last then
            table.insert(out, "\t")
        end
    end
    if addNewl then
        table.insert(out, "\n")
    end
    return unpack(out)
end

-- Print functions that prefix "MIDI" with colour
function piano_midi.print(...)
    MsgC(Color(0, 255, 255), "Piano MIDI: ", Color(220, 220, 220), printPre(true, ...))
end

function piano_midi.printChat(...)
    chat.AddText(Color(0, 255, 255), "Piano MIDI: ", Color(220, 220, 220), printPre(false, ...))
end

function piano_midi.eventHook(time, command, note, velocity, ...)
    if not command then return end
    local code = midi.GetCommandCode(command)
    local name = midi.GetCommandName(command)
    -- Zero velocity NOTE_ON substitutes NOTE_OFF
    if name == "NOTE_ON" and velocity == 0 then
        name = "NOTE_OFF"
    end
    -- Do debug print if enabled
    local cVar = GetConVar("midi_debug")
    if cVar and cVar:GetBool() then
        -- The code is a byte (number between 0 and 254).
        piano_midi.print(" = == EVENT = = =")
        piano_midi.print("Time:\t", time)
        piano_midi.print("Code:\t", code)
        piano_midi.print("Channel:\t", midi.GetCommandChannel(command))
        piano_midi.print("Name:\t", name)
        piano_midi.print("Parameters", note, velocity, ...)
    end
    -- Get instrument entity
    local instrument = LocalPlayer().Instrument
    if midi and IsValid(instrument) then
        if (name == "NOTE_ON" or name == "NOTE_OFF") and
           (note > 35) and (note <= (35 + instrument.SemitonesNum)) then
            piano_midi.sendNote(instrument, note - 35, velocity)
        end
    end
end

function piano_midi.load()
    -- If file exists (windows, macosx or linux)
    if file.Exists("lua/bin/gmcl_midi_osx.dll", "MOD") or
       file.Exists("lua/bin/gmcl_midi_win32.dll", "MOD") or
       file.Exists("lua/bin/gmcl_midi_win64.dll", "MOD") or
       file.Exists("lua/bin/gmcl_midi_linux.dll", "MOD") or
       file.Exists("lua/bin/gmcl_midi_linux64.dll", "MOD") then
        piano_midi.print("GMCL MIDI module detected!")
        require("midi") -- Import the library
        if midi then -- Check it succeeded
            piano_midi.printChat("GMCL MIDI module initialised. Use console commands midi_devices and midi_debug [0|1] to use.")
            hook.Add("MIDI", "midiPlayablePiano", piano_midi.eventHook)
            -- Tell others it worked
            hook.Run("piano_midi_init", midi)
        else
            print("Failed to initialise GMCL MIDI module.")
        end
    end
end

piano_midi.load()
