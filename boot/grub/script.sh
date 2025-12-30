hostname=tester2
username=null
password=1511 
timezone=Asia/Jakarta
drivpath=/dev/sda
efispath=/dev/sda1
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
    yes | mkfs.ext4 $bootpath &&
    mkdir -p /mnt/boot &&
    mount $bootpath /mnt/boot   
}

# efi partition
function create_efis {
    mkdir -p /mnt/boot/efi &&
    mount $efispath /mnt/boot/efi
}

# efi partition (partition efi in windows only)
# don't create the partition for linux
function create_efid {
    mkdir -p /mnt/boot &&
    mount $efispath /mnt/boot
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
    pacstrap /mnt base base-devel neovim linux-zen linux-firmware amd-ucode mkinitcpio efibootmgr os-prober grub iwd ntfs-3g sbctl --noconfirm &&
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
    arch-chroot /mnt passwd $username &&
    echo "$username ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers.d/nologin
}


# grub
function grub_install {
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch  &&
    echo "GRUB_DISABLE_OS_PROBER=false" >> /mnt/etc/default/grub &&
    echo "GRUB_DISABLE_SUBMENU=y" >> /mnt/etc/default/grub
}

# grub efi on windows
function grub_installw {
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch  --modules="tpm" --disable-shim-lock &&
    echo "GRUB_DISABLE_OS_PROBER=false" >> /mnt/etc/default/grub &&
    echo "GRUB_DISABLE_SUBMENU=y" >> /mnt/etc/default/grub
}

#cmdline
function cmdline {
    mkdir -p /mnt/etc/cmdline.d &&
    touch /mnt/etc/cmdline.d/{01-boot.conf,02-mods.conf,03-secs.conf,04-perf.conf,05-misc.conf} &&
    echo "root=UUID=$(blkid -s UUID -o value $procpath)" > /mnt/etc/cmdline.d/01-boot.conf
}

# mkinitcpio
function mkinitcpio {
    mkdir -p /mnt/boot/kernel &&
    mkdir -p /mnt/boot/efi/EFI/linux &&
    rm /mnt/boot/initramfs-* &&
    mv /mnt/boot/*-ucode.img /mnt/boot/vmlinuz-linux-* /mnt/boot/kernel &&
    mv -f /mnt/etc/mkinitcpio.conf /mnt/etc/mkinitcpio.d/default.conf &&
    echo "#linux zen default" > /mnt/etc/mkinitcpio.d/default.conf &&
    export CPIOHOOK="base systemd autodetect microcode kms keyboard block filesystems fsck" &&
    printf "MODULE=()\nBINARIES=()\nFILES=()\nHOOKS=($CPIOHOOK)" >> /mnt/etc/mkinitcpio.d/default.conf
}


function grub-hooks {
   mkdir -p /mnt/etc/pacman.d/hooks &&
   cp -r /install/etc/pacman.d/hooks/90-grub-update.hook /mnt/etc/pacman.d/hooks/
}

# efi
function efi {
    echo "#linux zen preset" > /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo 'ALL_config="/etc/mkinitcpio.d/default.conf"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo 'ALL_kver="/boot/kernel/vmlinuz-linux-zen"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo "PRESETS=('default')" >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo 'default_uki="/boot/efi/EFI/linux/arch-linux-zen.efi"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
}

function efi-lts {
    echo "#linux lts preset" > /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo 'ALL_config="/etc/mkinitcpio.d/default.conf"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo 'ALL_kver="/boot/kernel/vmlinuz-linux-lts"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo "PRESETS=('default')" >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo 'default_uki="/boot/efi/EFI/linux/arch-linux-lts.efi"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
}

function efi-linux {
    echo "#linux preset" > /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo 'ALL_config="/etc/mkinitcpio.d/default.conf"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo 'ALL_kver="/boot/kernel/vmlinuz-linux"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo "PRESETS=('default')" >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo 'default_uki="/boot/efi/EFI/linux/arch-linux.efi"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    arch-chroot /mnt mkinitcpio -P
}

# entries with initramfs
function entries_initramfs {
cat << EOF >> /mnt/etc/grub.d/40_custom
menuentry "Arch-zen" {
    linux /kernel/vmlinuz-linux-zen root=$procpath rw
    initrd /kernel/amd-ucode.img
    initrd /initramfs-linux-zen.img 
}
EOF
}

# entries with efi
function entries {
cat << EOF >> /mnt/etc/grub.d/40_custom
menuentry "Arch zen efi" {
        insmod fat
        insmod chain
        search --no-floppy --set=root --file /EFI/linux/arch-linux-zen.efi 
        chainloader /EFI/linux/arch-linux-zen.efi
}
menuentry "Arch lts efi" {
        insmod fat
        insmod chain
        search --no-floppy --set=root --file /EFI/linux/arch-linux-lts.efi 
        chainloader /EFI/linux/arch-linux-lts.efi
}
menuentry "Arch linux efi" {
        insmod fat
        insmod chain
        search --no-floppy --set=root --file /EFI/linux/arch-linux.efi 
        chainloader /EFI/linux/arch-linux.efi
}
EOF
}

# generate grub
function gen_grub {
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

function secure {
    arch-chroot /mnt sbctl create-keys &&
    arch-chroot /mnt sbctl enroll-keys -m -f &&
    arch-chroot /mnt sbctl sign --save /boot/efi/EFI/Arch/grubx64.efi &&
    arch-chroot /mnt sbctl sign --save /boot/kernel/vmlinuz-linux-zen &&
    arch-chroot /mnt sbctl sign --save /boot/efi/EFI/linux/arch-linux-zen.efi &&
    arch-chroot /mnt sbctl sign --save /boot/efi/EFI/linux/arch-linux-lts.efi &&
    arch-chroot /mnt sbctl sign --save /boot/efi/EFI/linux/arch-linux.efi &&
    arch-chroot /mnt sbctl sign --save /boot/grub/x86_64-efi/core.efi &&
    arch-chroot /mnt sbctl sign --save /boot/grub/x86_64-efi/grub.efi
}


function runscript {
    echo "configure proc"
    create_proc
    clear &&
    sleep 5

    echo "configure boot"
    create_boot
    clear &&
    sleep 5

    echo "configure efi"
    create_efis
    clear &&
    sleep 5

        #echo "configure efi on windows"
        #create_efid
        #clear &&
        #sleep 2

    echo "configure swap"
    create_swap
    clear &&
    sleep 5

    echo "configure home"
    create_home
    clear &&
    sleep 5

    echo "installing packages"
    packages
    clear &&
    sleep 5

    echo "configure network"
    network
    clear &&
    sleep 5

    echo "configure hosname"
    hostname
    clear &&
    sleep 5    

    echo "configure time"
    gentime
    clear &&
    sleep 5

    echo "configure locale"
    locale
    clear &&
    sleep 5

    echo "configure user"
    user
    clear &&
    sleep 5

    echo "generate grub"
    grub_installw
    clear &&
    sleep 10

    echo "configure cmdline"
    cmdline
    clear &&
    sleep 10

    echo "configure grub hooks"
    grub-hooks
    clear &&
    sleep 10    

    echo "configure mkinitcpio"
    mkinitcpio
    clear &&
    sleep 10

        #echo "configure mkinitcpiod"
        #mkinitcpiod
        #clear &&
        #sleep 2

    echo "configure efi"
    efi
    efi-lts
    efi-linux
    clear &&
    sleep 10

        #echo "configure efi on windows"
        #efi-windows
        #clear &&
        #sleep 2

    echo "configure entries"
    entries
    clear &&
    sleep 10

    echo "configure grub boot"
    gen_grub
    clear &&
    sleep 10

    echo "configure secure boot"
    secure
    clear &&
    sleep 10
}


runscript


























