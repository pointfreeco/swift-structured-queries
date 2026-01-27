SWIFT_VERSION = 6.2

format:
	swift format . --recursive --in-place
	find README.md Sources -name '*.md' -exec sed -i '' -e 's/ *$$//g' {} \;

docker-build:
	docker run \
		--rm \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift:$(SWIFT_VERSION) \
		bash -c "apt update && apt -y install libsqlite3-dev && swift build"

docc-preview:
	swift package --disable-sandbox preview-documentation \
		--target StructuredQueriesCore \
		--enable-experimental-overloaded-symbol-presentation

.PHONY: format
