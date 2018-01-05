#!/bin/bash

GROUP_PATH=./groups/

# print usage info
usage () {
	echo "usage: $0 [OPTION] [CMD]"
	echo "  -g|--group <GROUPNAME>      (all|all-rhel6|all-squeezy)"
	echo "  -n|--dry-run                don't run any command, only show them"
	echo "  -s|--silent                 don't show servernames"
	echo "  -c|--cron                   show servername only on remote output"
	echo "  -i|--stdin			use stdin, even if CMD is not empty"
	echo "  CMD                         if empty, command is expected once(!) from stdin and sent to all (EOF expected!)"
	exit
}

if [ $# -eq 0 ]; then
	usage;
fi

gflag=0
dryrunflag=0
silentflag=0
cronflag=0
stdinflag=0

# Parse the command-line options
TEMP=$(getopt -o g:nsci --long group:,dry-run,silent,cron,stdin \
	-n $0 -- "$@")

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

while true; do
	case "$1" in
	(-g|--group) gflag=1;
		case "$2" in
		("") echo "Groupname missing!"; usage; shift 2 ;;
		(*) GROUP=$2; shift 2 ;;
		esac ;;
	(-n|--dry-run) dryrunflag=1; shift ;;
	(-s|--silent) silentflag=1; shift ;;
	(-c|--cron) cronflag=1; shift ;;
	(-i|--stdin) stdinflag=1; shift ;;
	(--) shift; break ;;
	(*) echo "Internal error!" ; exit 1 ;;
	esac
done

if [[ $gflag = 0 ]]; then
	usage;
fi

## generate grouplist
#GROUP_LIST=""

### all
#if [[ "$GROUP" == "all" ]]; then
#	GROUP_LIST=`cat $GROUP_PATH/*`
#else
#	### location and type?
#	LOCATION_AND_TYPE=$(echo $GROUP |awk '/[a-z]+-[a-z]+/ { print 1 }')
#	if [[ "$LOCATION_AND_TYPE" = "1" ]]; then
#		#echo "Location and Type"
#		GROUP_LIST=$(cat $GROUP_PATH/$GROUP)
#	else
#		GROUP_LIST=$(cat $GROUP_PATH/*${GROUP}*)
#	fi
#fi

. ./lib/target.lib.sh
if [ "$GROUP" = "ALL" ]; then
	GROUP_LIST="$( cd -- "$GROUP_PATH" && \
		for d in *; do
			[ -e "$d" ] || continue
			target_getfrom . "$d"
		done | sort -u
	)"
else
	GROUP_LIST="$(target_getfrom "$GROUP_PATH" "$GROUP" | sort -u)"
fi

## initialize some vars
HOST=""
PORT=""
STDIN_TEMPFILE=""

## save stdin to file, for multiple use in loop later
## only if $@ empty!
if [ $# -eq 0 ] || [[ $stdinflag == 1 ]]; then
	STDIN_TEMPFILE=$(mktemp)
	cat /dev/stdin > $STDIN_TEMPFILE
fi

## loop through servers in group and execute specified command
for line in $GROUP_LIST; do
	case "$line" in
		('') continue ;; # ignore empty line
		('#'*) continue ;; # ignore comment line
	esac

	### get port
	HOST=$(echo "$line" |cut -d":" -f1)
	PORT=$(echo "$line" |cut -s -d":" -f2)
	if [ -z "$PORT" ]; then
		PORT=22
	fi
	ssh -p $PORT $HOST "echo 0" &>/dev/null
	CONNECT_TEST=$?
	if [ "$CONNECT_TEST" != "0" ]; then
		if [[ $silentflag == 0 && $cronflag == 0 ]]; then
			echo "WARNING: $HOST:$PORT not reachable.";
		fi
		continue
	fi
	### don't print header on "silent" parameter
	if [[ $silentflag == 0 && $cronflag == 0 ]]; then
		echo "### $line ###"
	fi

	if [ "$dryrunflag" = "1" ]; then
		if [ $# -eq 0 ] || [[ $stdinflag == 1 ]]; then
			echo "cat <STDIN> |ssh -p $PORT -T $HOST $@"
		else
			echo "ssh -p $PORT -T $HOST $@"
		fi
	else
		if [ $cronflag == 1 ]; then
			if [ $# -eq 0 ] || [[ $stdinflag == 1 ]]; then
				OUTPUT=$(cat $STDIN_TEMPFILE |ssh -p $PORT -T $HOST $@)
			else
				OUTPUT=$(ssh -p $PORT -T $HOST $@)
			fi
			if [[ "$OUTPUT" != "" ]]; then
				if [ $silentflag == 0 ]; then
					echo "### $line #######################################################################"
				fi
				IFS="$(printf '\n')"
				for line in $OUTPUT; do
					echo $line
				done
			fi
		else
			if [ $# -eq 0 ] || [[ $stdinflag == 1 ]]; then
				cat $STDIN_TEMPFILE |ssh -p $PORT -T $HOST $@
				#cat $STDIN_TEMPFILE |ssh -p $PORT -tt $HOST $@
			else
				ssh -p $PORT -T $HOST $@
				#ssh -p $PORT -tt $HOST $@
			fi
		fi
	fi
done

## cleanup
rm -f $STDIN_TEMPFILE
