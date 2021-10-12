#!/bin/bash

tempfolder=/tmp
version=00.01.06.00

while getopts s:u:a:p:l:d:i:t:hv option
   do
      case "${option}"
         in
           s) SESNO=${OPTARG};;
           u) USRNA=${OPTARG};;
           a) AMPST=$( echo "WHERE AMPState = '${OPTARG}'" );;
           p) PEST=$( echo "WHERE PEState = '${OPTARG}'" );;
           l) LUSR=${OPTARG};;
           d) PUSR=${OPTARG};;
           i) IPAD=${OPTARG};;
           t) TDAY=${OPTARG};;
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
     echo -e "                      [ -i IP Address ] "
     echo -e "                      [ -l DBS logon user ] "
     echo -e "                      [ -d DBS password ] "
     echo -e "                      [ -h display help text and exit ] "
     echo -e "                      [ -v display version text and exit ] "
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
.messageout file=$tempfolder/flow_control.stdout.txt
.logon /$LUSR,$PUSR
.export report file=$tempfolder/flow_control.csv
.width 270
.set separator '|'

SELECT THEDATE,  EXTRACT ( HOUR FROM (( TheTime ))) AS Starthour
    ,WM_COD_CPU
    ,CAST ( SUM ( CPUIDLE + CPUIOWAIT + CPUUSERV + CPUUEXEC ) AS BIGINT ) / 100 as MaxCPUSeconds
    ,CAST ( MaxCPUSeconds / 1000 * WM_COD_CPU AS INTEGER ) AS WMCODSeconds
    ,CAST ( SUM ( CPUUSERV + CPUUEXEC ) AS INTEGER ) / 100 AS CPUSecondsConsumed
    ,CPUSecondsConsumed*100/WMCODSeconds as Percent_Consumed
    ,MAX( AwtInuseMax ) AS AwtInuseMax
    ,MAX( AmpsFlowControlled ) AS AmpsFlowControlled
FROM  dbc.ResUsageSpma                 
WHERE THEDATE = '$TDAY' 
GROUP BY 1,2,3
ORDER BY 1,2;

.export reset
.logoff
.messageout reset
.exit
EOI
) > /dev/null 2>&1

if [ -z "$IPAD" ]
   then
     cat $tempfolder/flow_control.csv
   else
     cat $tempfolder/flow_control.csv | egrep 'Session|---' &&
     cat $tempfolder/flow_control.csv | grep $IPAD
fi

# Cleanup...
rm $tempfolder/flow_control.csv
rm $tempfolder/flow_control.stdout.txt
