#!/bin/sh

# This file fixes the permissions of the home directory so that it matches the host user's ID.
# It also enables multicast and changes directories before executing the input from docker run.

# Adapted from: http://chapeau.freevariable.com/2014/08/docker-uid.html

export ORIGPASSWD=$(cat /etc/passwd | grep rosbuild)
export ORIG_UID=$(echo $ORIGPASSWD | cut -f3 -d:)
export ORIG_GID=$(echo $ORIGPASSWD | cut -f4 -d:)

export UID=${UID:=$ORIG_UID}
export GID=${GID:=$ORIG_GID}

ARCH=`uname -i`

ORIG_HOME=$(echo $ORIGPASSWD | cut -f6 -d:)

echo "Enabling multicast..."
ifconfig eth0 multicast
echo "done."

. /etc/os-release

# We only attempt to install Connext on Ubuntu amd64
if [ "${ARCH}" = "x86_64" -a "${ID}" = "ubuntu" ]; then
    IGNORE_CONNEXTDDS=""
    ignore_rwm_seen="false"
    for arg in ${CI_ARGS} ; do
        case $arg in
            ("--ignore-rmw") ignore_rmw_seen="true" ;;
            ("-"*) ignore_rmw_seen="false" ;;
            (*) if [ $ignore_rmw_seen = "true" ] ; then [ $arg = "rmw_connextdds" ] && IGNORE_CONNEXTDDS="true" && break ; fi
        esac
    done

    echo "NOT installing Connext."
fi

echo "Fixing permissions..."
sed -i -e "s/:$ORIG_UID:$ORIG_GID:/:$UID:$GID:/" /etc/passwd
sed -i -e "s/rosbuild:x:$ORIG_GID:/rosbuild:x:$GID:/" /etc/group

chown -R ${UID}:${GID} "${ORIG_HOME}"
echo "done."

exec sudo -H -u rosbuild -E -- xvfb-run -s "-ac -screen 0 1280x1024x24" /bin/sh -c "$*"
