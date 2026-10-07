# Personal Helium fork

Josh's fork of [imputnet/helium-macos](https://github.com/imputnet/helium-macos).
Everything personal lives in `personal/`, so merging upstream stays conflict-free.

## First time (on the Mac)

```sh
git clone --recurse-submodules https://github.com/joshbilson/helium-macos.git ~/Projects/helium-macos
cd ~/Projects/helium-macos
personal/bootstrap.sh   # checks Xcode 26 + ~120GB free, installs Homebrew deps and .venv
personal/build.sh       # several hours the first time; output: build/*.dmg
```

Open the `.dmg` and drag Helium into Applications. The build is unsigned, but it runs without
Gatekeeper warnings because you built it locally (nothing downloaded it, so it isn't quarantined).

## Staying up to date

Chromium ships security fixes every couple of weeks. When Helium cuts a release:

```sh
personal/sync-upstream.sh
personal/build.sh --clean
```

## Making your own changes

Changes to Chromium are quilt patches. See [docs/building.md](../docs/building.md#development-build-and-environment):
`source dev.sh && he setup`, then `quilt new`, edit, `quilt refresh`, `he unmerge`, and commit.
Put Mac-only patches in `patches/` and add them to its `series` file.
