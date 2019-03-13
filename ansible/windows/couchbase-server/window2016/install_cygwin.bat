@ECHO OFF
REM -- Automates cygwin installation
REM -- Based on: https://github.com/rtwolf/cygwin-auto-install

SETLOCAL

REM -- Change to the directory of the executing batch file
CD %~dp0

REM -- Configure our paths
SET SITE=http://mirrors.xmission.com/cygwin/
SET LOCALDIR="%USERPROFILE%\Downloads"
SET ROOTDIR=C:\cygwin

REM -- These are the packages we will install (in addition
REM -- to the default packages)
SET PACKAGES=autoconf,autogen,gawk,grep,make,sed

REM -- Do the install!
ECHO *** INSTALLING DEFAULT PACKAGES
C:\ansible_files\cygwin_setup --quiet-mode --no-desktop --download --local-install --no-verify -s %SITE% -l "%LOCALDIR%" -R "%ROOTDIR%"
ECHO.
ECHO.
ECHO *** INSTALLING CUSTOM PACKAGES
C:\ansible_files\cygwin_setup -q -d -D -L -X -s %SITE% -l "%LOCALDIR%" -R "%ROOTDIR%" -P %PACKAGES%

REM -- Show what we did
ECHO.
ECHO.
ECHO cygwin installation updated
ECHO  - %PACKAGES%
ECHO.

ENDLOCAL

EXIT /B 0
