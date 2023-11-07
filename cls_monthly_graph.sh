#!/bin/bash

### Monthly Graph collection Suite

version=00.01.01.00

while getopts s:e:u:p:hv option
   do
      case "${option}"
         in
           s) STARTDATE=${OPTARG};;
           e) ENDD=${OPTARG};;
           u) LUSR=${OPTARG};;
           p) PUSR=${OPTARG};;
           h) ;;
           v) ;;
      esac
done

### Variables

tempfolder=/tmp
ENDDATE=$( echo "between '$STARTDATE' and '$ENDD'" )
DB1=pdcrinfo.ResUsageSpma_Hst
DB2=dbc.resusagesvpr


if [ "$1" == "-h" ]
   then
     echo -e " \n "
     echo -e "Usage: cls_sps_collect.sh   [ -s Start Date ] if this is the only input, then -s = the date for capture "
     echo -e "                            [ -e End Date ] "
     echo -e "                            [ -u DBS logon user ] "
     echo -e "                            [ -p DBS password ] "
     echo -e "                            [ -h display help text and exit ] "
     echo -e "                            [ -v display version text and exit ] "
     echo -e "                 -l, -d  and -s is mandatory \n"
     exit
fi

if [ "$1" == "-v" ]
   then
     echo -e " \n "
     echo -e "Monthly Graph collection Suite..."
     echo -e "   Version: $version \n"
     echo -e "             By clarsen-007.github.io \n"
     exit
fi

bteqf ()
   {
       /opt/teradata/client/$( rpm -qa | grep bteq | cut -d'-' -f2 | cut -d'.' -f1,2 )/bin/bteq
   }


### Application...

### CPU collection...

echo " Collecting DBQL for CPU... "

bteqf <<EOI
.set echoreq off
.messageout file=$tempfolder/cls_monthly_cpu_out.txt
.logon /$LUSR,$PUSR
.export report file=$tempfolder/cls_monthly_cpu_$STARTDATE.to.$ENDD.csv
.width 20000
.set separator '|'

SELECT
TheDate (FORMAT 'YYYY-MM-DD')
,CAST((TheTime (FORMAT '99:99:99')) as CHAR(8))
,Extract(HOUR FROM TheTime) as hr
,Extract(MINUTE FROM TheTime) as mn
,NodeID
,NodeType
,NCPUs
,WM_COD_CPU
,WM_COD_IO
,((CPUUServ + CPUUExec)  / (CPUUServ+CPUUExec+CPUIOWait+CPUIdle ) * 100) (NAMED "Busy%", FORMAT 'Z(1)99')
,(CPUUExec / (CPUUServ+CPUUExec+CPUIOWait+CPUIdle ) * 100) (NAMED "User%", FORMAT 'Z(1)99')
,(CPUUServ / (CPUUServ+CPUUExec+CPUIOWait+CPUIdle ) * 100) (NAMED "OS%", FORMAT 'Z(1)99')
,(CPUIOWait / (CPUUServ+CPUUExec+CPUIOWait+CPUIdle ) * 100) (NAMED "IOWait%", FORMAT 'Z(1)99')
,(CPUIdle / (CPUUServ+CPUUExec+CPUIOWait+CPUIdle ) * 100) (NAMED "Idle%", FORMAT 'Z(1)99')
,CPUPRocSwitches
,PageMajorFaults
,PageMinorFaults
,NLBActiveSessionsMax
,NLBSessionsInuse
,NLBSessionsCompleted
,NLBMsgFlowControlled
,NLBMsgFlowControlledKB   
, (CPUUServ + CPUUExec)
FROM $DB1
WHERE TheDate Between '$STARTDATE' and '$ENDD';

.export reset
.logoff
.messageout reset
.exit
EOI

sleep 5

### FSG collection...

echo " Collecting DBQL for FSG... "

bteqf <<EOI
.set echoreq off
.messageout file=$tempfolder/cls_monthly_fsg_out.txt
.logon /$LUSR,$PUSR
.export report file=$tempfolder/cls_monthly_fsg_$STARTDATE.to.$ENDD.csv
.width 20000
.set separator '|'

SELECT
TheDate
,TheTime
,NodeID 
,FsgCacheInuseKB
,ReadsCold
,ReadsHot
,ReadsWarm
,WritesCold
,WritesHot
,WritesWarm
FROM $DB2
WHERE TheDate BETWEEN '$STARTDATE' and '$ENDD';

.export reset
.logoff
.messageout reset
.exit

EOI

sleep 5

### User collection...

echo " Collecting DBQL for Users... "

bteqf <<EOI
.set echoreq off
.messageout file=$tempfolder/cls_monthly_user_out.txt
.logon /$LUSR,$PUSR
.export report file=$tempfolder/cls_monthly_user_$STARTDATE.to.$ENDD.csv
.width 20000
.set separator '|'

SELECT * FROM pdcrinfo.Acctg_Hst WHERE LogDate BETWEEN '$STARTDATE' AND '$ENDD';

.export reset
.logoff
.messageout reset
.exit

EOI

sleep 5
sed -i 's/,//' $tempfolder/cls_monthly_user_$STARTDATE.to.$ENDD.csv
sleep 2
sed -i 's/./,/' $tempfolder/cls_monthly_user_$STARTDATE.to.$ENDD.1.csv
sleep 5

### Disk collection...

echo " Collecting DBQL for Database Disks... "

bteqf <<EOI
.set echoreq off
.messageout file=$tempfolder/cls_monthly_disk_out.txt
.logon /$LUSR,$PUSR
.export report file=$tempfolder/cls_monthly_disk_$STARTDATE.to.$ENDD.csv
.width 20000
.set separator '|'

locking row for access
Select
c.year_of_calendar
,c.Month_of_Year
,c.Week_of_Year
,(LogDate - ((LogDate - DATE '0001-01-07') MOD 7)) as BOW
,c.Day_of_Month
,c.Day_of_week
,a.LogDate
,sh.WorkPeriod
,sh.Period
,a.Loghour
,a.NodeType as NodeType ,COUNT(DISTINCT(Nodeid))(int) as Nodes
,SUM(Secs) (int) as Seconds
,SUM(IOReadDataMB+IOWriteDataMB)(NAMED  IODiskMB,FORMAT 'Z(20)9')
,SUM(IOReadDataMB)(NAMED  IOReadMB,FORMAT 'Z(20)9')
,SUM(IOWriteDataMB)(NAMED IOWriteMB,FORMAT 'Z(20)9')
,(IOReadMB/NULLIFZERO(IODiskMB)) * 100 (NAMED IOMBReadPct,FORMAT 'Z(20)9')
,SUM(IOReadCount+IOWriteCount)(NAMED IODiskReq,FORMAT 'Z(20)9')
,SUM(IOReadCount)(NAMED IOReadReq,FORMAT 'Z(20)9')
,SUM(IOWriteCount)(NAMED IOWriteReq,FORMAT 'Z(20)9')
,(IOReadReq/NULLIFZERO(IODiskReq)) * 100 (NAMED IOReqReadPct,FORMAT 'Z(20)9')
,AVG(IOReadDataMB+IOWriteDataMB)/NULLIFZERO(AVG(IOReadCount+IOWriteCount))(NAMED AVGDATASIZE,FORMAT 'Z(20)9')
,MAX(IOReadDataMB+IOWriteDataMB)/NULLIFZERO(MAX(IOReadCount+IOWriteCount))(NAMED MAXDATASIZE,FORMAT 'Z(20)9')
,(( 1 -(AVG(IOReadDataMB+IOWriteDataMB) /NULLIFZERO(MAX(IOReadDataMB+IOWriteDataMB))) ) * 100)(NAMED IODataMBSkew,FORMAT 'Z(20)9')
,(( 1 -(AVG(IOReadDataMB+IOWriteDataMB)/NULLIFZERO(MAX(IOReadDataMB+IOWriteDataMB))) ) * 100)(NAMED IOCountSkew,FORMAT 'Z(20)9')
,SUM(IOReadDataMB+IOWriteDataMB)/NULLIFZERO(SUM(SECS))(NAMED IODiskMBSec,FORMAT 'Z(20)9') -- Avg Node Level Metric
,SUM(IOReadDataMB)/NULLIFZERO(SUM(SECS))(NAMED IOReadMBSec,FORMAT 'Z(20)9') -- Avg Node Level Metric
,SUM(IOWriteDataMB)/NULLIFZERO(SUM(SECS))(NAMED IOWriteMBSec,FORMAT 'Z(20)9') -- Avg Node Level Metric
,SUM(IOReadDataMB+IOWriteDataMB)/NULLIFZERO(SUM(SECS)/Nodes)(NAMED SysIODiskMBSec,FORMAT 'Z(20)9') -- System Level Metric
,SUM(IOReadDataMB)/NULLIFZERO(SUM(SECS)/Nodes)(NAMED SysIOReadMBSec,FORMAT 'Z(20)9') -- System Level Metric
,SUM(IOWriteDataMB)/NULLIFZERO(SUM(SECS)/Nodes)(NAMED SysIOWriteMBSec,FORMAT 'Z(20)9') -- System Level Metric
FROM PDCRINFO.ResUsageSum10_hst a INNER JOIN PDCRINFO.Calendar c
ON a.logdate = c.calendar_date
INNER JOIN PDCRINFO.Shifthour sh
ON a.loghour = sh.shifthour
WHERE a.LogDate between '$STARTDATE' AND '$ENDD'
AND c.Calendar_date between '$STARTDATE' AND '$ENDD'
Group by 1,2,3,4,5,6,7,8,9,10,11
Order by 1,2,3,4,5,6,7,8,9,10,11;

.export reset
.logoff
.messageout reset
.exit

EOI

sleep 5

### Paging collection...

echo " Collecting DBQL for Paging... "

bteqf <<EOI
.set echoreq off
.messageout file=$tempfolder/cls_monthly_paging_out.txt
.logon /$LUSR,$PUSR
.export report file=$tempfolder/cls_monthly_paging_$STARTDATE.to.$ENDD.csv
.width 20000
.set separator '|'

LOCKING ROW FOR ACCESS
SELECT
         TheDate (FORMAT 'YYYY-MM-DD')
        ,CAST((TheTime (FORMAT '99:99:99')) as CHAR(8))
        ,Extract(HOUR FROM TheTime) as hr
        ,Extract(MINUTE FROM TheTime) as mn
        ,Extract(SECOND FROM TheTime) as sec
        ,NodeID
        ,NodeType
        ,NCPUs
        ,vproc1 (NAMED "AMPs/Node")
        ,vproc2 (NAMED "PEs/Node")
        ,vproc3 (NAMED "GTWs/Node")
        ,vproc4 (NAMED "RSGs/Node")

        ,PM_COD_CPU
        ,PM_COD_IO
        ,WM_COD_CPU
        ,WM_COD_IO

        ,((CPUUServ + CPUUExec)  / (CPUUServ+CPUUExec+CPUIOWait+CPUIdle ) * 100) (NAMED "Busy%", FORMAT 'Z(3)9.99')
        ,(CPUUExec / (CPUUServ+CPUUExec+CPUIOWait+CPUIdle )*100) (NAMED "User%", FORMAT 'Z(3)9.99')
        ,(CPUUServ / (CPUUServ+CPUUExec+CPUIOWait+CPUIdle )*100) (NAMED "OS%", FORMAT 'Z(3)9.99')
        ,(CPUIOWait / (CPUUServ+CPUUExec+CPUIOWait+CPUIdle )*100) (NAMED "IOWait%", FORMAT 'Z(3)9.99')
        ,(CPUIdle / (CPUUServ+CPUUExec+CPUIOWait+CPUIdle )*100) (NAMED "Idle%", FORMAT 'Z(3)9.99')

        ,(CpuThrottleTime / (CPUUServ+CPUUExec+CPUIOWait+CPUIdle )*100) (NAMED "Throttle%", FORMAT 'Z(3)9.99')
        ,TDEnabledCPUs

        ,MemSize
        ,MemFreeKB
        ,VHCacheKB
        ,KernMemInuseKB
        ,SegMDLInuseKB
        ,KernMemInuseKB+SegMDLInuseKB AS TotalKernMemInuseKB
        ,FsgCacheKB
        ,PageScanDirects
        ,PageScanKswapds
        ,PageMajorFaults
        ,PageMinorFaults
        ,SlabCacheKB
        ,AmpsFlowControlled
        ,FlowCtlCnt
        ,AwtInuse
        ,AwtInuseMax

        ,MemVprAllocKB
        ,MemTextPageReads
        ,MemCtxtPageWrites
        ,MemCtxtPageReads
        ,( MemCtxtPageWrites + MemCtxtPageReads ) / secs (NAMED "TotSwapPgs/sec")

        ,DBLockBlocks
        ,DBLockDeadlocks
        ,FileAcqs        (FORMAT 'Z(13)9')
        ,FileAcqKB        (FORMAT 'Z(13)9')
        ,FileAcqReads    (FORMAT 'Z(13)9')
        ,FileAcqReadKB    (FORMAT 'Z(13)9')
        ,FileRels        (FORMAT 'Z(13)9')
        ,FileRelKB        (FORMAT 'Z(13)9')
        ,FileWrites        (FORMAT 'Z(13)9')
        ,FileWriteKB    (FORMAT 'Z(13)9')
        ,FilePres        (FORMAT 'Z(13)9')
        ,FilePreKB        (FORMAT 'Z(13)9')
        ,FilePreReads    (FORMAT 'Z(13)9')
        ,FilePreReadKB    (FORMAT 'Z(13)9')
        ,FileLockBlocks    (FORMAT 'Z(13)9')
        ,FileLockDeadlocks
        ,FileLockEnters
        ,FileSmallDepotWrites
        ,FileLargeDepotWrites
        ,FileLargeDepotBlocks
        ,((FileAcqReadKB + FilePreReadKB + FileWriteKB)/1024) (NAMED TotMB, FORMAT 'Z(15)9')
        ,ZEROIFNULL(  TotMB/(NULLIFZERO(centisecs/100.00))  ) (NAMED "TotMB/sec", FORMAT 'Z(15)9')

/* Physical I/O */

        ,FileAcqReads (named "SPMAPhysReads")
        ,FilePreReads (named "SPMAPhysPreReads")
        ,FileWrites (named "SPMAPhysWrites")
        ,FileAcqReadKB (named "SPMAPhysReadKB")
        ,FilePreReadKB (named "SPMAPhysPreReadKB")
        ,FileWriteKB (named "SPMAPhysWriteKB")

/* Loghical IO */
        ,FileAcqKB (named "SPMALogicalReadKB")
        ,FileAcqs (named "SPMALogicalReads")

/* Network */
        ,NetMsgPtPWriteKB
        ,NetMsgBrdWriteKB
        ,NetMsgPtPReadKB
        ,NetMsgBrdReadKB
        ,NetRxKBPtP
        ,NetTxKBPtP
        ,NetRxKBBrd
        ,NetTxKBBrd
        ,NetMrgTxKB
        ,NetMrgRxKB
        ,NetMrgTxRows
        ,NetMrgRxRows
        ,HostReadKB
        ,HostWriteKB

FROM    PDCRINFO.ResUsageSpma_hst
WHERE    TheDate BETWEEN '$STARTDATE' AND '$ENDD'
Order    By TheDate, TheTime, NodeID
;

.export reset
.logoff
.messageout reset
.exit

EOI

sleep 5

### User collection...

echo " Collecting DBQL for AWT's... "

bteqf <<EOI
.set echoreq off
.messageout file=$tempfolder/cls_monthly_awt_out.txt
.logon /$LUSR,$PUSR
.export report file=$tempfolder/cls_monthly_awt_$STARTDATE.to.$ENDD.csv
.width 20000
.set separator '|'

SELECT
TheDate
,TheTime
,Secs
,VPRID as TheAMP
,NodeID
,MailBoxDepth
,FlowCOntrolled
,FlowCtlCnt
,InUseMax
,Available
,AvailableMin
,WorkTypeMax00 AS DispatcherStep
,WorkTypeMax01 AS Spawned_Level1
,WorkTypeMax02 AS Spawned_Level2
,WorkTypeMax03 AS InternalWork
,WorkTypeMax04 AS Recovery
,WorkTypeMax08 AS ExpeditedDispatcherStep
,WorkTypeMax09 AS ExpeditedSpawned_Level1
,WorkTypeMax10 AS ExpeditedSpawned_Level2
,WorkTypeMax12 AS AbortStep
,WorkTypeMax13 AS SpawnedWorkAbort
,WorkTypeMax14 AS UrgentInternalWork
,WorkTypeMax15 AS MostUrgentInterbalWork
FROM DBC.ResUsageSAWT
WHERE TheDate BETWEEN '$STARTDATE' AND '$ENDD';

.export reset
.logoff
.messageout reset
.exit

EOI

### Collecting all data...

zip $tempfolder/cls_monthly_$STARTDATE.to.$ENDD.zip $tempfolder/cls_monthly_cpu_$STARTDATE.to.$ENDD.csv \
	$tempfolder/cls_monthly_fsg_$STARTDATE.to.$ENDD.csv \
	$tempfolder/cls_monthly_user_$STARTDATE.to.$ENDD.csv \
	$tempfolder/cls_monthly_disk_$STARTDATE.to.$ENDD.csv \
	$tempfolder/cls_monthly_paging_$STARTDATE.to.$ENDD.csv \
	$tempfolder/cls_monthly_awt_$STARTDATE.to.$ENDD.csv

sleep 2
rm $tempfolder/cls_monthly_cpu_$STARTDATE.to.$ENDD.csv
rm $tempfolder/cls_monthly_fsg_$STARTDATE.to.$ENDD.csv
rm $tempfolder/cls_monthly_user_$STARTDATE.to.$ENDD.csv
rm $tempfolder/cls_monthly_disk_$STARTDATE.to.$ENDD.csv
rm $tempfolder/cls_monthly_paging_$STARTDATE.to.$ENDD.csv
rm $tempfolder/cls_monthly_awt_$STARTDATE.to.$ENDD.csv

echo -e " Please collect log file...   $tempfolder/cls_monthly_$STARTDATE.to.$ENDD.zip "

###
### 00.01.01.00
### First release
### 
### 00.01.02.00
### Added Paging and AWT SQL...
