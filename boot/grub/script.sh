#!/bin/bash

hostname=tester2
username=null
password=1511
timezone=Asia/Jakarta
drivpath=/dev/sda
efispath=/dev/sda5
bootpath=/dev/sda6
procpath=/dev/sda7
swappath=/dev/sda8
homepath=/dev/sda9

# root partition

yes | mkfs.ext4 $procpath &&
mount $procpath /mnt &&

# linux partition

yes | mkfs.ext4 $bootpath &&
mkdir -p /mnt/boot &&
mount $bootpath /mnt/boot &&

# efi partition


# swap partition

mkswap $swappath &&
swapon $swappath &&

# home partition

yes | mkfs.ext4 $homepath &&
mkdir -p /mnt/home &&
mount $homepath /mnt/home &&

# package

pacstrap /mnt base base-devel neovim linux-zen linux-firmware intel-ucode mkinitcpio efibootmgr os-prober grub iwd intel-ucode --noconfirm &&
genfstab -U /mnt >> /mnt/etc/fstab &&

# network

cp /etc/systemd/network/* /mnt/etc/systemd/network &&
mkdir -p /mnt/var/lib/iwd &&
cp /var/lib/iwd/*.psk /mnt/var/lib/iwd &&

# hostname

echo "$hostname" > /mnt/etc/hostname &&

# time

arch-chroot /mnt ln -sf /usr/share/zoneinfo/$timezone /mnt/etc/localtime &&
arch-chroot /mnt hwclock --systohc &&
arch-chroot /mnt timedatectl set-ntp true &&
arch-chroot /mnt timedatectl set-timezone $timezone &&
arch-chroot /mnt timedatectl status &&
arch-chroot /mnt timedatectl show-timesync --all &&


# locale

arch-chroot /mnt sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8' /mnt/etc/locale.gen &&
arch-chroot /mnt locale-gen &&

# user

arch-chroot /mnt useradd -m $username &&
arch-chroot /mnt echo $password | passwd $username --stdin &&
echo "$username ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers.d/nologin &&

# grub

arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch --modules="tpm --disable-shim-lock" &&
echo 'GRUB_DISABLE_OS_PROBER=false' >> /mnt/etc/default/grub &&

# mkinitcpio

mkdir -p /mnt/boot/kernel &&
rm -fr /mnt/boot/initramfs-* &&
mv /mnt/boot/*-ucode.img /mnt/boot/vmlinuz-linux-* /mnt/boot/kernel &&
mv -f /mnt/etc/mkinitcpio.conf /mnt/etc/mkinitcpio.d/default.conf &&
echo "#linux zen default" > /mnt/etc/mkinitcpio.d/default.conf &&
export CPIOHOOK="base systemd autodetect microcode kms keyboard block filesystem fsck" &&
printf "MODULE=()\nBINARIES=()\nFILES=()\nHOOKS=($CPIOHOOK)" >> /mnt/etc/mkinitcpio.d/default.conf &&

# efi

echo "#linux zen preset" > /mnt/etc/mkinitcpio.d/linux-zen.preset &&
echo 'ALL_config="/etc/mkinitcpio.d/default.conf"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
echo 'ALL_kver="/boot/kernel/vmlinuz-linux-zen"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
echo "PRESETS=('default')" >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
echo '#default_uki="/boot/efi/linux/arch-linux-zen.efi"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
arch-chroot /mnt mkinitcpio -P &&

# entries

cat << EOF >> /mnt/etc/grub.d/40_custom
menuentry "Arch Linux" {
    linux /kernel/vmlinuz-linux-zen root=UUID=$(blkid -s UUID -o value $procpath)
    initrd /kernel/intel-ucode.img
    initrd /initramfs-linux-zen.img
}
EOF &&

# generate grub

arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg