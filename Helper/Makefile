# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Makefile of /CoreOS/Spacewalk/Helper
#   Description: Helper utilities for Spacewalk tests
#   Authors:
#     Jan Hutar <jhutar@redhat.com>
#     Petr Sklenar <psklenar@redhat.com>
#     Garik Khachikyan <gkhachik@redhat.com>
#     Simon Lukasik <slukasik@redhat.com>
#     Pavel Novotny <pnovotny@redhat.com>
#     Martin Minar <mminar@redhat.com>
#     Dimitar Yordanov <dyordano@redhat.com>
#     Jiri Kastner <jkastner@redhat.com>
#     Pavel Studenik <pstudeni@redhat.com>
#     Lukas Hellebrandt <lhellebr@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2010 Red Hat, Inc. All rights reserved.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

export TEST=/CoreOS/Spacewalk/Helper
export TESTVERSION=1.7

BUILT_FILES=*.pyc
OTHERS_SCRIPTS=rpmfluff.py
LOCAL_PY_SCRIPTS=manage-ak.py \
               manage-channel.py \
               manage-config.py \
               manage-custominfo.py \
               manage-events.py \
               manage-errata.py \
               manage-ks.py \
               manage-org.py manage-package.py \
               manage-proxy.py \
               manage-scap.py \
               manage-sysgroups.py \
               manage-system.py \
               manage-taskomatic-org.py \
               manage-taskomatic.py \
               manage-yum-repos.py \
               manage-users.py \
               manage-abrt.py \
               manage-sync-slave.py \
               manage-sync-master.py \
               manage-custominfo.py \
               manage-search.py
LOCAL_BASH_SCRIPTS=rpm_verify_lib.sh \
               reporting.sh \
               helper-wait-for-metadata.sh \
               helper-wait-for-errata-cache.sh \
               remote.sh \
               helper-source-config.sh \
               create_first_user.sh helper-log-movement.sh \
               cat_rhnplugin_repo_cache.sh \
               helper-rhn-register.sh get_rhel_channel_name.sh \
               spacewalk-install.sh \
               spacewalk_logs.sh \
               helper-get-distro-name.sh \
               get_rhel_kickstart_name.sh \
               helper-install-with-support-repos.sh \
               helper-tcpdump-external.sh \
               helper-rhn-satellite.sh \
               helper-satellite-sync.sh \
               helper-rhn-satellite-activate.sh \
               helper-up2date-cert-to-rhnpushrc.sh \
               helper-sm-reg.sh \
               helper-get-updater.sh \
               tttt-perf.sh
LOCAL_SCRIPTS=$(LOCAL_BASH_SCRIPTS) $(LOCAL_PY_SCRIPTS)
FETCHED_SCRIPTS=$(OTHERS_SCRIPTS)
SCRIPTS=$(FETCHED_SCRIPTS) $(LOCAL_SCRIPTS)
FILES=$(METADATA) Makefile $(SCRIPTS) runtest.sh
WGET=wget --no-verbose

.PHONY: all build install download clean rpmfluff.py
all: pep8 tag bkradd
run: $(FILES) build
	./runtest.sh

build: $(SCRIPTS) runtest.sh
	python -m py_compile *.py
	bash -n *.sh
	chmod a+x $(SCRIPTS) runtest.sh

verify:
	rpm -q python-autopep8 && autopep8 *.py -i

refresh:
	echo "Make refresh is no longer needed. You just build the package!"

clean:
	rm -f *~ $(BUILT_FILES) *.rpm
	rm -f $(FETCHED_SCRIPTS)
cvsup: clean
	cvs up


# Download rpmfluff.py from CVS
rpmfluff.py:
	rm -f rpmfluff.py
	./get-rpmfluff.sh

include /usr/share/rhts/lib/rhts-make.include

$(METADATA): Makefile build
	@echo "Owner:           Lukas Hellebrandt <lhellebr@redhat.com>" > $(METADATA)
	@echo "Name:            $(TEST)" >> $(METADATA)
	@echo "TestVersion:     $(TESTVERSION)" >> $(METADATA)
	@echo "Path:            $(TEST_DIR)/Helper" >> $(METADATA)
	@echo "Description:     Helper utilities for Spacewalk tests" >> $(METADATA)
	@echo "Type:            Helper" >> $(METADATA)
	@echo "TestTime:        20m" >> $(METADATA)
	@echo "RunFor:          Spacewalk/Helper" >> $(METADATA)
	@echo "Requires:        wget mailx traceroute tcpdump" >> $(METADATA)
	@echo "Provides:        rh-tests-Spacewalk-Helper" >> $(METADATA)
	@echo "Priority:        Normal" >> $(METADATA)
	@echo "License:         GPLv2" >> $(METADATA)
	@echo "Confidential:    no" >> $(METADATA)
	@echo "Destructive:     no" >> $(METADATA)

	rhts-lint $(METADATA)
