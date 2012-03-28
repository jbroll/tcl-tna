

tnaplus:
	critcl3.kit -force -pkg tnaplus

tna-vm :
	gcc  -O3 tna-vm.c  -o tna-vm


# Install ActiveState python
#    pypm install numpy
#    pypm install numexpr
#
python:
	time /usr/local/bin/python2.7   numpy-test.py
	time /usr/local/bin/python2.7 numexpr-test.py
	
