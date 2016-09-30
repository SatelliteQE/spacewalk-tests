#!/usr/bin/python
# author: Pavel Studenik

from fabric.api import env, get, run, cd

env.hosts = [""]
env.user = "root"
env.password = "spacewalk"

env.hosts = open("config/hosts.ini").read().split()

# Run test on remote guest. For example:
# fab run_test:test_name=/CoreOS/Spacewalk/Others/Example
def run_test(test_name):
	with cd("/mnt/tests/"):
		run("make build -C ./%s" % test_name)
		run("make -C ./%s" % test_name)