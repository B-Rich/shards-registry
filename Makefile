CRYSTAL_BIN ?= $(shell which crystal)
SOURCES := registry.cr $(shell find app libs -type f)

ifdef RELEASE
	CRFLAGS := $(CRFLAGS) --release
endif

.PHONY: tasks doc routes notes test assets stats
.PHONY: db db_migrate db_up db_down db_redo db_load db_dump


all: bin/registry

run: all
	bin/env.sh bin/registry

bin/registry: $(SOURCES)
	$(CRYSTAL_BIN) build $(CRFLAGS) registry.cr -o bin/registry

db:
	$(CRYSTAL_BIN) run bin/db

db_migrate:
	$(CRYSTAL_BIN) run bin/db -- migrate

db_up:
	$(CRYSTAL_BIN) run bin/db -- up VERSION=$(VERSION)

db_down:
	$(CRYSTAL_BIN) run bin/db -- down VERSION=$(VERSION)

db_redo:
	$(CRYSTAL_BIN) run bin/db -- redo STEP=$(STEP)

db_load:
	$(CRYSTAL_BIN) run bin/db -- load

db_dump:
	$(CRYSTAL_BIN) run bin/db -- dump

tasks:
	@echo "Available tasks:"
	@grep --color=never -e "^[a-z]\+:" Makefile | sed s/://g

doc: db_migrate
	$(CRYSTAL_BIN) docs registry.cr

routes:
	$(CRYSTAL_BIN) config/routes.cr

src_files := $(wildcard ./*.cr) $(wildcard app/*.cr) $(wildcard app/**/*.cr) $(wildcard config/*.cr) $(wildcard config/**/*.cr)
notes:
	@grep -oT -E '#\s+(NOTE|TODO|OPTIMIZE|FIXME).+' $(src_files) |\
		sed 's/:#\s*//g' |\
		awk -F'\t' '{print $$2" ("$$1")"}' | cut -b 2-

test_files := $(wildcard test/*_test.cr) $(wildcard test/**/*_test.cr) $(wildcard test/**/**/*_test.cr)
test:
	$(CRYSTAL_BIN) run $(test_files) -- --verbose

assets:
	node_modules/.bin/bower install
	node_modules/.bin/gulp

#fixtures_files := $(wildcard test/fixtures/*.cr) $(wildcard test/fixtures/**/*.cr)
#lines := $(shell cat $(src_files) | grep -v "^$$" | wc -l )
#tests := $(shell cat $(fixtures_files) $(test_files) | grep -v '^$$' | wc -l )

#stats:
#	@echo " code: $(lines)"
#	@echo "tests: $(tests)"
#	@echo -n "ratio: `echo 'scale=6; 1.0 / $(lines) * $(tests)' | bc -q`"
#	@echo " (code-to-test)"
