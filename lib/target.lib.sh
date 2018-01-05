gettargetsfiles() {
        local group="${1%/}";shift;
	group="$(dirname -- "$group")/$(basename -- "$group" .d)"
	group="${group#./}"
	group="${group%/}"
	case "$group" in
		(*::*) group="$(printf '%s\n' "$group" | sed -e 's,::,.d/,g')" ;;
	esac

	local notfound=true
        if [ -f "$group" ]; then
		echo "$group"
		notfound=false
	fi
	if [ -d "$group.d" ]; then
		find "$group.d" -type f && notfound=false
	fi
	if $notfound; then return 1; fi
}

gettargetsfrom() {
	local GROUP_PATH="$1";shift;
	for f in $(cd -- "$GROUP_PATH" && gettargetsfiles "$1"); do
		[ -f "$GROUP_PATH/$f" ] || continue
		cat -- "$GROUP_PATH/$f"
	done
}

