# Modified 2022.05.18 to deal with dollar sign in source files.
s/|/::/g
s/%/ pct. /g
s/#/ octothorpe /g
s/	/|/g
s/\$/ qDOLLARq /g
