PORT ?= 5173

.PHONY: help dev pack push publish tag release

help:
	@printf '%s\n' \
		'Release: make pack → commit → make release' \
		'' \
		'  make dev      Serve the theme preview at localhost:$(PORT)' \
		'  make pack     Create an installable VSIX' \
		'  make push     Push main to GitHub' \
		'  make publish  Publish the extension to the VS Code Marketplace' \
		'  make tag      Create and push the committed package version tag' \
		'  make release  Pack the VSIX, push, publish and tag'

dev:
	python3 -m http.server $(PORT) --bind 127.0.0.1

pack:
	npm exec -- vsce package --no-dependencies

push:
	git push origin main

publish:
	npm exec -- vsce publish --no-dependencies

tag:
	@set -e; \
	version=$$(git show HEAD:package.json | node -p 'JSON.parse(require("node:fs").readFileSync(0, "utf8")).version ?? ""'); \
	test -n "$$version"; \
	git tag -a "$$version" -m "Release $$version"; \
	git push origin "refs/tags/$$version"

release:
	@test "$$(git branch --show-current)" = main || { echo "Release from main." >&2; exit 1; }
	@test -z "$$(git status --porcelain)" || { echo "Commit the release changes first." >&2; exit 1; }
	$(MAKE) pack
	$(MAKE) push
	@set -e; \
	version=$$(node -p 'require("./package.json").version'); \
	extension=$$(node -p 'const { publisher, name } = require("./package.json"); publisher + "." + name'); \
	npm exec -- vsce publish --packagePath "webcimes-dark-theme-$$version.vsix"; \
	echo "Waiting for $$extension@$$version on the VS Code Marketplace..."; \
	for attempt in 1 2 3 4 5 6 7 8 9 10 11 12; do \
		if listing=$$(npm exec -- vsce show "$$extension" --json 2>/dev/null) && \
			printf '%s' "$$listing" | node -e 'const listing = JSON.parse(require("node:fs").readFileSync(0, "utf8")); process.exit(listing.versions.some(({ version }) => version === process.argv[1]) ? 0 : 1);' "$$version" 2>/dev/null; then \
			exit 0; \
		fi; \
		if [ "$$attempt" -lt 12 ]; then sleep 5; fi; \
	done; \
	echo "Could not confirm Marketplace publication for $$extension@$$version. Check the listing before running make tag." >&2; \
	exit 1
	$(MAKE) tag
