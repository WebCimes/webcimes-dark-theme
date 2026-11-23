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
	version=$$(node -p 'require("./package.json").version'); \
	npm exec -- vsce publish --packagePath "webcimes-dark-theme-$$version.vsix"
	$(MAKE) tag
