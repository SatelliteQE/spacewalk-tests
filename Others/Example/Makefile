# Author: Author <email>

# The toplevel namespace within which the test lives.
TOPLEVEL_NAMESPACE=CoreOS

# The name of the package under test:
PACKAGE_NAME=Spacewalk/

# The path of the test below the package:
RELATIVE_PATH=Others/Example

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
FILES=$(METADATA) runtest.sh Makefile

run: $(FILES) build
	./runtest.sh

build: $(BUILT_FILES)
	chmod a+x runtest.sh 

clean:
	rm -f *~ *.rpm $(BUILT_FILES)

# Include Common Makefile
include /usr/share/rhts/lib/rhts-make.include

# Generate the testinfo.desc here:
$(METADATA): Makefile
	@touch $(METADATA)
	@echo "Owner:         Name of author <email>" > $(METADATA)
	@echo "Name:          $(TEST)" >> $(METADATA)
	@echo "Path:          $(TEST_DIR)" >> $(METADATA)
	@echo "License:       GPL" >> $(METADATA)
	@echo "TestVersion:   $(TESTVERSION)" >> $(METADATA)
	@echo "Description:   Example test" >> $(METADATA)
	@echo "TestTime:      1h" >> $(METADATA)
	@echo "RunFor:        $(PACKAGE_NAME)" >> $(METADATA)
	@echo "RhtsRequires:  test(/CoreOS/Spacewalk/Helper)" >> $(METADATA)
	@echo "Architectures: i386 x86_64" >> $(METADATA)
	rhts-lint $(METADATA)
