@echo off

::********************************************************
:: Zabbix Agent Installer for Windows
:: 
:: This file can be used to install the zabbix agent for
:: Windows as available from http://www.zabbix.com/download.php
::
:: The ZABBIXZIPFILE variable below may be changed and the ZIP
:: file may be placed in the same directory as this file.  When
:: this file is executed, it will extract the zip file to the
:: desired location and allow you to configure the agent for use.
::
:: Default installation options are available for install path
:: and architecture.
::
::********************************************************

set ZABBIXZIPFILE="zabbix_agents_2.4.4.win.zip"


if [%1] == [] goto GetAdmin
if NOT [%1] == [] goto Install

:GetAdmin
powershell -Command "& { Start-Process '%0' -ArgumentList '%cd%' -Verb runAs }"
goto End

:Install
copy %1\%ZABBIXZIPFILE% .

set /p installpath="Enter installation path [c:\zabbix-agent]: "
if [%installpath%] == [] set installpath=c:\zabbix-agent

powershell -Command "& { Add-Type -A System.IO.Compression.FileSystem ; [IO.Compression.ZipFile]::ExtractToDirectory('%ZABBIXZIPFILE%', '%installpath%') }"

rmdir /s /q %installpath%\conf

set /p hostname="Enter hostname: "
set /p servername="Enter server IP/hostname: "
set /p remotecommands="Enable remote commands? (1 = yes, 0=no) "
set /p unsafeparam="Enable unsafe user parameters? (1 = yes, 0=no) "

echo Creating folders

mkdir %installpath%\conf
mkdir %installpath%\logs

echo Writing settings file

echo LogFile=%installpath%\logs\zabbix_agentd.log > %installpath%\conf\zabbix_agentd.win.conf
echo Server=%servername% >> %installpath%\conf\zabbix_agentd.win.conf
echo ServerActive=%servername% >> %installpath%\conf\zabbix_agentd.win.conf
echo Hostname=%hostname% >> %installpath%\conf\zabbix_agentd.win.conf
echo EnableRemoteCommands=%remotecommands% >> %installpath%\conf\zabbix_agentd.win.conf
echo UnsafeUserParameters=%unsafeparam% >> %installpath%\conf\zabbix_agentd.win.conf
echo Timeout=30 >> %installpath%\conf\zabbix_agentd.win.conf

echo Installing Service

powershell -Command "& { if ($ENV:PROCESSOR_ARCHITECTURE -like '*64*' ) { %installpath%\bin\win64\zabbix_agentd.exe -c %installpath%\conf\zabbix_agentd.win.conf -i } else { %installpath%\bin\win32\zabbix_agentd.exe -c %installpath%\conf\zabbix_agentd.win.conf -i } }"

erase %ZABBIXZIPFILE%

echo Installation Complete

pause

:End