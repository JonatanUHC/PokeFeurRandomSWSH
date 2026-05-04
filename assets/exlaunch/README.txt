This folder stores the project's custom ExLaunch payloads that are safe to ship
with the repository.

- Each title-id subfolder contains the custom `subsdk9` used by the randomizer.
- `runtime/` contains the extra ROMFS files that ExLaunch needs at generation time.
- `subsdk9_stable` targets Eden and Yuzu-style forks; `subsdk9_ryujinx` targets Ryujinx.
- ExLaunch runtime features target Pokemon Sword/Shield update 1.3.2.
- `main.npdm` is NOT stored here and must always come from the user's own ExeFS dump.
- Do not add Nintendo dump files to this folder.
