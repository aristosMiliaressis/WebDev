@echo off
setlocal EnableDelayedExpansion

echo 1) Add entry to hosts file
echo 2) Add firewall rule
echo 3) Setup new site

:main_menu
echo .
set /P option="Choose option: "

if %option% == 1 (
	goto :add_to_hosts
) else if %option% == 2 (
	goto :add_fw_rule
) else if not %option% == 3 (
	goto :main_menu
)

:cont
echo .
set /P sitename="Enter host name of site: "
set /P directory="Enter project directory: "

echo .
echo 1) https only
echo 2) http only
echo 3) both http and https

:choose_binding
echo .
set /P binding="Choose binding options: "

if %binding% NEQ 1 ( 
	if %binding% NEQ 2 ( 
		if %binding% NEQ 3 (
			goto :choose_binding
)))

echo .
set /P port="Change default port (Y/N): "

set custom_port=0
set fw_allow_all=0

if %port% == Y (
	goto :change_port
) else if %port% == y (
	goto :change_port
)
echo .

:continue
if %binding% == 1 ( 
	if %custom_port% == 1 (
		if %fw_allow_all% == 1 (
			set binding=https/*:%port%:
		) else (
			set binding=https/*:%port%:%sitename%
		)
	) else (
		set binding=https/*:443:%sitename%
	)
) else if %binding% == 2 (
	if %custom_port% == 1 (
		if %fw_allow_all% == 1 (
			set binding=http/*:%port%:
		) else (
			set binding=http/*:%port%:%sitename%
		)
	) else (
		set binding=http/*:80:%sitename%
	)
) else if %binding% == 3 (
	if %custom_port% == 1 (
		if %fw_allow_all% == 1 (
			set binding=http/*:%port%:,https/*:%port%:
		) else (
			set binding=http/*:%port%:%sitename%,https/*:%port%:%sitename%
		)
		
	) else (
		set binding=http/*:80:%sitename%,https/*:443:%sitename%
	)
)

REM Create IIS site
%systemroot%\system32\inetsrv\appcmd add site /name:"%sitename%" /physicalPath:"%directory%" /bindings:%binding% > nul

REM Attempt to migrate config to IIS7 style
%systemroot%\system32\inetsrv\appcmd migrate config "%sitename%/" > nul

REM Start new site
%systemroot%\system32\inetsrv\appcmd start site "%sitename%" > nul

REM add entry in hosts file
echo 127.0.0.1	%sitename% >> %systemroot%\system32\drivers\etc\hosts

echo Added %sitename% to hosts file.
echo site %sitename% now running...

goto :end


:change_port
set custom_port=1
echo .
set /P port="Enter port number: "

echo .
set /P fw="Add firewall rule to allow all incoming on port %port% (Y/N): "

if not %fw% == "Y" ( if not %fw% == "y" (
	goto :continue
))

set fw_allow_all=1
set rule_name="Open Port %port%"

REM add firewall rula to allow all connections to %port% 
netsh advfirewall firewall add rule name=%rule_name% dir=in action=allow protocol=TCP localport=%port% > nul
echo .
echo Added firewall rule.

goto :continue


:add_fw_rule
echo .
set /P port="Enter port number: "
set rule_name="Open Port %port%"

REM add firewall rula to allow all connections to %port% 
netsh advfirewall firewall add rule name=%rule_name% dir=in action=allow protocol=TCP localport=%port% > nul
echo .
echo Added firewall rule.
goto :end


:add_to_hosts
echo .
set /P sitename="Enter host name of site: "

REM add entry in hosts file
echo 127.0.0.1	%sitename% >> %systemroot%\system32\drivers\etc\hosts
echo Added %sitename% to hosts file.

goto :end


:end
echo .
pause