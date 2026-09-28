SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
ROOT := $(CURDIR)
WORKSPACE := $(ROOT)/MacPowerScheduler.xcworkspace
SCHEME := MacPowerScheduler
DERIVED := $(ROOT)/.build/DerivedData
APP := $(DERIVED)/Build/Products/Debug/MacPowerScheduler.app
XCODE := xcodebuild -workspace "$(WORKSPACE)" -scheme "$(SCHEME)" -derivedDataPath "$(DERIVED)" -destination 'platform=macOS'

.PHONY: generate build run test-unit test-adapters test-coverage coverage-report test-tools test-strict test-snapshots record-snapshots test-cli check format lint install-hooks analyze build-universal archive verify-release notarize package-release
generate:
	python3 Tools/generate_project.py
build:
	$(XCODE) -configuration Debug build
run: build
	open "$(APP)"
test-unit:
	swift test --package-path Package --skip 'PowerSchedule(Adapter|Snapshot)Tests'
test-adapters:
	swift test --package-path Package --filter PowerScheduleAdapterTests
test-coverage:
	python3 Tools/unit_coverage.py
COVERAGE_RUN ?= latest
coverage-report:
	python3 Tools/unit_coverage.py --reuse "$(COVERAGE_RUN)"
test-tools:
	PYTHONOPTIMIZE=1 python3 -m unittest discover -s Tools/tests -v
test-strict: test-unit test-adapters test-tools test-snapshots test-cli
test-snapshots:
	MPS_RECORD_SNAPSHOTS=0 swift test --package-path Package --filter PowerScheduleSnapshotTests
record-snapshots:
	MPS_RECORD_SNAPSHOTS=1 swift test --package-path Package --filter PowerScheduleSnapshotTests
test-cli: build
	python3 Tools/verify_cli.py "$(APP)/Contents/MacOS/powerschedulectl"
format:
	swiftformat --cache ignore --config .swiftformat App Helper CLI Package Tools
lint:
	bash Tools/lint.sh
install-hooks:
	git config --local core.hooksPath Tools/git-hooks
analyze:
	$(XCODE) -configuration Debug analyze
check: lint test-coverage test-adapters test-tools test-snapshots build analyze
build-universal:
	$(XCODE) -configuration Release ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO build
	python3 Tools/verify_bundle.py .build/DerivedData/Build/Products/Release/MacPowerScheduler.app
RELEASE_VARIANT ?= universal
archive:
	bash Tools/release.sh archive "$(RELEASE_VARIANT)"
verify-release:
	bash Tools/release.sh verify "$(RELEASE_VARIANT)"
notarize:
	bash Tools/release.sh notarize "$(RELEASE_VARIANT)"
package-release:
	bash Tools/release.sh package "$(RELEASE_VARIANT)"
