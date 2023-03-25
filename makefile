# Makefile for student submission for CS352 Semester project

USERNAME = db2inst1
ROOT_PACKAGE_NAME = project

all: dosqlj dojavac dobind

dosqlj:
	@echo Ignore warning about undefined parameter type Fine
	cd semesterproject; sqlj -compile=false Database.sqlj

dojavac:
	javac -classpath project.jar:$$CLASSPATH semesterproject/Database.java
	
dobind:
	@echo Please enter password when prompted for it
	cd semesterproject; java -cp ..:$$CLASSPATH Bind \
		-rootpkgname $(ROOT_PACKAGE_NAME) \
		-url jdbc:db2:project \
		-user $(USERNAME) \
		Database_SJProfile0.ser
	
	
	