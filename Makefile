#
# Makefile for stackato-aok
#
# Used solely by packaging systems.
# Must support targets "all", "install", "uninstall".
#
# During the packaging install phase, the native packager will
# set either DESTDIR or prefix to the directory which serves as
# a root for collecting the package files.
#
# The resulting package installs in /home/stackato/stackato,
# is not intended to be relocatable.
#

NAME=stackato-aok

INSTALLHOME=/home/stackato
INSTALLROOT=$(INSTALLHOME)/stackato
DIRNAME=$(INSTALLROOT)/code/aok

INSTHOME=$(DESTDIR)$(prefix)$(INSTALLHOME)
INSTROOT=$(DESTDIR)$(prefix)$(INSTALLROOT)
INSTDIR=$(DESTDIR)$(prefix)$(DIRNAME)

RSYNC_EXCLUDE=--exclude=.git* --exclude=Makefile --exclude=.stackato-pkg --exclude=debian --exclude=etc
VM=$(VMNAME).local

all:
	@ true

install:
	mkdir -p $(INSTDIR)
	rsync -ap . $(INSTDIR) $(RSYNC_EXCLUDE)
	if [ -d etc ] ; then rsync -ap etc $(INSTROOT) ; fi
	chown -Rh stackato.stackato $(INSTHOME)

uninstall:
	rm -rf $(INSTDIR)

clean:
	@ true

test:
	rspec spec --pattern '**/*.rb'

sync:
	rsync -avzL ./ stackato@$(VM):/s/code/aok/ $(RSYNC_EXCLUDE)
	ssh stackato@$(VM) sup restart aok

ssh:
	ssh stackato@$(VM)

console:
	bundle exec irb -r './config/boot'
