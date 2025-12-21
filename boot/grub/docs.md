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
grub config uefi grub single boot
  
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


## uji coba script v0.0.5
hasil: kesalahan pada konfigurasi custom entries grub
```
[root@archiso /]# grub-mkconfig -o /boot/grub/grub.cfg
Generating grub configuration file ...
Warning: os-prober will be executed to detect other bootable partitions.
Its output will be used to detect bootable binaries on them and create new boot entries.
Adding boot menu entry for UEFI Firmware Settings ...
error: grub-core/script/lexer.c:grub_script_yyerror:352:syntax error.
error: grub-core/script/lexer.c:grub_script_yyerror:352:Incorrect command.
error: grub-core/script/lexer.c:grub_script_yyerror:352:syntax error.
Syntax error at line 144
Syntax errors are detected in generated GRUB config file.
Ensure that there are no errors in /etc/default/grub
and /etc/grub.d/* files or please file a bug report with
/boot/grub/grub.cfg.new file attached.
```

## uji coba script v0.0.6
hasil: 
1. linux berhasil booting
2. windows tidak terbaca pada boot menu
3. user tidak bisa masuk karena password belum terbuat

## uji coba script v0.0.7
```/etc/grub.d/40_custom

menuentry "Arch efi single boot" {
    insmod fat
    insmod chain
    search --no-floppy --set=root --file /efi/linux/arch-linux-zen.efi
    chainloader /efi/linux/arch-linux-zen.efi
}
```

hasil: 
1. tidak berhasil booting
2. time out waiting for device /dev/gpt-auto-root

## uji coba script v0.0.8
1. menambahkan function cmdline ke dalam script

hasil: 
1. tidak berhasil booting
2. function cmdline tidak berjalan






