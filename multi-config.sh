#!/bin/sh

set -e

. ./lib/target.lib.sh

GROUP_PATH="./groups"

if [ $# -eq 0 ]; then
	set -- --help
	reterr=1
else
	reterr=0
fi
LISTGROUPNAMES=false
RECURSIVE=true
while [ $# -gt 0 ]; do
	case "$1" in
	(-h|--help)
		echo >&2 "Usage: $0 [-l|-c] [--] [ALL|<groupname[.]>]"
		echo >&2 "You should try $0 -l"
		exit ${reterr:-0}
	;;
	('-l'|'--list') LISTGROUPNAMES=true;;
	('-c'|'--content') LISTGROUPNAMES=false;;
	('--') shift;break;;
	(*) break;;
	esac
	shift
done

case "$1" in
	(*.) RECURSIVE=false  ; a1="${1%.}";shift; set -- "$a1" "$@" ;;
	(*)  RECURSIVE=true ;;
esac

if ${LISTGROUPNAMES:-false}; then
		if [ "${1:-ALL}" = "ALL" ]; then
			(
				cd -- "$GROUP_PATH" && \
				for x in *; do
					case "$x" in
						(*'.list') [ -f "$x" ] || continue ;;
						(*) [ -d "$x" ] || continue ;;
					esac
					target_files "$x"
				done
			) | target_long2short
		else
			if ${RECURSIVE}; then
				(cd -- "$GROUP_PATH" && target_files "$1") | target_long2short || exit 1
			else
				(cd -- "$GROUP_PATH" && [ -f "$1.list" ] && echo "$1" || true)
			fi
		fi
else
		if [ "${1:-ALL}" = "ALL" ]; then
			(
				cd -- "$GROUP_PATH" && \
				for x in *; do
					case "$x" in
						(*'.list') [ -f "$x" ] || continue ;;
						(*) [ -d "$x" ] || continue ;;
					esac
					target_files . "$x" || true
				done
			)
		else
			if ${RECURSIVE}; then
				target_getfrom "$GROUP_PATH" "$1"
			else
				target_getonefrom "$GROUP_PATH" "$1"
			fi
		fi
fi
