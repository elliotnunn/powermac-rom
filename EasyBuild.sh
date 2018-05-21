#!/bin/sh

# Uncomment this block to use https://github.com/elliotnunn/mac-rom

# echo "> Diving into mac-rom repo"
# cd ../mac-rom
# ./EasyBuild.sh
# cmp -s BuildResults/RISC/Image/RomMondo "$OLDPWD/RomMondo.bin" || cp BuildResults/RISC/Image/RomMondo "$OLDPWD/RomMondo.bin"
# cd "$OLDPWD"
# echo "< Done with mac-rom repo"


# Avoid the uber-slow step of running the emulator when nothing has changed

if [ ! -f BuildResults/PowerROM ]
then
	echo "PowerROM not yet built"
	echo "> Starting emulator to build PowerROM"
	empw -b EasyBuild
	echo "< Emulator done"
	exit
fi

echo "Checking for files updated since PowerROM"
find **/*.s *.s *.x *.bin -newer BuildResults/PowerROM | grep . || exit 0

echo "> Starting emulator to build PowerROM"
empw -b EasyBuild
echo "< Emulator done"
