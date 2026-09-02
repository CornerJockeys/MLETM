# PROD External Overlay Folder

This directory documents the user-editable presentation folder that MLE TM PROD creates in Openplanet plugin storage at runtime. It is a template only; production overrides should not be edited inside the packaged `.op` plugin.

Use `Plugins > MLE TM PROD - Open Overlay Folder` or the operator/test panel to open the live folder.

Expected runtime structure:

```text
Overlay/
├── theme.json
├── README.txt
├── teams/
│   ├── Dodgers.png
│   ├── Flames.png
│   ├── Hive.png
│   ├── Hurricanes.png
│   ├── Jets.png
│   ├── Sabres.png
│   ├── Spectre.png
│   └── Wizards.png
└── branding/
    └── MLETM.png
```

Missing or invalid override assets fall back to bundled PROD assets. Use the plugin's safe reload control after editing files.
