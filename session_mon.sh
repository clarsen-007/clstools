#!/bin/bash

tempfolder=/tmp
version=00.01.02.00

while getopts s:u:a:p:l:hv option
   do
      case "${option}"
         in
           s) SESNO=${OPTARG};;
           u) USRNA=${OPTARG};;
           a) AMPST=$( echo "WHERE AMPState = '${OPTARG}'" );;
           p) PEST=$( echo "WHERE PEState = '${OPTARG}'" );;
           l) LUSR=${OPTARG};;
           h) ;;
           v) ;;
      esac
done

if [ "$1" == "-h" ]
   then
     echo -e " \n "
     echo -e "Usage: session_mon.sh [ -s Session Number ] default all sessions "
     echo -e "                      [ -u User Name ] default all users "
     echo -e "                      [ -a AMPState filter ] "
     echo -e "                      Accepted states are : ABORTING, BLOCKED, ACTIVE, IDLE, UNKNOWN "
     echo -e "                      [ -p PEState filter ] "
     echo -e "                      Accepted states are : DELAYED, HOST-RESTART, ABORTING, PARSING-WAIT, PARSING, ELICIT ( for ELICIT CLIENT DATA ), DISPATCHING, BLOCKED, "
     echo -e "                                            ACTIVE, RESPONSE, IDLE ( two states IDLE and IDLE: IN-DOUBT ), QTDELAYED, SESDELAYED, UNKNOWN "
     echo -e "                      [ -l DBS logon user ] default is SYSTEMFE "
     echo -e "                      [ -h display help text and exit ] "
     echo -e "                      [ -v display version text and exit ] \n"
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
.messageout file=$tempfolder/session_mon.stdout.txt
.logon /${LUSR:-xxxxxx},xxxxxxx
.export report file=$tempfolder/session_mon.csv
.width 250 

SELECT SessionNo, PartName, PEState, AMPState, LogonTime, LogonSource, UserName FROM TABLE(MonitorSession( -1, '${USRNA:-*}', ${SESNO:-0} )) AS T2 $AMPST $PEST
ORDER BY 1;

.export reset
.logoff
.messageout reset
.exit
EOI

cat $tempfolder/session_mon.csv

# Cleanup...
rm $tempfolder/session_mon.csv
rm $tempfolder/session_mon.stdout.txt
