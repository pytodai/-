#!/bin/bash
# This script runs AFTER pg_ctl start, so we can modify the config and reload
# It needs to be called from a SQL init script that has server already running
echo "Init script executed but postgres might not be ready yet"
