#!/bin/bash

tempfolder=/tmp
version=00.01.02.00

while getopts u:l:d:hv option
   do
      case "${option}"
         in
           u) USRNA=${OPTARG};;
           l) LUSR=${OPTARG};;
           d) PUSR=${OPTARG};;
           h) ;;
           v) ;;
      esac
done

if [ "$1" == "-h" ]
   then
     echo -e " \n "
     echo -e "Usage: cpu_io_per_user.sh [ -u User Name ] "
     echo -e "                          [ -l DBS logon user ] "
     echo -e "                          [ -d DBS password ] "
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

/opt/teradata/client/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2 | cut -d'.' -f1,2)/bin/bteq <<EOI
.set echoreq off
.messageout file=$tempfolder/cpu_io_per_user.stdout.txt
.logon /$LUSR,$PUSR
.export report file=$tempfolder/cpu_io_per_user.csv
.width 250 

SELECT UserName (FORMAT 'X (16)')
,AccountName (FORMAT 'X (12)')
,SUM (CpuTime)
,SUM (DiskIO)
FROM DBC.AMPUsage
WHERE UserName = '$USRNA'
GROUP BY 1, 2
ORDER BY 3 DESC ;

.export reset
.logoff
.messageout reset
.exit
EOI

cat $tempfolder/cpu_io_per_user.csv

# Cleanup...
rm $tempfolder/cpu_io_per_user.csv
rm $tempfolder/cpu_io_per_user.stdout.txt
