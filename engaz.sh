rm cubietruck.img
export BOARD=cubietruck
make $BOARD.img
dd if=cubietruck.img of=/dev/sdb
