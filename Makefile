VM=$(AOK_API_URL)

EXTERNAL_VERSION=0.0.6

EXTERNAL_REPOS = \
	ext/test-more-bash \
	ext/test-tap-bash \
	ext/bashplus \
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
ifndef AOK_API_URL
	@echo "You need to set AOK_API_URL. Something like this:"
	@echo
	@echo "export AOK_API_URL=stackato-g4jx.local"
	@echo
	@exit 1
endif

ext/$(EXTERNAL_VERSION):
	rm -fr ext
	mkdir -p ext
	touch $@

$(EXTERNAL_REPOS): ext/$(EXTERNAL_VERSION)
	git clone http://git-mirrors.activestate.com/github.com/ingydotnet/$(@:ext/%=%) $@

export:
	@echo export VMNAME=$(VMNAME)

truststore:
	echo | openssl s_client -connect $(VM):443 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > cert.pem
	rm -f truststore.jks
	keytool -import -file cert.pem -keystore truststore.jks -storepass aaaaaa -alias $(VM)
	rm -f cert.pem

# Test targets

# Runs tests assuming everything has been setup on the machine.
unit-test:
	bundle exec rspec spec/unit

# Runs tests assuming a Sentinel-based install is on the machine.
config-ci:
	sed -i.bak s/^BUNDLE_WITHOUT:/#BUNDLE_WITHOUT:/ .bundle/config
	bundle install
