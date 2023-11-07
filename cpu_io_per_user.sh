#!/bin/bash

tempfolder=/tmp
version=00.01.02.00

while getopts t:u:p:hv option
   do
      case "${option}"
         in
           t) TOPNA=$( echo "TOP ${OPTARG}" );;
           u) LUSR=${OPTARG};;
           p) PUSR=${OPTARG};;
           h) ;;
           v) ;;
      esac
done

if [ "$1" == "-h" ]
   then
     echo -e " \n "
     echo -e "Usage: cpu_io_per_user.sh [ -t TOP Users - enter TOP 10 or equivalent ] "
     echo -e "                          [ -u DBS logon user ] "
     echo -e "                          [ -p DBS password ] "
     echo -e "                          [ -h display help text and exit ] "
     echo -e "                          [ -v display version text and exit ] "
     echo -e "     -l and -d is mandatory \n"
     exit
fi

if [ "$1" == "-v" ]
   then
     echo -e " \n "
     echo -e "Version: $version \n"
     exit
fi

### Application...

(
/opt/teradata/client/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2 | cut -d'.' -f1,2)/bin/bteq <<EOI
.set echoreq off
.messageout file=$tempfolder/cpu_io_per_user.txt
.logon /$LUSR,$PUSR
.export report file=$tempfolder/cpu_io_per_user.csv
.width 250

SELECT $TOPNA DT.UN (FORMAT 'X(25)', TITLE 'USERNAME'),
 COUNT(DT.SN)(FORMAT 'Z(2)9', TITLE 'SESSION//COUNT')
	,SUM(DT.CPUT)
            (FORMAT 'ZZZ,ZZZ,ZZZ,ZZ9.99', TITLE 'CPU//SECONDS')
	,SUM(DT.DIO)
            (FORMAT 'ZZZ,ZZZ,ZZZ,ZZZ,ZZ9', TITLE 'DISK IO//ACCESSES')
FROM	 
 (
SELECT	 ST.USERNAME 	
	,ST.SESSIONNO 		
	,SUM(AC.CPU) 		
	,SUM(AC.IO) 		
FROM	 DBC.SESSIONTBL ST, DBC.ACCTG AC
GROUP	 BY 1,2) DT(UN, SN, CPUT, DIO)
GROUP	 BY 1
ORDER	 BY 3 DESC;

.export reset
.logoff
.messageout reset
.exit
EOI
) > /dev/null 2>&1

cat $tempfolder/cpu_io_per_user.csv

# Cleanup...
rm $tempfolder/cpu_io_per_user.csv
rm $tempfolder/cpu_io_per_user.txt
