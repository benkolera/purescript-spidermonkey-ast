default: build doc
all: build doc test

MODULE = SpiderMonkeyAST

build: lib/$(MODULE).js
build-tests: $(TESTSOUT)
externs: lib/$(MODULE).externs.purs
deps: node_modules bower_components
doc: README.md

BOWER_DEPS = $(shell find bower_components/purescript-*/src -name '*.purs' -type f | sort)
SRC = $(shell find src -name '*.purs' -type f | sort)
TESTS = $(shell [ -d test ] && find test -name '*.purs' -type f | sort)
TESTSOUT = $(TESTS:test/%.purs=built-tests/%.js)

BOWER = node_modules/.bin/bower
ISTANBUL = node_modules/.bin/istanbul
MOCHA = node_modules/.bin/_mocha
MOCHA_OPTS = --inline-diffs --check-leaks --reporter dot
NPM = $(shell command -v npm || { echo "npm not found."; exit 1; })
PSC = $(shell command -v psc || { echo "PureScript compiler (psc) not found."; exit 1; })
PSCDOCS = $(shell command -v psc-docs || command -v docgen)

lib/$(MODULE).js: bower_components $(SRC)
	@mkdir -p '$(@D)'
	$(PSC) --verbose-errors \
	  --module $(MODULE) \
	  --browser-namespace exports \
	  $(BOWER_DEPS) $(SRC) \
	  > lib/$(MODULE).js

.PHONY: default all build externs deps doc clean test build-tests

lib/$(MODULE).externs.purs: bower_components $(SRC)
	@mkdir -p '$(@D)'
	$(PSC) --verbose-errors \
	  --module $(MODULE) \
	  --codegen $(MODULE) \
	  --externs lib/$(MODULE).externs.purs \
	  $(BOWER_DEPS) $(SRC) \
	  > /dev/null

README.md: lib/$(MODULE).externs.purs
	@mkdir -p '$(@D)'
	$(PSCDOCS) lib/$(MODULE).externs.purs >'$@'

built-tests/%.js: test/%.purs bower_components test-helper.purs
	@mkdir -p '$(@D)'
	$(PSC) --verbose-errors --module Tests \
	  $(BOWER_DEPS) test-helper.purs '$<' \
	  >'$@'

node_modules:
	$(NPM) install

bower_components: node_modules
	$(BOWER) install

test: node_modules $(TESTSOUT) lib/$(MODULE).js
	[ -d test ] && $(ISTANBUL) cover --root lib $(MOCHA) -- $(MOCHA_OPTS) -- built-tests
clean:
	rm -rf lib built-tests coverage bower_components node_modules
