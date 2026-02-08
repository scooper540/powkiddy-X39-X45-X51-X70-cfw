#!/bin/sh

# run test.sh in upgrade disk
if [ -f /var/upgrade/test.sh ]; then
    /var/upgrade/test.sh
fi
