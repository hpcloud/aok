VM=$(VMNAME).local

# EXTERNAL_VERSION=0.0.1
	#ext/$(EXTERNAL_VERSION) \

EXTERNAL_REPOS = \
	ext/test-simple-bash \
	ext/json-bash \

default: help

include pkg.mk

RSYNC_EXCLUDE := $(RSYNC_EXCLUDE) \
	--exclude=ext \


help:
	@echo 'Make targets:'
	@echo ''
	@echo 'sync 		Push local code to VM and restart AOK'
	@echo 'ssh		SSH into Stackato VM'
	@echo 'test-api 	Run AOK API tests'
	@echo ''

clean::
	rm -f HEAD STDOUT STDERR

distclean: clean
	rm -fr ext/

.PHONY: test
test:
	@for t in test/*.rb; do \
	    echo "# Testing: $$t"; \
	    ruby -Ilib $$t; \
	done
	@# rspec spec --pattern '**/*.rb'

.PHONY: test-api
test-api: vmname $(EXTERNAL_REPOS)
	prove $(PROVEOPT) test-api/

# Alias:
api-test: test-api

sync: rsync restart

aok: rsync stop-all migrate

rsync: vmname
	rsync -avzL ./ stackato@$(VM):/s/code/aok/ $(RSYNC_EXCLUDE)

start stop restart: vmname
	ssh stackato@$(VM) sup $@ aok

stop-all: stop
	@true

migrate:
	ssh stackato@$(VM) '(cd /s/code/aok; bundle exec rake db:drop db:create db:migrate)'

ssh: vmname
	ssh stackato@$(VM)

console:
	bundle exec irb -r './config/boot'

vmname:
ifndef VMNAME
	@echo "You need to set VMNAME. Something like this:"
	@echo
	@echo "export VMNAME=stackato-g4jx"
	@echo
	@exit 1
endif

ext/$(EXTERNAL_VERSION):
	rm -fr ext/test-simple-bash
	rm -fr ext/json.bash
	mkdir -p ext
	touch $@

ext/test-simple-bash:
	git clone git@github.com:ingydotnet/test-simple-bash $@

ext/json-bash:
	git clone git@github.com:ingydotnet/json-bash $@

export:
	@echo export VMNAME=$(VMNAME)
