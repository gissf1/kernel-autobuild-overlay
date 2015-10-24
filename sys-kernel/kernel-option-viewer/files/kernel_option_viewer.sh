#!/bin/bash

. /etc/init.d/functions.sh

NEW_OPTIONS=$( readlink -f "$1" )
KDIR=$( dirname $NEW_OPTIONS )
FILESDIR=$( dirname $0 )
TMPF="/tmp/kernel_options.$$.$RANDOM"

RENDERER="text"

VIEWER=""
HELPER=""
BG_TYPE=0
# try to find an X11 viewer if we're running X11
if [[ ! -z "$DISPLAY" ]]; then
	OK=0
	# try to confirm we have a valid X11 connection
	which xwininfo 2>&1 >/dev/null && xwininfo -root >/dev/null && OK=1
	[[ $OK -eq 0 ]] && which xprop 2>&1 >/dev/null && xprop -root > /dev/null && OK=1
	[[ $OK -eq 0 ]] && which xhost 2>&1 >/dev/null && xhost > /dev/null && OK=1
	if [[ $OK -eq 1 ]]; then
		# now figure out how to best display the data
		for APP in firefox google-chrome chromium konqueror epiphany midori dillo elinks links ; do
			which $APP 2>&1 >/dev/null && VIEWER=$APP && RENDERER=html && break
		done
		if [[ -z "$VIEWER" ]]; then
			for APP in kwrite gedit ; do
				which $APP 2>&1 >/dev/null && VIEWER=$APP && break
			done
		fi
		if [[ -z "$VIEWER" ]]; then
			for APP in konsole gnome-terminal rxvt xterm ; do
				which $APP 2>&1 >/dev/null && HELPER=$APP && break
			done
		fi
		if [[ -n "$VIEWER" ]]; then
			BG_TYPE=1
		fi
	fi
fi
if [[ -z "$VIEWER" ]]; then
	for APP in vim less more ; do
		which $APP 2>&1 >/dev/null && VIEWER=$APP && break
	done
	if [[ -z "$HELPER" ]]; then
		for APP in screen openvt ; do
			which $APP 2>&1 >/dev/null && HELPER=$APP && BG_TYPE=1 && break
		done
	fi
	VIEWER="$HELPER $VIEWER"
fi
if [[ -z "$VIEWER" ]]; then
	eerror "No viewers available to list new options."
	RET=1
	rm $TMPF
else
	case $RENDERER in
		text)
			gawk -f $FILESDIR/build_new_options_list.awk -v KDIR="$KDIR" $NEW_OPTIONS > $TMPF
			;;
		cleantext)
			gawk -f $FILESDIR/build_new_options_list.awk -v KDIR="$KDIR" -v FMT="cleantext" $NEW_OPTIONS > $TMPF
			;;
		html)
			TMPF="$TMPF.html"
			gawk -f $FILESDIR/build_new_options_list.awk -v KDIR="$KDIR" -v FMT="text" $NEW_OPTIONS | $FILESDIR/kernel_menu_to_html.py > $TMPF
			;;
		
	esac
	RET=0
	case $BG_TYPE in
		0) $VIEWER $TMPF
			RET=$?
			rm $TMPF
			;;
		1) ( $VIEWER $TMPF ; rm $TMPF ) &
			;;
		*) eerror "Unknown BG_TYPE: $BG_TYPE"
			RET=1
			rm $TMPF
			;;
	esac
fi
exit $RET
