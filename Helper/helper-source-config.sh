# Transfer default and custom variables to the test

. /usr/share/beakerlib/beakerlib.sh

export RHTESTDIR="/etc/rhtest"

# Source tests defaults.conf:
if [ -f defaults.conf ]; then
  . defaults.conf || rlFail "Config file './defaults.conf' sourced"
fi

# When run from WebUI without any test_param, test might prepare:
if [ -f /tmp/defaults.conf ]; then
  . /tmp/defaults.conf || rlFail "Config file '/tmp/defaults.conf' sourced"
fi

# Transfer custom variables from TEST_PARAM_CONFIG to the test
if [ -n "$TEST_PARAM_CONFIG" ]; then
  TEST_PARAM_CONFIG=$( helper_get "$TEST_PARAM_CONFIG" | tail -n 1 )
  . $TEST_PARAM_CONFIG || rlFail "Config file '$TEST_PARAM_CONFIG' sourced" $?
  /bin/cp -f $TEST_PARAM_CONFIG /tmp/defaults.conf || rlFail "/bin/cp -f $TEST_PARAM_CONFIG /tmp/defaults.conf"
fi

# Satellite tests may benefit from python libraries within the helper 
if [ "$PYTHONPATH" == "" ]; then
  export PYTHONPATH=".:/usr/local/lib/python:/mnt/tests/CoreOS/Spacewalk/Helper"
elif [[ ! "$PYTHONPATH" =~ "/mnt/tests/CoreOS/Spacewalk/Helper" ]]; then
  export PYTHONPATH="$PYTHONPATH:/mnt/tests/CoreOS/Spacewalk/Helper"
fi

