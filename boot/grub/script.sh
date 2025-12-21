hostname=tester2
username=null
password=1511 
timezone=Asia/Jakarta
drivpath=/dev/sda
efispath=
bootpath=/dev/sda5
procpath=/dev/sda6
swappath=/dev/sda7
homepath=/dev/sda8


# root partition
function create_proc {
    yes | mkfs.ext4 $procpath &&
    mount $procpath /mnt
}


# linux partition
function create_boot {
    yes | mkfs.vfat -F32 $bootpath &&
    mkdir -p /mnt/boot &&
    mount $bootpath /mnt/boot   
}

# swap partition
function create_swap {
    mkswap $swappath &&
    swapon $swappath
}


# home partition
function create_home {
    yes | mkfs.ext4 $homepath &&
    mkdir -p /mnt/home &&
    mount $homepath /mnt/home
}


# package
function packages {
    pacstrap /mnt base base-devel neovim linux-zen linux-firmware amd-ucode mkinitcpio efibootmgr os-prober grub iwd --noconfirm &&
    genfstab -U /mnt >> /mnt/etc/fstab
}


# network
function network {
    cp /etc/systemd/network/* /mnt/etc/systemd/network &&
    mkdir -p /mnt/var/lib/iwd &&
    cp /var/lib/iwd/*.psk /mnt/var/lib/iwd
}


# hostname
function hostname {
    echo "$hostname" > /mnt/etc/hostname
}


# time
function gentime {
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/$timezone /mnt/etc/localtime &&
    arch-chroot /mnt hwclock --systohc &&
    arch-chroot /mnt timedatectl set-ntp true &&
    arch-chroot /mnt timedatectl set-timezone $timezone &&
    arch-chroot /mnt timedatectl status &&
    arch-chroot /mnt timedatectl show-timesync --all
}


# locale
function locale {
    arch-chroot /mnt sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /mnt/etc/locale.gen &&
    arch-chroot /mnt locale-gen
}


# user
function user {
    arch-chroot /mnt useradd -m $username &&
    arch-chroot /mnt "echo $username:$password" | chpasswd &&
    echo "$username ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers.d/nologin
}


# grub
function grub_install {
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch  &&
    echo "GRUB_DISABLE_OS_PROBER=false" >> /mnt/etc/default/grub

}

#cmdline
function cmdline {
    mkdir -p /etc/cmdline.d
    touch /etc/cmdline.d/{01-boot.conf,02-mods.conf,03-secs.conf,04-perf.conf,05-misc.conf}
    echo "root=UUID=$(blkid -s UUID -o value $procpath)" > /etc/cmdline.d/01-boot.conf
}

# mkinitcpio
function mkinitcpio {
    mkdir -p /mnt/boot/kernel &&
    rm -fr /mnt/boot/initramfs-* &&
    mv /mnt/boot/*-ucode.img /mnt/boot/vmlinuz-linux-* /mnt/boot/kernel &&
    mv -f /mnt/etc/mkinitcpio.conf /mnt/etc/mkinitcpio.d/default.conf &&
    echo "#linux zen default" > /mnt/etc/mkinitcpio.d/default.conf &&
    export CPIOHOOK="base systemd autodetect microcode kms keyboard block filesystem fsck" &&
    printf "MODULE=()\nBINARIES=()\nFILES=()\nHOOKS=($CPIOHOOK)" >> /mnt/etc/mkinitcpio.d/default.conf
}


# efi
function efi {
    echo "#linux zen preset" > /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo 'ALL_config="/etc/mkinitcpio.d/default.conf"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo 'ALL_kver="/boot/kernel/vmlinuz-linux-zen"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo "PRESETS=('default')" >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo '#default_image="/boot/initramfs-linux-zen.img"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo 'default_uki="/boot/efi/linux/arch-linux-zen.efi"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    arch-chroot /mnt mkinitcpio -P
}


# entries
function entries {
cat << EOF >> /mnt/etc/grub.d/40_custom
menuentry "Arch efi single boot" {
        insmod fat
        insmod chain
        search --no-floppy --set=root --file /efi/linux/arch-linux-zen.efi
        chainloader /efi/linux/arch-linux-zen.efi
}
EOF
}


# generate grub
function gen_grub {
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}


function runscript {
    echo "configure proc"
    create_proc
    clear &&
    sleep 2

    echo "configure boot"
    create_boot
    clear &&
    sleep 2

    echo "configure swap"
    create_swap
    clear &&
    sleep 2

    echo "configure home"
    create_home
    clear &&
    sleep 2

    echo "installing packages"
    packages
    clear &&
    sleep 2

    echo "configure network"
    network
    clear &&
    sleep 2

    echo "configure hosname"
    hostname
    clear &&
    sleep 2    

    echo "configure time"
    gentime
    clear &&
    sleep 2

    echo "configure locale"
    locale
    clear &&
    sleep 2

    echo "configure user"
    user
    clear &&
    sleep 2

    echo "generate grub"
    grub_install
    clear &&
    sleep 2

    echo "configure cmdline"
    cmdline
    clear &&
    sleep 2

    echo "configure mkinitcpio"
    mkinitcpio
    clear &&
    sleep 2

    echo "configure efi"
    efi
    clear &&
    sleep 2

    echo "configure entries"
    entries
    clear &&
    sleep 2

    echo "configure grub boot"
    gen_grub
    clear &&
    sleep 2
}


runscript


