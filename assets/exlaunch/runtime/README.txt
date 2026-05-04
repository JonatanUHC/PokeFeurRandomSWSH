This folder contains the versioned ExLaunch runtime ROMFS extras required by
CustomSwShRandomizer.ps1 when runtime features are enabled.

Files expected here:
- bin/message/English/script/string_format.dat
- bin/message/English/script/string_format.tbl
- bin/script/amx/custom_message.amx
- bin/script/amx/dex_animations.amx
- bin/script/amx/early_bike.amx
- bin/script/amx/randomizer_pc_menu.amx

These files are copied into the generated output ROMFS when ExLaunch runtime
features are active. Keep this folder in the repository so a clean GitHub clone
does not depend on local research artifacts.
