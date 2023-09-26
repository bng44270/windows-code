@echo off

::********************************************************
:: Add Hosts File Entry
::********************************************************

if [%1] == [] goto GetAdmin
if NOT [%1] == [] goto HostMenu

:GetAdmin
powershell -Command "& { Start-Process '%0' -ArgumentList 'YES' -Verb runAs }"
goto End

:HostMenu
cls
echo "Host Entries:"
type C:\Windows\System32\drivers\etc\hosts | findstr /v /r "^#"
echo.
echo "1) Add Host"
echo "2) Delete Host"
echo "3) Exit"
echo.
set /p MENU=-:

if [%MENU%] == [1] goto AddHost
if [%MENU%] == [2] goto DelHost
if [%MENU%] == [3] goto End
goto HostMenu

:AddHost
set /p IPADDR=Enter IP Address:
set /p THISHOST=Enter Hostname:

echo %IPADDR% %THISHOST% >> C:\Windows\System32\drivers\etc\hosts

goto HostMenu

:DelHost
set /p DELHOST=Enter Hostname:

type C:\Windows\System32\drivers\etc\hosts | findstr /v /r /C:" %DELHOST%" > hosts.tmp

move hosts.tmp C:\Windows\System32\drivers\etc\hosts

goto HostMenu

:End