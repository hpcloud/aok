#
# Makefile for stackato-aok
#
# Also used by packaging systems.
# Must support targets "all", "install", "uninstall".
#
# During the packaging install phase, the native packager will
# set either DESTDIR or prefix to the directory which serves as
# a root for collecting the package files.
#
# The resulting package installs in /home/stackato/stackato,
# is not intended to be relocatable.
#

# Packaging specific variables
NAME = stackato-aok

INSTALLHOME = /home/stackato
INSTALLROOT = $(INSTALLHOME)/stackato
DIRNAME = $(INSTALLROOT)/code/aok

INSTHOME = $(DESTDIR)$(prefix)$(INSTALLHOME)
INSTROOT = $(DESTDIR)$(prefix)$(INSTALLROOT)
INSTDIR = $(DESTDIR)$(prefix)$(DIRNAME)


# Development variables
RSYNC_EXCLUDE = \
	--exclude=.git* \
	--exclude=Makefile \
	--exclude=.stackato-pkg \
	--exclude=debian \
	--exclude=etc \
	--exclude=ext \

VM=$(VMNAME).local

EXTERNAL_REPOS = \
	ext/test-simple-bash \
	ext/json-bash \

default: help

help:
	@echo 'Make targets:'
	@echo ''
	@echo 'sync 		Push local code to VM and restart AOK'
	@echo 'ssh		SSH into Stackato VM'
	@echo 'test-api 	Run AOK API tests'
	@echo ''

install:
	mkdir -p $(INSTDIR)
	rsync -ap . $(INSTDIR) $(RSYNC_EXCLUDE)
	if [ -d etc ] ; then rsync -ap etc $(INSTROOT) ; fi
	chown -Rh stackato.stackato $(INSTHOME)

uninstall:
	rm -rf $(INSTDIR)

clean:
	rm -fr ext/

.PHONY: test
test:
	@for t in test/*.rb; do \
	    echo "# Testing: $$t"; \
	    ruby -Ilib $$t; \
	done
	@# rspec spec --pattern '**/*.rb'

test-api: vmname $(EXTERNAL_REPOS)
	prove $(PROVEOPT) test/api/

sync: vmname rsync restart

rsync: vmname
	rsync -avzL ./ stackato@$(VM):/s/code/aok/ $(RSYNC_EXCLUDE)

start stop restart:
	ssh stackato@$(VM) sup $@ aok


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

ext/test-simple-bash:
	git clone git@github.com:ingydotnet/test-simple-bash $@

ext/json-bash:
	git clone git@github.com:ingydotnet/json-bash $@
