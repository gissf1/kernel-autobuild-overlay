#!/usr/bin/env python

from __future__ import print_function
import sys
import os
import pprint

pp = pprint.PrettyPrinter(indent=4)

def loadData(fn):
	n=0
	data = { "name":".config Option Changes", "nolink":True }
	with open(fn, 'rt') as f:
		for rawline in f:
			line = rawline.rstrip('\r\n').split('\t')
			n += 1
			d = data
			while len(line) > 0:
				t = line.pop(0)
				if "child" not in d:
					d["child"] = {}
				d = d["child"]
				if t not in d:
					d[t] = { "name":t }
					d = d[t]
				else:
					d = d[t]
	return data

def displayData(data, id="chg"):
	if "name" not in data:
		print("*** Missing Name! ***")
		pp.pprint(data)
	elif "nolink" in data and data["nolink"] == True:
		print(data["name"])
	else:
		print("<a href='#%s' onclick='strike(this);'>%s</a>" % (id, data["name"]))
	if "child" in data:
		print("<ol>")
		i = 1
		for child in data['child']:
			print("<li>")
			displayData(data['child'][child], "%s_%d" % (id, i))
			print("</li>\n")
			i += 1
		print("</ol>\n")

def main(fn):
	data = loadData(fn)
	if data == None:
		return 1
	print("""
<style>
ol {
	border-left:   1px dotted #888;
	border-bottom: 1px dotted #888;
	padding-left:  30px;
	margin-bottom:  3px;
}

ol li {
	padding-bottom: 2px;
}

ol a, *:link, *:visited {
	color: #000;
	text-decoration: none;
}

a.strike {
	text-decoration: line-through;
	color: #bbb;
}
a.strike + ol {
	display:none;
}
a:hover {
	border: 1px dashed blue;
	background-color: #def;
}

</style>
<script><!--
function strike(e) {
	e.classList.toggle("strike");
}
//--></script>
""")
	displayData(data)
	return 0

if __name__ == "__main__":
	main("/dev/stdin")