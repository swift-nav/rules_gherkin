#!/bin/bash
echo FOOOOO
echo $(pwd)
echo ""
echo $(pwd)/{STEPS}
echo {CUCUMBER_RUBY}
echo $RUNFILES_DIR/{FEATURE_DIR}
echo BAAAR

./{STEPS} &
sleep 2
ss -tulpn | grep 3902


./{CUCUMBER_RUBY} -v -r $RUNFILES_DIR/{FEATURE_DIR}/support $RUNFILES_DIR/{FEATURE_DIR} 