@echo off
rem 
rem   Script for get Status, version, ID and hostname and saved in the UNC.
rem   version 0.3.10
rem 
rem  Enrique Landestoy 
rem  -- e.landestoy@gmail.com
rem  -- http://github.com/elandestoy
rem 


set NETPATH=\\filesrv\Bit\

if exist "C:\Program Files (x86)\AnyDesk\AnyDesk.exe" ( 
    GOTO GETINFO
) else (
    echo AnyDesk not Installed.
    GOTO END
)

:GETINFO
for /f "delims=" %%i in ('"C:\Program Files (x86)\AnyDesk\AnyDesk.exe" --get-status') do set STATUS=%%i 
for /f "delims=" %%i in ('"C:\Program Files (x86)\AnyDesk\AnyDesk.exe" --version') do set VERSION=%%i 
for /f "delims=" %%i in ('"C:\Program Files (x86)\AnyDesk\AnyDesk.exe" --get-id') do set CID=%%i 
echo %VERSION% [ %STATUS%] ID for %HOSTNAME% (%userdomain%\%USERNAME%) is: %CID% >> %NETPATH%anydesk.txt
GOTO END

:SETPASS
echo klk@klk | anydesk.exe --set-password
GOTO END

:END
EXIT /B