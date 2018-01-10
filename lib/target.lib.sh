target_files() {
	local group="${1%/}";shift;
	group="$(dirname -- "$group")/$(basename -- "$group" .list)"
	group="${group#./}"
	group="${group%/}"
#	case "$group" in
#		(*::*) group="$(printf '%s\n' "$group" | sed -e 's,::,/,g')" ;;
#	esac

	local notfound=true
	if [ -f "$group.list" ]; then
		echo "$group.list"
		notfound=false
	fi
	if [ -d "$group" ]; then
		find "$group" -type f -name '*.list' || notfound=false
	fi
	if $notfound; then return 1; fi
}

target_getfrom() {
	local GROUP_PATH="$1";shift;
	for f in $(cd -- "$GROUP_PATH" && target_files "$1"); do
		[ -f "$GROUP_PATH/$f" ] || continue
		cat -- "$GROUP_PATH/$f"
	done
}

# non recursive
target_getonefrom() {
	local GROUP_PATH="$1";shift;
	[ ! -f "$GROUP_PATH/$1.list" ] || cat -- "$GROUP_PATH/$1.list"
}

target_short2long() {
        sed -e 's,,\.list$,g'
}
                    
target_long2short() {
        sed -e 's,\.list$,,g'
}


