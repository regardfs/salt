@echo off
@echo Salt Windows Build Package Script
@echo ----------------------------------------------------------------------
@echo.

:: Define Variables
@echo Defining Variables...
@echo ----------------------------------------------------------------------
Set "CurrDir=%cd%"
Set "BinDir=%cd%\buildenv\bin"
Set "InsDir=%cd%\installer"
Set "PreDir=%cd%\prereqs"
Set "PyDir27=C:\Python27"
Set "PyDir35=C:\Program Files\Python35"
Set "PyDir36=C:\Program Files\Python36"

:: Get the version from git if not passed
if [%1]==[] (
    for /f "delims=" %%a in ('git describe') do @set "Version=%%a"
) else (
    set "Version=%~1"
)

If Exist "%PyDir36%\python.exe" (
    Set "PyDir=%PyDir36%"
    Set "PyVerMajor=3"
    Set "PyVerMinor=6"
) Else (
    If Exist "%PyDir35%\python.exe" (
        Set "PyDir=%PyDir35%"
        Set "PyVerMajor=3"
        Set "PyVerMinor=5"
    ) Else (
        If Exist "%PyDir27%\python.exe" (
            Set "PyDir=%PyDir27%"
            Set "PyVerMajor=2"
            Set "PyVerMinor=7"
        ) Else (
            @echo Could not find Python on the system
            exit /b 1
        )
    )
)

:: Find the NSIS Installer
If Exist "C:\Program Files\NSIS\" (
    Set NSIS="C:\Program Files\NSIS\"
) Else (
    Set NSIS="C:\Program Files (x86)\NSIS\"
)
Set "PATH=%NSIS%;%PATH%"
@echo.

@echo Copying "%PyDir%" to bin...
@echo ----------------------------------------------------------------------
:: Check for existing bin directory and remove
If Exist "%BinDir%\" rd /S /Q "%BinDir%"

:: Copy the Python directory to bin
@echo xcopy /E /Q "%PyDir%" "%BinDir%\"
xcopy /E /Q "%PyDir%" "%BinDir%\"
@echo.

@echo Copying VCRedist 2008 MFC to Prerequisites
@echo ----------------------------------------------------------------------
:: Make sure the "prereq" directory exists
If NOT Exist "%PreDir%" mkdir "%PreDir%"

:: Check for 64 bit by finding the Program Files (x86) directory
Set Url64="http://repo.saltstack.com/windows/dependencies/64/vcredist_x64_2008_mfc.exe"
Set Url32="http://repo.saltstack.com/windows/dependencies/32/vcredist_x86_2008_mfc.exe"
If Exist "C:\Program Files (x86)" (
    bitsadmin /transfer "VCRedist 2008 MFC AMD64" "%Url64%" "%PreDir%\vcredist.exe"
) Else (
    bitsadmin /transfer "VCRedist 2008 MFC x86" "%Url32%" "%PreDir%\vcredist.exe"
)
@echo.

:: Remove the fixed path in .exe files
@echo Removing fixed path from .exe files
@echo ----------------------------------------------------------------------
"%PyDir%\python" "%CurrDir%\portable.py" -f "%BinDir%\Scripts\easy_install.exe"
"%PyDir%\python" "%CurrDir%\portable.py" -f "%BinDir%\Scripts\easy_install-%PyVerMajor%.%PyVerMinor%.exe"
"%PyDir%\python" "%CurrDir%\portable.py" -f "%BinDir%\Scripts\pip.exe"
"%PyDir%\python" "%CurrDir%\portable.py" -f "%BinDir%\Scripts\pip%PyVerMajor%.%PyVerMinor%.exe"
"%PyDir%\python" "%CurrDir%\portable.py" -f "%BinDir%\Scripts\pip%PyVerMajor%.exe"
@echo.

@echo Cleaning up unused files and directories...
@echo ----------------------------------------------------------------------
:: Remove all Compiled Python files (.pyc)
del /S /Q "%BinDir%\*.pyc" 1>nul
:: Remove all Compiled HTML Help (.chm)
del /S /Q "%BinDir%\*.chm" 1>nul
:: Remove all empty text files (they are placeholders for git)
del /S /Q "%BinDir%\..\empty.*" 1>nul

:: Delete Unused Docs and Modules
If Exist "%BinDir%\Doc"           rd /S /Q "%BinDir%\Doc"
If Exist "%BinDir%\share"         rd /S /Q "%BinDir%\share"
If Exist "%BinDir%\tcl"           rd /S /Q "%BinDir%\tcl"
If Exist "%BinDir%\Lib\idlelib"   rd /S /Q "%BinDir%\Lib\idlelib"
If Exist "%BinDir%\Lib\lib-tk"    rd /S /Q "%BinDir%\Lib\lib-tk"
If Exist "%BinDir%\Lib\test"      rd /S /Q "%BinDir%\Lib\test"
If Exist "%BinDir%\Lib\unit-test" rd /S /Q "%BinDir%\Lib\unit-test"

:: Delete Unused .dll files
If Exist "%BinDir%\DLLs\tcl85.dll"    del /S /Q "%BinDir%\DLLs\tcl85.dll"    1>nul
If Exist "%BinDir%\DLLs\tclpip85.dll" del /S /Q "%BinDir%\DLLs\tclpip85.dll" 1>nul
If Exist "%BinDir%\DLLs\tk85.dll"     del /S /Q "%BinDir%\DLLs\tk85.dll"     1>nul

:: Delete Unused .lib files
If Exist "%BinDir%\libs\_tkinter.lib" del /S /Q "%BinDir%\libs\_tkinter.lib" 1>nul

:: Delete .txt files
If Exist "%BinDir%\NEWS.txt"   del /q "%BinDir%\NEWS.txt"   1>nul
If Exist "%BinDir%\README.txt" del /q "%BinDir%\README.txt" 1>nul
@echo.

@echo Building the installer...
@echo ----------------------------------------------------------------------
makensis.exe /DSaltVersion=%Version% "%InsDir%\Salt-Minion-Setup.nsi"
makensis.exe /DSaltVersion=%Version% "%InsDir%\Salt-Setup.nsi"
@echo.

@echo.
@echo ======================================================================
@echo Script completed...
@echo ======================================================================
@echo Installation file can be found in the following directory:
@echo %InsDir%

:done
if [%Version%] == [] pause
