#!/bin/bash
# Use GHERKIN_WIRE_SOCKET environment variable if set, otherwise fall back to default
SOCKET="${GHERKIN_WIRE_SOCKET:-{SOCKET}}"
{SERVER} -u "$SOCKET"
