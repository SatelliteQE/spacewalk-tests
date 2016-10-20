#!/usr/bin/python
# author: Pavel Studenik

from fabric.api import env, get, run, cd

env.user = "root"
env.password = "spacewalk"

env.hosts = open("config/hosts.ini").read().split()

# Run test on remote guest. For example:
# fab run_test:test_name=/CoreOS/Spacewalk/Others/Example
def run_test(test_name):
    with cd("/mnt/tests/"):
            run("make build -C ./%s" % test_name)
            run("make -C ./%s" % test_name)


def build_all():
    with cd("/mnt/tests/"):
        repo_path = "/var/repos/beaker-test"
        run("for it in $( find ./ -name Makefile ); do make rpm -C $( dirname ${it}); done")
        run("mkdir -p %s; for it in $( find ./ -name 'spacewalk-test*.rpm'); do mv $it %s; done" % (repo_path, repo_path))
        run("createrepo %s" % repo_path)
        run("dnf config-manager --add %s && dnf repolist" % repo_path)
        run("echo 'gpgcheck=0' >> /etc/yum.repos.d/var_repos_beaker-test.repo")
