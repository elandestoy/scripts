@echo off
rem 
rem   This script save a file on a UNC PATH with the status, version, ID and hostname of Anydesk.
rem   Script Version 0.1
rem 
rem  Enrique Landestoy 
rem  -- e.landestoy@gmail.com
rem  -- http://github.com/elandestoy
rem 

set NETPATH=\\PATH\
set ScriptRegPath=HKLM\SOFTWARE\StakScripts\Anydesk

reg query %ScriptRegPath% >NUL 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Exiting: Script already run.
    GOTO :END
)

reg add %ScriptRegPath% >NUL 2>&1
if %ERRORLEVEL% NEQ 0 ( 
    echo Exiting: Can't write on the registry.
    GOTO :END
)

if not exist %NETPATH% (
    echo Exiting: Path do not exist.
    reg delete %ScriptRegPath% /f
    GOTO :END
)

:ANYDESK
if exist "C:\Program Files (x86)\AnyDesk\AnyDesk.exe" ( 
    GOTO :GETINFO
) else (
    echo AnyDesk not Installed.
    GOTO :END
)

:GETINFO
for /f "delims=" %%i in ('"C:\Program Files (x86)\AnyDesk\AnyDesk.exe" --get-status') do set STATUS=%%i 
for /f "delims=" %%i in ('"C:\Program Files (x86)\AnyDesk\AnyDesk.exe" --version') do set VERSION=%%i 
for /f "delims=" %%i in ('"C:\Program Files (x86)\AnyDesk\AnyDesk.exe" --get-id') do set CID=%%i 
echo %VERSION% [ %STATUS%] ID for  %COMPUTERNAME% (%USERDOMAIN%\%USERNAME%) is: %CID% >> %NETPATH%Anydesk-%COMPUTERNAME%-%USERNAME%.txt
GOTO :END



:END
EXIT /B