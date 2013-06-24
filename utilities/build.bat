@ECHO OFF
set srcdir=..\source
set builddir=..\build
set scriptname=uteml.sql

ECHO.                         >  "%builddir%\%scriptname%"
ECHO.SET DEFINE OFF           >> "%builddir%\%scriptname%"
ECHO.                         >> "%builddir%\%scriptname%"
type "%srcdir%\UTL_EMAIL.pks" >> "%builddir%\%scriptname%"
ECHO.SHOW ERRORS              >> "%builddir%\%scriptname%"
ECHO.                         >> "%builddir%\%scriptname%"
type "%srcdir%\UTL_EMAIL.pkb" >> "%builddir%\%scriptname%"
ECHO.SHOW ERRORS              >> "%builddir%\%scriptname%"
ECHO.                         >> "%builddir%\%scriptname%"
