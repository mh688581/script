#!/usr/bin/env python
# -*- coding: UTF-8 -*-
# update—baseline.py v1.0.0
# just for xls to update apk's baseline
# Author:minheng, 2016.12.21
import xlrd
import sys
import os

def usage():
	print '''
	usage :
	python %s *.xls
	*.xls :
	序号  apk  基线  说明
	''' % sys.argv[0]
	sys.exit(1)

def main(argv):
	if len(argv)!= 2:
		usage()
	data = xlrd.open_workbook(argv[1])
	CMS_table = data.sheet_by_name(u'Sheet1')
	if not os.path.exists("copy_app.cfg"):
		print "Error : copy_app.cfg not exists!!!!!"
		sys.exit(1)
	apklist = open("copy_app.cfg","r")
	newfile = open("copy_app.cfg_new","w")
	CMS_nrows = CMS_table.nrows
	#CMS_ncols = CMS_table.ncols
	print "%d apks to upadte" % (CMS_nrows-1)

	k = 0
	dic = {}
	for i in range(1,CMS_nrows):
		for j in range(1,3):
			if k != 1:
				apk = CMS_table.cell(i,j).value
				#print "apk:%s" % apk
			else:
				baseline = CMS_table.cell(i,j).value
				#print "baseline:%s" % baseline
				baseline = baseline[baseline.rfind('\\')+1:]
				#print "baseline_modify:%s" % baseline
				dic[apk] = baseline
			k=k+1
		k = 0
		#print >>  apklist

	for i in apklist.readlines():
		if i.startswith('$') or i.startswith('\n') or i.startswith(' '):
			print >> newfile, i,
			continue
		appinfo = i.split()
		for j in dic.keys():
			if appinfo[0] == j+".apk" or appinfo[0] == j:
				appinfo[1] = dic[j]
				print appinfo
		print >> newfile , " ".join(appinfo)+"\n",

if __name__ == '__main__':
	main(sys.argv)