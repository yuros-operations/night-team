# pseudocode dualboot-grub
format root
mounting root
format boot
mounting boot
format swap
mounting swap
installasi package
copy configurasi network dari installer ke /mnt
pembuatan hostname
konfigurasi waktu
konfigurasi bahasa
buat user
install grub
konfigurasi mkinitcpio
penambahan entries
generate grub

## eror
sed: -e expression #1, char39: unterminated 's' command (solved)
passwd: user 'null' does not exist (solved)
echo: write error: broken pipe (solved)