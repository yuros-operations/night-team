## pseudocode dualboot-grub
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

## uji joba script v.0.0.3
hasil: grub belum tergenerate


## uji coba script v0.0.4
hasil: error pada bagian menambahkan custom entry pada /etc/grub.d/40_custom

```
[root@archiso /]# grub-mkconfig -o /boot/grub/grub.cfg
Generating grub configuration file ...
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
/etc/grub.d/40_custom: line 2: menuentry: command not found
/etc/grub.d/40_custom: line 3: linux: command not found
/etc/grub.d/40_custom: line 4: initrd: command not found
/etc/grub.d/40_custom: line 5: initrd: command not found
/etc/grub.d/40_custom: line 6: syntax error near unexpected token `}'
/etc/grub.d/40_custom: line 6: `}'
```
