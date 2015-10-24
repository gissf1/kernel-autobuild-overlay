#!/usr/bin/gawk
# KDIR should be the kernel directory with .config to check

@load "time"

function findConfigOption(opt,   m,t) {
	if (match(opt, /^  HOST(CC|LD)  |^scripts\/kconfig\/conf /, m)) {
		#print "Skipping line: " opt
		return
	}
	if (!match(opt, /^CONFIG_(.*)$/, m)) {
		print "Failed to mangle config option"
		return
	}
	opt = m[1]
	FINDVARS[opt]=opt
}

function findSRCARCH(   file,LINE) {
	file=KDIR "/.config"
	SRCARCH=""
	while ((getline LINE < file) > 0) {
		if (match(LINE, /^CONFIG_ARCH_DEFCONFIG="arch\/(.*)\/configs\/.*"$/, m)) {
			SRCARCH=m[1]
		}
	}
	if (SRCARCH == "") {
		print "Unable to find SRCARCH in " file
	}
}

function parseKconfig(file, prefix,    KCONFIGLINE,m,m2,t,t2,readuntil,menu,menudepth,setMenuConfig,setChoice) {
	readuntil=""
	menudepth=0
	setMenuConfig=""
	#print "Starting search in: " file
	while ((getline KCONFIGLINE < file) > 0) {
		if (readuntil > "") {
			if (match(KCONFIGLINE, readuntil)) {
				readuntil = ""
			} else {
				continue
			}
		} else if (match(KCONFIGLINE, /^#|^$|^mainmenu|^comment/)) {
			continue
		} else if (setMenuConfig > "" && match(KCONFIGLINE, /^\s*(bool|tristate|int|string)( "(.*)")?/, m)) {
			#print "     Setting MenuConfig line: " KCONFIGLINE
			if (m[1] == "string" && m[2] == "") {
				t=setChoice
				MENUCONFIG[setMenuConfig]=t
			} else {
				t = m[3]
				MENUCONFIG[setMenuConfig]=t
			}
			if (setMenuConfig in FINDVARS) {
				for(i=menudepth-1; i>=0; i--) {
					t = menu[i] "\t" t
				}
				#print "Found target option path: " t
				FINDVARS[setMenuConfig]=prefix t
			}
			setMenuConfig=""
		} else if (setChoice == 1 && match(KCONFIGLINE, /^\s*(bool|prompt|tristate)\s+(.*)($| if )/, m)) {
			#print "     Setting Choice line: " KCONFIGLINE
			if (match(m[2], /^(["'])(.*)(["'])$/, m2) && m2[1] == m2[3]) m[2]=m2[2];
			setChoice=m[2]
			if (menu[menudepth-1] == "choice")
				menu[menudepth-1] = setChoice
		} else if (setMenuConfig > "" || setChoice == 1) {
			if (match(KCONFIGLINE, /^\s*(depends on|default|select) /, m)) continue;
			print "Read unexpected Kconfig line: " KCONFIGLINE
			print "                      Status: " setMenuConfig " / " setChoice
		} else if (match(KCONFIGLINE, /^\s*config\s+(.*)$/, m)) {
			#print "Read Kconfig config line: " KCONFIGLINE
			if (m[1] in FINDVARS) {
				t=m[1]
				#print "Found target option: " t
				setMenuConfig=t
			}
		} else if (match(KCONFIGLINE, /^menuconfig (.*)$/, m)) {
			#print "Read Kconfig menuconfig line: " KCONFIGLINE
			setMenuConfig=m[1]
		} else if (match(KCONFIGLINE, /^choice$/, m)) {
			#print "Read Kconfig choice line: " KCONFIGLINE
			setChoice=1
			menu[menudepth] = "choice"
			menudepth++
		} else if (match(KCONFIGLINE, /^(if|menu) (.*)$/, m)) {
			#print "Read Kconfig menu line: " KCONFIGLINE
			if (match(m[2], /^(["'])(.*)(["'])$/, m2) && m2[1] == m2[3]) m[2]=m2[2];
			t = m[2]
			if (t in MENUCONFIG) t = MENUCONFIG[t];
			#print "Read Kconfig " m[1] ": " m[2] ": " t
			menu[menudepth] = t
			menudepth++
		} else if (match(KCONFIGLINE, /^end(if|menu|choice)/, m)) {
			menudepth--
			#t = menu[menudepth]
			#print "Read Kconfig end" m[1] ": " t
		} else if (match(KCONFIGLINE, /^source (.*)$/, m)) {
			#print "Read Kconfig source line: " KCONFIGLINE
			if (match(m[1], /^(["'])(.*)(["'])$/, m2) && m2[1] == m2[3]) m[1]=m2[2];
			t = m[1]
			if (match(t, /\$([0-9A-Z_a-z]+)/, m)) {
				if (m[1] == "SRCARCH") {
					sub(/\$SRCARCH/, SRCARCH, t)
					#print "replaced path: " t
				} else {
					print "path needs variable: " m[1]
					continue
				}
			}
			t2 = ""
			for(i=menudepth-1; i>=0; i--) {
				t2 = menu[i] "\t" t2
			}
			parseKconfig(KDIR "/" t, prefix t2)
			#print "Resuming search in: " file
		} else if (match(KCONFIGLINE, /^[ \t]+|^(bool|tristate|int|string|depends|---help---)/)) {
			continue
		} else {
			print "Read Unknown Kconfig line: " KCONFIGLINE
		}
	}
	close(file)
	#print "closed: " file
}

function str_repeat(s, c,    t) {
	t = ""
	while (c > 0) {
		t = t s
		c--
	}
	return t
}

function indexOf(h, n, start, end,    i) {
	i = index(substr(h,start+1, end-start), n)
	if (i == 0) {
		return -1;
	}
	i += start-1
	#print "i=" i
	return i
}

function nester(prev, curr,    i,t,l,h) {
	# find the length of the prefix that is equal
	h = length(prev)
	if (h > length(curr)) h = length(curr)
	l = 0
	while (h>l) {
		#print "[l=" l "]=" substr(curr,0,l)
		#print "[h=" h "]=" substr(curr,0,h)
		#sleep(0.02)
		# make sure the split is on an arrow boundary
		i = indexOf(curr, "\t", 1+l,h-l)
		if (i <= 0) {
			#print "i=0; h=" l
			h = l
			continue
		}
# 		if (i == l) {
# 			i += 5
# 			#print "i=" i
# 		}
		if (substr(prev,0,i) != substr(curr,0,i)) {
			if (i == h) {
				if (i-1 == l) {
					h = l;
				} else {
					print "h already equal!"
					sleep(10)
					break;
				}
			} else {
				#print "h=" i
				h = i
			}
		} else if (i == l) {
			print "l already equal!"
			sleep(10)
			break;
		} else {
			l = i
		}
	}
	#print "       " substr(curr, 0, l) " / " substr(curr, l+1)
	# return the curr string but replace the equal part with spaces
	return str_repeat(" ", l) substr(curr, l+1)
}

function finalize(    opt,n,i,LAST) {
	for(opt in FINDVARS) {
		t = FINDVARS[opt]
		FINDVARS[opt] = t " (" opt ")"
	}
	n=asort(FINDVARS)
	if (FMT == "") FMT="text"
	if (FMT == "text") {
		LAST=""
		for(i=1; i<=n; i++) {
			print FINDVARS[i]
		}
	} else if (FMT == "cleantext") {
		LAST=""
		for(i=1; i<=n; i++) {
			print nester(LAST, FINDVARS[i])
			LAST=FINDVARS[i]
		}
	}
}

BEGIN {
	if (KDIR == "") {
		print "FATAL: KDIR is not set." > "/dev/stderr"
		exit 1
	}
	
	L=0
	while ((getline VAR) > 0) {
		L++
		findConfigOption(VAR);
	}
	
	findSRCARCH()
	# find menu-paths to options so the user can navigate to options in the menu
	parseKconfig(KDIR "/Kconfig");
	
	finalize()
	
	exit 0
}
