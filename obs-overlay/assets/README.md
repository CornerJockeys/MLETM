# OBS Overlay Assets

Production replacements go here.

```text
assets/
├── teams/       # high-resolution transparent franchise logos
└── wordmarks/   # transparent team-name PNGs / wordmarks
```

The initial renderer temporarily references the existing `prod-plugin/assets/teams/` files so the layout works before the new artwork is ready.

When the new assets are added, update each team's `logo` and `wordmark` paths in `../js/state.js`.

Keep transparent padding consistent between teams so logos and wordmarks do not visually jump between matchups.
