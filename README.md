

These scripts can be run on Linux systems, and is used for my daily health checks.

Please note - this is my script and NOT supported or approved or affiliated to/by any company mentioned above.

Use at Your Own Risk...

<pre>

# ./session_mon.sh -l DBCUSER -d DBCUSERPASSWD -p DISPATCHING -i 10.0.0.1
  SessionNo|PartName   |PEstate     |AMPState      |              AMPIO|LogonTime             |LogonSource                                                                                                                     |UserName
----------- ----------- ------------ -------------- ------------------- ---------------------- -------------------------------------------------------------------------------------------------------------------------------- -------------------------------
    6356839|DBC/SQL    |DISPATCHING |ACTIVE        |         28,805,711|2021/07/22 22:53:28.00|(TCP/IP) ec0c 10.0.0.1 TERADATA;TERADATACOP1/10.0.0.1:1025 CID=257A4994 C23360010 JDBC16.20.00.13;1.8.0_112 01 LSS   |PUI
    6356875|DBC/SQL    |DISPATCHING |ACTIVE        |        168,727,908|2021/07/22 22:54:06.00|(TCP/IP) ec22 10.0.0.1 TERADATA;TERADATACOP2/10.0.0.1:1025 CID=7C7A23A4 C23360010 JDBC16.20.00.13;1.8.0_112 01 LSS   |PUI
    6356878|DBC/SQL    |DISPATCHING |ACTIVE        |        104,994,355|2021/07/22 22:54:06.00|(TCP/IP) ec23 10.0.0.1 TERADATA;TERADATACOP1/10.0.0.1:1025 CID=2A0714D C23360010 JDBC16.20.00.13;1.8.0_112 01 LSS    |PGUI
    6446649|DBC/SQL    |DISPATCHING |ACTIVE        |          4,917,165|2021/07/23 16:15:23.00|(TCP/IP) cdc9 10.0.0.1 TERADATA;TERADATACOP3/10.0.0.1:1025 CID=1A65F7E4 C23360010 JDBC16.20.00.13;1.8.0_112 01 LSS    |PGUI

</pre>
