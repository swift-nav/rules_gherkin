#!/bin/bash
echo FOOOOO
echo "script filepath: $0"
echo "script location: $(dirname "$0")"
echo ""
echo "pwd:"
echo $(pwd)
echo ""
echo $(pwd)/{STEPS}
echo {CUCUMBER_RUBY}
echo $RUNFILES_DIR/{FEATURE_DIR}
echo BAAAR

./{STEPS} &
sleep 1
ss -tulpn | grep 3902

echo "LS"
ls -al examples/Calc
echo "=="
ls -al examples/Calc/features
echo "=="
ls -al examples/Calc/features/support
echo "=="
ls -al examples/Calc/features/step_definitions
echo "---"
./{CUCUMBER_RUBY} -v -r examples/Calc examples/Calc