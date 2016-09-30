# Copyright (c) 2006 Red Hat, Inc. All rights reserved. This copyrighted material 
# is made available to anyone wishing to use, modify, copy, or
# redistribute it subject to the terms and conditions of the GNU General
# Public License v.2.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Author: Jan Hutar <jhutar@redhat.com>, based on work of Petr Sklenar <psklenar@redhat.com>

# The toplevel namespace within which the test lives.
TOPLEVEL_NAMESPACE=CoreOS

# The name of the package under test:
PACKAGE_NAME=Spacewalk/Installer

# The path of the test below the package:
RELATIVE_PATH=Sanity/Yum-install/spacewalk-postgresql

# Version of the Test. Used with make tag.
export TESTVERSION=1.0

# The combined namespace of the test.
export TEST=/$(TOPLEVEL_NAMESPACE)/$(PACKAGE_NAME)/$(RELATIVE_PATH)


# A phony target is one that is not really the name of a file.
# It is just a name for some commands to be executed when you
# make an explicit request. There are two reasons to use a
# phony target: to avoid a conflict with a file of the same
# name, and to improve performance.
.PHONY: all install download clean

# executables to be built should be added here, they will be generated on the system under test.
BUILT_FILES= 

# data files, .c files, scripts anything needed to either compile the test and/or run it.
FILES=$(METADATA) runtest.sh Makefile PURPOSE

run: $(FILES) build
	./runtest.sh

build: $(BUILT_FILES)
	chmod a+x ./runtest.sh

clean:
	rm -f rh-*.rpm $(BUILT_FILES)

# Include Common Makefile
include /usr/share/rhts/lib/rhts-make.include

# Generate the testinfo.desc here:
$(METADATA): Makefile
	@touch $(METADATA)
	@echo "Owner:         Jan Hutar <jhutar@redhat.com>" > $(METADATA)
	@echo "Name:          $(TEST)" >> $(METADATA)
	@echo "Path:          $(TEST_DIR)" >> $(METADATA)
	@echo "License:       GPL" >> $(METADATA)
	@echo "TestVersion:   $(TESTVERSION)" >> $(METADATA)
	@echo "Description:   Do yum installation of spacewalk-postgresql package" >> $(METADATA)
	@echo "TestTime:      2h" >> $(METADATA)
	@echo "Type:          Install" >> $(METADATA)
	@echo "RunFor:        $(PACKAGE_NAME)" >> $(METADATA)
	@echo "Architectures: i386 x86_64" >> $(METADATA)
	@echo "RhtsRequires:  test(/CoreOS/Spacewalk/Helper)" >> $(METADATA) 
	@echo "NeedProperty:  DISK >= 25" >> $(METADATA) 
	rhts-lint $(METADATA)
