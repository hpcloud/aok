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

INSTALLROOT=/home/stackato/stackato
DIRNAME=$(INSTALLROOT)/aok

INSTROOT=$(DESTDIR)$(prefix)$(INSTALLROOT)
INSTDIR=$(DESTDIR)$(prefix)$(DIRNAME)

RSYNC_EXCLUDE=--exclude=.git --exclude=.gitignore --exclude=Makefile --exclude=.stackato-pkg --exclude=debian --exclude=etc

all:
	@ true

install:
	mkdir -p $(INSTDIR)
	rsync -ap . $(INSTDIR) $(RSYNC_EXCLUDE)
	rsync -ap etc $(INSTROOT)

uninstall:
	rm -rf $(INSTDIR)

clean:
	@ true

test:
	rspec spec --pattern '**/*.rb'
