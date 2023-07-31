@ECHO OFF
echo rpi01
plink -batch -ssh sfernandez@192.168.0.28 -i ssh.ppk sudo nohup sh -c 'sleep 2; shutdown now' &
echo rpi02
plink -batch -ssh sfernandez@192.168.0.4 -i ssh.ppk sudo nohup sh -c 'sleep 2; shutdown now' &
echo rpi03
plink -batch -ssh sfernandez@192.168.0.5 -i ssh.ppk sudo nohup sh -c 'sleep 2; shutdown now' &
echo OpenWrt-Slate
plink -batch -ssh root@192.168.0.1 -i ssh.ppk sh -c 'sleep 2; halt' &
pause