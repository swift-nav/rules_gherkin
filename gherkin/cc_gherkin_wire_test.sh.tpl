#!/bin/bash
export GHERKIN_WIRE_SOCKET="{SOCKET}"

start_server() {
    ./{STEPS} &
    STEPS_PID=$!
    sleep 1
    # Verify server started successfully
    if ! kill -0 $STEPS_PID 2>/dev/null; then
        echo "Error: Failed to start wire server" >&2
        exit 1
    fi
}

STEPS_PID=""
trap "kill $STEPS_PID 2>/dev/null" EXIT
mkdir -p "${TEST_UNDECLARED_OUTPUTS_DIR}" || exit 1
TEST_FAILED=0

# NOTE: FEATURE_RUN_LIST is space-separated; feature filenames must not contain spaces.
for feature_run in {FEATURE_RUN_LIST}; do
    kill -0 $STEPS_PID 2>/dev/null || start_server
    FEATURE_PATH="${feature_run%%:*}"
    OUTPUT_FILE="${TEST_UNDECLARED_OUTPUTS_DIR}/${feature_run##*:}"
    ./{CUCUMBER_RUBY} -r $RUNFILES_DIR/{FEATURE_DIR} {ADDITIONAL_CUCUMBER_ARGS} --out="${OUTPUT_FILE}" "$RUNFILES_DIR/{FEATURE_DIR}/${FEATURE_PATH}" || TEST_FAILED=1
    cat "${OUTPUT_FILE}"
done

exit $TEST_FAILED
