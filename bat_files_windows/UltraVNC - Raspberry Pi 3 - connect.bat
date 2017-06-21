set vncfolder=O:\Programs\UltraVNC
set hostname=192.168.1.128
set port=5901
set pass=111222333111
set quality=2
:: 2 = LAN (> 1Mbit/s) Max Colors 
start "" "%vncfolder%\vncviewer.exe" -connect %hostname%::%port% -password %pass% -quickoption %quality%