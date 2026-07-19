# Store the absolute path of the Makefile so scripts can be called regardless of what the current directory is.
mkfile_path := $(realpath $(dir $(firstword $(MAKEFILE_LIST))))

define git_tag_with_prefix
$(eval $@_TAGPREFIX = $(addsuffix *,$(1)))$(shell git describe --tags --abbrev=0 --match '${$@_TAGPREFIX}')
endef

.PHONY: ci lint linst-sh clean release pkgver

tag_prefix := v

pkgver_prefixed := $(call git_tag_with_prefix,$(tag_prefix))
pkgver = $(pkgver_prefixed:$(tag_prefix)%=%)

pkgname := bmw-nftables

src_directory := $(mkfile_path)/src/$(pkgname)/

clean:
	rm $(pkgname)-*-sources.tar.gz

ci: lint

lint-sh:
	shfmt -i 4 -d "$(mkfile_path)/src/bmw-nftables-aur/bmw-nftables-rules.install"
	shfmt -i 4 -d "$(mkfile_path)/src/bmw-nftables-aur/PKGBUILD"
	shellcheck --shell=bash --exclude=SC2034,SC2154,SC2164 "$(mkfile_path)/src/bmw-nftables-aur/PKGBUILD"

lint: lint-sh

pkgver:
	@echo "$(pkgver)"

release: $(pkgname)-v$(pkgver)-sources.tar.gz

$(pkgname)-v$(pkgver)-sources.tar.gz:
	# Reproducible archives https://gist.github.com/stokito/c588b8d6a6a0aee211393d68eea678f2
	tar \
	  --directory $(src_directory) \
	  --sort=name \
	  --mtime 'UTC 1980-02-01' \
	  --owner=0 --group=0 --numeric-owner \
	  --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
	  --use-compress-program 'gzip -9' \
	  -cf "$(pkgname)-v$(pkgver)-sources.tar.gz" "etc/"
	TZ=UTC touch -a -m -t 198002010000.00 "$(pkgname)-v$(pkgver)-sources.tar.gz"

