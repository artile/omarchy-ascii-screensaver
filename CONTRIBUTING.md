# Contributing

## Development

```bash
./install.sh          # PATH-hook install into a throwaway HOME for testing
./uninstall.sh --purge
omarchy plugin validate .   # on an Omarchy machine
```

Keep `vendor/ascii.rest` in sync with npm when bumping scenes. Do not add symlinks inside the repo (`omarchy plugin validate` rejects them).

When refreshing the idle clone from upstream Omarchy, re-apply the single change in `Service.qml` (`launchScreensaver` → `ascii-screensaver-launch`) and keep the file header credit.

## Publishing checklist

1. Push a public GitHub repository (suggested name: `omarchy-ascii-screensaver`).
2. Confirm `manifest.json` id `io.github.artile.ascii-screensaver` is free on [omarchyplugins.com](https://omarchyplugins.com).
3. Update README clone URLs if the owner/name differs from `artile/omarchy-ascii-screensaver`.
4. Optionally add `preview.png` (screenshot of a scene fullscreen).
5. Open a marketplace submission issue only after you explicitly want it listed — see README “Catalog notes”. Do not open theme PRs for this package.
