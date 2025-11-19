#!/bin/bash
echo $(pwd)
./{STEPS} &
sleep 2

echo "Feature Directory: $RUNFILES_DIR + {FEATURE_DIR}"
echo $(ls -al $RUNFILES_DIR/{FEATURE_DIR})

./{CUCUMBER_RUBY} $RUNFILES_DIR/{FEATURE_DIR} 