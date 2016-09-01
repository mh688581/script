#!/usr/bin/python
# -*- coding: UTF-8 -*-
#Author:minheng,2016.3.16

import os
import xlwt

#os.system("git log --after=2015-11-19 --name-only  --oneline | grep -v 'TFS' | grep -v 'Merge' | grep -v 'Task' | grep -v 'af8a63c' | sort | uniq > list")
"""
os.system('git remote update')
os.system('git checkout origin/QCOM_8992_6.x_qiku')
os.system('git log --after=2015-11-19 --raw --oneline | egrep -v "TFS|Task|Merge|upload\ Pull\ Up" | awk '{print "^"$5" "$6}' | egrep -v "\^A|\^D" | awk '{print $2}' | sort | uniq > list')
os.system('git log --after=2015-11-19 --raw --oneline | egrep -v "TFS|Task|Merge|upload\ Pull\ Up" | awk '{print "^"$5" "$6}' | egrep "\^A|\^D" | awk '{print $2}' | sort | uniq > dlist')
list1 = open("list").readlines()
dlist = open("dlist").readlines()
for i in dlist:
	try:
		list1.remove(i)
	except:
		pass
mlist = open("mlist","w")
mlist.write("".join(list1))
mlist.close()
"""
myfile = open("mlist")
dst = xlwt.Workbook(encoding = 'utf-8')
table = dst.add_sheet('framework',cell_overwrite_ok=True)
row = 2 
lines = myfile.readlines()
myfont = xlwt.Font()
myfont.bold = True
myfont.height = 100
myfont.colour_index = 5
alignment = xlwt.Alignment()
alignment.horz = xlwt.Alignment.HORZ_CENTER
alignment.vert = xlwt.Alignment.VERT_CENTER
#myfont.colour_index = 3 # 3 red 28 blue
blue_style = xlwt.XFStyle()
blue_style.font = myfont
blue_style.alignment = alignment
table.write(1,0,"file name",blue_style)
table.write(1,1,"增加行数",blue_style)
table.write(1,2,"减少行数",blue_style)
table.write(1,3,"文件类型",blue_style)
table.write(1,4,"change_type",blue_style)
#print myfile
myfile.close()
for i in lines:
	name = i.strip()
	print name
	code = os.system("git diff --numstat origin/QCOM_8992_ori %s > %s.tmp" % (name,name))
	#print code
	if code != 0:
		os.system("rm -rf %s.tmp" % name)
	try:
		lines = open("%s.tmp" % name).readlines()
		table.write(row,4,"Differ")
	except:
		continue
		#	print "%s not exist" % name
		#	table.write(row,4,"Delete")
		#os.system("git log --after=2015-11-19 --oneline --numstat | grep %s > top.tmp" % name)
		#lines = open("top.tmp").readlines()
	plus = 0
	minus = 0
	for j in lines:
		tmp = j.strip().split()
		try:
			plus = plus + int(tmp[0])
			minus = minus + int(tmp[1])
			table.write(row,3,"txtfile")
		except:
			table.write(row,3,"binaryfile")
			pass
#	if plus == int(os.popen("cat %s | wc -l" % name).read().strip()) and plus != 0:
	#	table.write(row,4,"Add")
#		continue
	if plus == 0 and minus == 0:
		continue
	table.write(row,0,name)
	table.write(row,1,plus)
	table.write(row,2,minus)
	row = row + 1
myfont0 = xlwt.Font()
myfont0.bold = True
myfont0.height = 160
#myfont.colour_index = 3 # 3 red 28 blue
myfont0.colour_index = 20
red_style = xlwt.XFStyle()
red_style.font = myfont0
red_style.alignment = alignment
table.write(0,0,"总共修改文件数 : %d" % (row-2),red_style)
table.col(0).width = 256 * 50
table.row(0).height_mismatch = True
table.row(0).height = 256 * 2
table.row(1).height = 300
dst.save("frameworks修改行数统计.xls")