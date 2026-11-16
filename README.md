# bmw-nftables
Modular nftables configuration for setting up machines, packaged for Arch Linux (AUR) and Debian.

## Installation

### Arch Linux
Install `bmw-nftables` from the AUR.

### Debian
Download the `.deb` from the [releases page](https://github.com/borismw/bmw-nftables/releases) and run:

```sh
sudo apt install ./bmw-nftables_X.Y.Z-1_all.deb
```

### Activate
Add this line to `/etc/nftables.conf`:

```
include "/etc/nftables/*.rules"
```

Then check and apply:

```sh
sudo nft -c -f /etc/nftables.conf && sudo systemctl reload nftables
```

## Development
- `make lint`: lint packaging scripts
- `make release`: build the reproducible source tarball in `build/`
- `make deb`: build the `.deb` in `build/deb/` (needs `debhelper`, `devscripts`)

## Release
1. Tag `main`: `git tag vX.Y.Z && git push origin vX.Y.Z`.
2. The `release` workflow builds the tarball and `.deb`, creates a draft release and opens a bump PR (PKGBUILD + `debian/changelog`).
3. Download the CI-built tarball, sign it (`gpg --detach-sign bmw-nftables-vX.Y.Z-sources.tar.gz`), upload the `.sig` to the draft and publish the release.
4. Merge the bump PR, then publish to the AUR.
