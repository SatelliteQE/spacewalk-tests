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
# Author: Simon Lukasik

TOPLEVEL_NAMESPACE=CoreOS
PACKAGE_NAME=Spacewalk/Installer
RELATIVE_PATH=Sanity/Spacewalk-setup-postgresql

export TESTVERSION=20

export TEST=/$(TOPLEVEL_NAMESPACE)/$(PACKAGE_NAME)/$(RELATIVE_PATH)


.PHONY: all install download clean

BUILT_FILES= 

FILES=$(METADATA) runtest.sh Makefile PURPOSE answer-file

run: $(FILES) build
	./runtest.sh
build: $(BUILT_FILES)
	chmod a+x ./runtest.sh
clean:
	rm -f $(BUILT_FILES)

include /usr/share/rhts/lib/rhts-make.include

$(METADATA): Makefile
	@touch $(METADATA)
	@echo "Owner:         Jan Hutar <jhutar@redhat.com>" > $(METADATA)
	@echo "Name:          $(TEST)" >> $(METADATA)
	@echo "Path:          $(TEST_DIR)" >> $(METADATA)
	@echo "License:       GPL" >> $(METADATA)
	@echo "TestVersion:   $(TESTVERSION)" >> $(METADATA)
	@echo "Description:   Spacewalk setup with postgresql backend" >> $(METADATA)
	@echo "TestTime:      1h" >> $(METADATA)
	@echo "Type:          Install" >> $(METADATA)
	@echo "RunFor:        $(PACKAGE_NAME)" >> $(METADATA)
	@echo "Architectures: i386 x86_64" >> $(METADATA)
	@echo "Requires:      tcpdump wget" >> $(METADATA)
	@echo "RhtsRequires:  test(/CoreOS/Spacewalk/Helper)" >> $(METADATA) 
	rhts-lint $(METADATA)
