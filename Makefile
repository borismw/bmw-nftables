# Store the absolute path of the Makefile so scripts can be called regardless of what the current directory is.
mkfile_path := $(realpath $(dir $(firstword $(MAKEFILE_LIST))))

define git_tag_with_prefix
$(eval $@_TAGPREFIX = $(addsuffix *,$(1)))$(shell git describe --tags --abbrev=0 --match '${$@_TAGPREFIX}')
endef

.PHONY: ci lint lint-sh clean release pkgver deb

tag_prefix := v

pkgver_prefixed := $(call git_tag_with_prefix,$(tag_prefix))
pkgver = $(pkgver_prefixed:$(tag_prefix)%=%)

pkgname := bmw-nftables

BUILD_DIR := $(mkfile_path)/build
SRC_DIR := $(mkfile_path)/src
DEB_DIR := $(BUILD_DIR)/deb
DEB_SRC := $(DEB_DIR)/$(pkgname)-$(pkgver)
SRC_FILES := $(shell find $(SRC_DIR) -type f)

$(BUILD_DIR):
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR)

ci: lint

lint-sh:
	shfmt -i 4 -d "$(mkfile_path)/package/archlinux/bmw-nftables.install"
	shfmt -i 4 -d "$(mkfile_path)/package/archlinux/PKGBUILD"
	shfmt -i 4 -d "$(mkfile_path)/package/debian/debian/postinst"
	shellcheck --shell=sh "$(mkfile_path)/package/debian/debian/postinst"
	shellcheck --shell=bash --exclude=SC2034,SC2154,SC2164 "$(mkfile_path)/package/archlinux/PKGBUILD"

lint: lint-sh

pkgver:
	@echo "$(pkgver)"

release: $(BUILD_DIR)/$(pkgname)-v$(pkgver)-sources.tar.gz

$(BUILD_DIR)/$(pkgname)-v$(pkgver)-sources.tar.gz: $(SRC_FILES) | $(BUILD_DIR)
	# Reproducible archives https://gist.github.com/stokito/c588b8d6a6a0aee211393d68eea678f2
	tar \
	  --directory $(SRC_DIR) \
	  --sort=name \
	  --mtime 'UTC 1980-02-01' \
	  --owner=0 --group=0 --numeric-owner \
	  --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
	  --use-compress-program 'gzip -9n' \
	  -cf "$@" "etc/"
	TZ=UTC touch -a -m -t 198002010000.00 "$@"

# Builds the .deb from the release tarball. If debian/changelog lags behind the
# version (e.g. on a tag before the bump PR is merged), the build copy gets a
# changelog entry for $(pkgver); the repo file is left untouched.
deb: $(BUILD_DIR)/$(pkgname)-v$(pkgver)-sources.tar.gz
	rm -rf $(DEB_DIR)
	mkdir -p $(DEB_SRC)
	tar -xzf "$<" -C $(DEB_SRC)
	cp -r $(mkfile_path)/package/debian/debian $(DEB_SRC)/
	chmod +x $(DEB_SRC)/debian/rules $(DEB_SRC)/debian/postinst
	cd $(DEB_SRC) && if [ "$$(dpkg-parsechangelog -SVersion)" != "$(pkgver)-1" ]; then \
	  DEBEMAIL="52957119+borismw@users.noreply.github.com" DEBFULLNAME="borismw" \
	  dch -b -v "$(pkgver)-1" --distribution unstable --force-distribution "Release $(pkgver)."; fi
	cd $(DEB_SRC) && dpkg-buildpackage -us -uc -b
