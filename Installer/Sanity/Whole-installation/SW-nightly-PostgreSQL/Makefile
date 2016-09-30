# Copyright (c) 2016 Red Hat, Inc. All rights reserved. This copyrighted material 
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
# Author: Jan Pazdziora


# The toplevel namespace within which the test lives.
TOPLEVEL_NAMESPACE=CoreOS

# The name of the package under test:
PACKAGE_NAME=Spacewalk/Installer

# The path of the test below the package:
RELATIVE_PATH=Sanity/Whole-installation/SW-nightly-PostgreSQL

# Version of the Test. Used with make tag.
export TESTVERSION=1.0

# The combined namespace of the test.
export TEST=/$(TOPLEVEL_NAMESPACE)/$(PACKAGE_NAME)/$(RELATIVE_PATH)


.PHONY: all install download clean

# executables to be built should be added here, they will be generated on the system under test.
BUILT_FILES=

# data files, .c files, scripts anything needed to either compile the test and/or run it.
FILES=$(METADATA) runtest.sh Makefile PURPOSE answer-file

run: $(FILES) build
	./runtest.sh

build: $(BUILT_FILES)
	chmod a+x ./runtest.sh

clean:
	rm -f *~ *.rpm $(BUILT_FILES)

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
	@echo "Description:   Installation of Spacewalk nightly on PostgreSQL" >> $(METADATA)
	@echo "TestTime:      4h" >> $(METADATA)
	@echo "Type:          Install" >> $(METADATA)
	@echo "RunFor:        $(PACKAGE_NAME)" >> $(METADATA)
	@echo "Architectures: i386 x86_64" >> $(METADATA)
	@echo "RhtsRequires:  test(/CoreOS/Spacewalk/Helper)" >> $(METADATA)
	@echo "RhtsRequires:  test(/CoreOS/Spacewalk/Installer/Sanity/SW-setup-firewall)" >> $(METADATA)
	@echo "RhtsRequires:  test(/CoreOS/Spacewalk/Installer/setup-repos/SWnightly)" >> $(METADATA)
	@echo "RhtsRequires:  test(/CoreOS/Spacewalk/PostgreSQL/setup-server-and-user)" >> $(METADATA)
	@echo "RhtsRequires:  test(/CoreOS/Spacewalk/Installer/Sanity/Yum-install/spacewalk-postgresql)" >> $(METADATA)
	@echo "RhtsRequires:  test(/CoreOS/Spacewalk/Installer/Sanity/Spacewalk-setup-postgresql)" >> $(METADATA)
	@echo "Requires:      tcpdump wget mailx" >> $(METADATA)
	rhts-lint $(METADATA)
