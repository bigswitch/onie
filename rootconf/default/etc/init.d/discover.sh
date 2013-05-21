#!/bin/sh

cmd="$1"

PATH=/usr/bin:/usr/sbin:/bin:/sbin

. /scripts/functions

import_cmdline

daemon="discover"

do_start() {

    # Check for any one time boot commands
    if [ -n "$onie_boot_reason" ] ; then

        # delete one time env variable
        fw_setenv -f onie_boot_reason > /dev/null 2>&1

        # Further parse boot_reason
        case "$onie_boot_reason" in
            rescue)
                echo "$daemon: Rescue mode detected.  Installer disabled." > /dev/console
                echo "** Rescue Mode Enabled **" >> /etc/issue
                exit 0
                ;;
            uninstall)
                echo "$daemon: Uninstall mode detected.  Running uninstaller." > /dev/console
                echo "** Uninstall Mode Enabled **" >> /etc/issue
                /bin/uninstaller
                exit 0
                ;;
            install)
            # pass through to discover
                true
                ;;
            *)
                log_failure_msg "$daemon: Unknown reboot command: $onie_boot_reason"
                reboot
        esac

    fi

    echo "** Installer Mode Enabled **" >> /etc/issue
    log_begin_msg "Starting: $daemon"
    start-stop-daemon -S -b -m -p /var/run/${daemon}.pid -x $daemon
    log_end_msg

}

do_stop() {
    log_begin_msg "Stopping: $daemon"
    start-stop-daemon -q -K -s TERM -p /var/run/${daemon}.pid
    killall -q $onie_installer exec_installer wget tftp 
    log_end_msg
}

case $cmd in
    start)
        do_start
        ;;
    stop)
        do_stop
        ;;
    *)
        
esac
