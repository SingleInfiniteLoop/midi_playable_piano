# MIDI Playable Piano
This is the LUA script library used in the [MIDI Playable Piano](https://steamcommunity.com/sharedfiles/filedetails/?id=2659606719) Garry's Mod addon.  
It integrates Starfall hooks and functions for the MIDI input interface of the addon.  

## Requirements
Clients are required to have [GMCL MIDI](https://github.com/FPtje/gmcl_midi) binary LUA module in order to use MIDI devices.

See [Installation](https://github.com/FPtje/gmcl_midi#installation) section of the GMCL MIDI README file.

## Console Commands
- `midi_devices` - This allows you to select the MIDI device you wish to use.
- `midi_debug [0|1]` - This boolean ConVar enables/disables debug prints in console, which show information about midi events as they occur.
- `midi_reload` - This simply reloads the addon, and searches for GMCL MIDI binary LUA module again, allowing users to add the file without relog.
- `sv_midi_sf_note_quota` - This is a server-side quota for starfall playNote calls (per second) (def 30).

## Starfall
- The `MIDI` hook is now available on client-side, using the following syntax:  
`nil GM:MIDI( float time, int command, int note, int velocity )`  
or more often:  
`hook.add("MIDI", "my_unique_identifier", function(time, command, note, velocity) end)`
- Entities now have the `boolean Entity:IsInstrument()` and `boolean Entity:playNote(int note)` functions.  
`Entity:playNote` takes a note index from `1-61` and returns a success boolean.  
**NOTE:** `Entity:playNote` is limited by the `sv_midi_sf_note_quota` ConVar.  
**NOTE2:** `Entity:playNote` also requires the calling player have PhysGun access to the instrument entity.

## References
This addon is based on the original [Playable Piano](https://steamcommunity.com/sharedfiles/filedetails/?id=104548572) addon. Its source code can be found at [GitHub](https://github.com/macdguy/playablepiano).

It also uses a modified version of the [CFC MIDI Interface](https://github.com/CFC-Servers/cfc_midi_interface) LUA script library to handle MIDI input.

