#!/usr/bin/env python
# -*- coding: UTF-8 -*-
# sync app info and copy reports
# Author:minheng, 20170119

import os
import sys
import getopt
import shutil

isFirst = 0

def main(argv):
	global NEWF,OLDF,isFirst
	opts, args = getopt.getopt(argv[1:], "n:o:f")
	for op, value in opts:
		if op == "-n":
			NEWF = value
		elif op == "-o":
			OLDF = value
		elif op == "-f":
			isFirst = 1
		else:
			print '''wrong parameter!!!
just -n newversion -o oldverson -f isFirst'''
	if os.path.exists("ApkChangedInfo"):
		shutil.rmtree("ApkChangedInfo")
	os.mkdir("ApkChangedInfo")
	if isFirst == 1 :
		sync_first()
	else:
		sync_diff()

def copy_report(arr):
	fpath = "/mnt/hgfs/APP_APK/" + arr[5] + "/" + arr[6] + "/" + arr[7].strip() + "/test_report.xls"
	if os.path.exists(fpath):
		shutil.copyfile(fpath,"ApkChangedInfo/%s_%s_test_report.xls" % (arr[6],arr[7].strip()))

def sync_first():
	NEW = open(NEWF,"r")
	dic_new = create_dic(NEW)
	for i in dic_new.keys() :
		copy_report(dic_new[i])
	NEW.close()

def sync_diff():
	NEW = open(NEWF,"r")
	OLD = open(OLDF,"r")
	dic_new = create_dic(NEW)
	dic_old = create_dic(OLD)
	changef = open("ApkChangedInfo/apk_changed_info.txt","w")
	for i in dic_new.keys() :
		if not dic_old.has_key(i) :
			print >> changef,"---------------------------------\n"
			print >> changef,"App_Name : %s (add new apk)\n" % i
			print >> changef,"APK release path : %s " % '\\'.join(dic_new[i])
			copy_report(dic_new[i])
			continue
		if dic_new[i][7] != dic_old[i][7] :
			print >> changef,"---------------------------------\n"
			print >> changef,"App_Name : %s (update apk)\n" % i
			print >> changef,"APK release path : %s " % '\\'.join(dic_new[i])
			copy_report(dic_new[i])
		del dic_old[i]
	for j in dic_old.keys() :
		print >> changef,"---------------------------------\n"
		print >> changef,"App_Name : %s (del old apk)\n" % j
	NEW.close()
	OLD.close()

def create_dic(file):
	dic = {}
	for i in file.readlines() :
		if not i.startswith("APK release path") :
			continue
		tmp = i[i.rfind(':')+1:].split('\\')
		app_name = tmp[6]
		dic[app_name] = tmp
		#print tmp 
	return dic
        

if __name__ == '__main__':
	main(sys.argv)
