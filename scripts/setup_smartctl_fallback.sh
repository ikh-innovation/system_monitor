#!/bin/bash
# One-time setup for the smartctl fallback of hdd_monitor.py: NVMe temperature on kernels
# without nvme hwmon (< 5.5, e.g. Ubuntu 18.04). Does nothing when the kernel reports it in sysfs.
#
# - installs smartmontools without recommends (they pull in postfix)
# - installs a sudoers rule that allows only the exact command hdd_monitor runs
#
# usage: sudo ./setup_smartctl_fallback.sh [user]    (default: the user who ran sudo)
set -eu

TARGET_USER=${1:-${SUDO_USER:-}}
SUDOERS_FILE=/etc/sudoers.d/system-monitor-smartctl

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo $0 [user]" >&2
    exit 1
fi
if [ -z "$TARGET_USER" ] || ! id -u "$TARGET_USER" > /dev/null 2>&1; then
    echo "Unknown user '$TARGET_USER': pass the user that runs the ROS nodes" >&2
    exit 1
fi
if grep -qsx nvme /sys/class/hwmon/hwmon*/name; then
    echo "Kernel $(uname -r) reports NVMe temperature in sysfs: smartctl fallback not needed"
    exit 0
fi

if [ ! -x /usr/sbin/smartctl ]; then
    apt-get update
    apt-get install -y --no-install-recommends smartmontools
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cat > "$tmp" << EOF
# system_monitor hdd_monitor: NVMe temperature through smartctl (kernels without nvme hwmon)
Cmnd_Alias NVME_TEMP = /usr/bin/timeout 5 /usr/sbin/smartctl -i -A /dev/nvme[0-9]
Defaults!NVME_TEMP !syslog, !pam_session
$TARGET_USER ALL=(root) NOPASSWD: NVME_TEMP
EOF
visudo -c -q -f "$tmp"
install -m 0440 -o root -g root "$tmp" "$SUDOERS_FILE"
echo "Installed $SUDOERS_FILE for user $TARGET_USER"

for dev in /dev/nvme[0-9]; do
    [ -e "$dev" ] || continue
    echo "Check $dev as $TARGET_USER:"
    sudo -u "$TARGET_USER" sudo -n /usr/bin/timeout 5 /usr/sbin/smartctl -i -A "$dev" \
        | grep -E '^(Model Number|Temperature):' || echo "  no temperature from $dev" >&2
done
