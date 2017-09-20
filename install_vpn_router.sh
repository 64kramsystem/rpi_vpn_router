#!/bin/bash

set -o errexit

# VARIABLES/CONSTANTS ##########################################################

c_project_repository_link=https://github.com/saveriomiroddi/rpi_vpn_router.git
c_ubuntu_image_address=https://www.finnie.org/software/raspberrypi/ubuntu-rpi3/ubuntu-16.04-preinstalled-server-armhf+raspi3.img.xz
c_data_dir_mountpoint=/mnt

# There are no clean solutions in bash fo capturing multiple return values,
# so for this case, globals are ok, esprcially considering that processing
# is performed in a strictly linear fashion (no reassignments, etc.).
v_temp_path=
v_sdcard_device=
v_rpi_static_ip_on_modem_net=
v_pia_user=
v_pia_password=
v_pia_server=
v_pia_dns_server_1=
v_pia_dns_server_2=
v_local_image_filename=

# HELPERS ######################################################################

function find_usb_storage_devices {
  for device in /sys/block/*; do
    usb_storages_info=$(udevadm info --query=property --path=$device)

    if echo "$usb_storages_info" | grep -q ^ID_BUS=usb; then
      devname=$(echo "$usb_storages_info" | grep ^DEVNAME= | perl -pe 's/DEVNAME=//')
      model=$(echo "$usb_storages_info" | grep ^ID_MODEL= | perl -pe 's/ID_MODEL=//')
      v_usb_storage_devices[$devname]=$model
    fi
  done
}

# MAIN FUNCTIONS ###############################################################

function print_intro {
  whiptail --title "Intro" --msgbox "Hello! This script will prepare an SDCard for using un a RPi3 as VPN router." 30 100
}

# TODO: add space check
function ask_temp_path {
  v_temp_path=$(whiptail --inputbox 'Enter the temporary directory (requires about 255 MiB of free space).
If left blank, `/tmp` will be used.' 30 100 3>&1 1>&2 2>&3)

  if [[ "$v_temp_path" == "" ]]; then
    v_temp_path="/tmp"
  fi
}

function ask_sdcard_device {
  declare -A v_usb_storage_devices

  while [[ "$v_sdcard_device" == "" || ${v_usb_storage_devices[$v_sdcard_device]} == "" ]]; do
    find_usb_storage_devices

    local message=$'Enter the SDCard device (eg. `/dev/sdc`). THE DEVICE WILL BE COMPLETELY ERASED.\n\n'

    if [[ ${#v_usb_storage_devices[@]} > 0 ]]; then
      message+=$'Available (USB) devices:\n\n'

      for dev in "${!v_usb_storage_devices[@]}"; do
        message+="$dev -> ${v_usb_storage_devices[$dev]}
"
      done
    else
      message+="No (USB) devices found. Plug one and press Enter."
    fi

    v_sdcard_device=$(whiptail --inputbox "$message" 30 100 3>&1 1>&2 2>&3);
  done

  unset v_usb_storage_devices
}

function ask_rpi_static_ip_on_modem_net {
  while [[ ! $v_rpi_static_ip_on_modem_net =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; do
    v_rpi_static_ip_on_modem_net=$(whiptail --inputbox $'Enter the RPi static IP on the modem network (eth0 on the RPi)' 30 100 3>&1 1>&2 2>&3)
  done
}

function ask_pia_data {
  while [[ "$v_pia_user" == "" ]]; do
    v_pia_user=$(whiptail --inputbox $'Enter the PrivateInternetAccess user' 30 100 3>&1 1>&2 2>&3)
  done

  while [[ "$v_pia_password" == "" ]]; do
    v_pia_password=$(whiptail --inputbox $'Enter the PrivateInternetAccess password' 30 100 3>&1 1>&2 2>&3)
  done

  while [[ "$v_pia_server" == "" ]]; do
    v_pia_server=$(whiptail --inputbox 'Enter the PrivateInternetAccess server (eg. germany.privateinternetaccess.com).
You can find the list at https://www.privateinternetaccess.com/pages/network' 30 100 3>&1 1>&2 2>&3)
  done

  v_pia_dns_server_1=$(whiptail --inputbox 'Enter the PrivateInternetAccess DNS server 1 IP.
If left blank, the default PIA DNS 1 will be set (209.222.18.222)' 30 100 3>&1 1>&2 2>&3)

  if [[ "$v_pia_dns_server_1" == "" ]]; then
    v_pia_dns_server_1="209.222.18.222"
  fi

  v_pia_dns_server_2=$(whiptail --inputbox 'Enter the PrivateInternetAccess DNS server 2 IP.
If left blank, the default PIA DNS 2 will be set (209.222.18.218)' 30 100 3>&1 1>&2 2>&3)

  if [[ "$v_pia_dns_server_2" == "" ]]; then
    v_pia_dns_server_2="209.222.18.218"
  fi
}

function download_and_process_required_data {
  v_local_image_filename="$v_temp_path/${c_ubuntu_image_address##*/}"

  wget -cO "$v_local_image_filename" "$c_ubuntu_image_address" 2>&1 | \
   stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
   whiptail --gauge "Downloading Ubuntu image..." 30 100 0

  rm -rf "$v_temp_path/rpi_vpn_router"

  git clone "$c_project_repository_link" "$v_temp_path/rpi_vpn_router"

  find "$v_temp_path/rpi_vpn_router"/* -type d -exec chmod 755 {} \;
  find "$v_temp_path/rpi_vpn_router"/* -type f -name '*.sh' -exec chmod 755 {} \;
  find "$v_temp_path/rpi_vpn_router"/* -type f -not -name '*.sh' -exec chmod 644 {} \;
}

function unmount_sdcard_partitions {
  if [[ $(mount | grep "^$v_sdcard_device") ]]; then
    for partition in $(mount | grep ^$v_sdcard_device | awk '{print $1}'); do
      umount "$partition" 2> /dev/null || true
    done
  fi

  while [[ $(mount | grep "^$v_sdcard_device") ]]; do
    local message=$'There are still some partitions mounted in the sdcard device that couldn\'t be unmounted:\n\n'

    while IFS=$'\n' read -r partition_data; do
      echo $partition_data
      local partition_description=$(echo $partition_data | awk '{print $1 " " $2 " " $3}')
      message+="$partition_description
"
    done <<< "$(mount | grep "^$v_sdcard_device")"

    message+=$'\nPlease unmount them, then press Enter.'

    whiptail --yesno "$message" 30 100
  done
}

function burn_image {
  local image_filename="$v_temp_path/${c_ubuntu_image_address##*/}"
  local file_size=$(stat -c "%s" $image_filename)

  (cat "$image_filename" | pv -n -s "$file_size" | xzcat > "$v_sdcard_device") 2>&1 | whiptail --gauge "Burning the image on the SD card..." 30 100 0
}

function mount_data_partition {
  # Need to wait a little bit for the OS to recognize the device and the partitions...
  #
  while [[ ! -e "${v_sdcard_device}2" ]]; do
    sleep 0.5
  done

  # Wait a little bit! Otherwise, trying to mount will make a mess - it may fail
  # and cause the devices disconnection (!).
  sleep 1

  # If the automount kicked in already (which is unlikely), unmount the partition.
  if [[ $(mount | grep "^${v_sdcard_device}2") ]]; then
    umount "${v_sdcard_device}2"
  fi

  mount "${v_sdcard_device}2" "$c_data_dir_mountpoint"
}

function copy_configuration_files {
  rsync --recursive --links --perms \
    --exclude=.git --exclude=README.md --exclude=install_vpn_router.sh \
    "$v_temp_path/rpi_vpn_router/" "$c_data_dir_mountpoint"
}

function update_configuration_files {
  # Setup the PIA configuration
  perl -i -pe "s/__PIA_USER__/$v_pia_user/" "$c_data_dir_mountpoint/etc/openvpn/pia/auth.conf"
  perl -i -pe "s/__PIA_PASSWORD__/$v_pia_password/" "$c_data_dir_mountpoint/etc/openvpn/pia/auth.conf"
  perl -i -pe "s/__PIA_SERVER_ADDRESS__/$v_pia_server/" "$c_data_dir_mountpoint/etc/openvpn/pia/default.ovpn"

  # Fix the hosts file - the localhost name is currently missing from the image.
  [[ ! $(grep ubuntu "$c_data_dir_mountpoint/etc/hosts") ]] && echo '127.0.0.1 ubuntu' >> "$c_data_dir_mountpoint/etc/hosts"

  # Setup the networking
  local modem_ip=$(perl -pe 's/\.\d+$/.1/' <<< "$v_rpi_static_ip_on_modem_net")
  perl -i -pe "s/__MODEM_NET_RPI_IP__/$v_rpi_static_ip_on_modem_net/" "$c_data_dir_mountpoint/etc/network/interfaces"
  perl -i -pe "s/__MODEM_IP__/$modem_ip/" "$c_data_dir_mountpoint/etc/network/interfaces"
  perl -i -pe "s/__PIA_DNS_SERVER_1__/$v_pia_dns_server_1/" "$c_data_dir_mountpoint/etc/dnsmasq.d/eth1-access-point-net.conf"
  perl -i -pe "s/__PIA_DNS_SERVER_2__/$v_pia_dns_server_2/" "$c_data_dir_mountpoint/etc/dnsmasq.d/eth1-access-point-net.conf"

  # Disable the automatic update, due to a critical bug in the distro.
  # See https://bugs.launchpad.net/ubuntu-pi-flavour-maker/+bug/1697637
  #
  perl -i -pe 's/"1"/"0"/' "$c_data_dir_mountpoint/etc/apt/apt.conf.d/20auto-upgrades"
}

function eject_sdcard {
  eject "$v_sdcard_device"
}

function print_first_boot_instructions {
  whiptail --title "Intro" --msgbox "The SD card is ready.

Insert it in the RPi, then execute:

    sudo apt update
    sudo apt install -y openvpn dnsmasq
    sudo systemctl enable openvpn-pia
    sudo reboot

Enjoy your RPI3 VPN router!
" 30 100
}

# MAIN #########################################################################

print_intro
ask_temp_path
ask_sdcard_device
ask_rpi_static_ip_on_modem_net
ask_pia_data

download_and_process_required_data
unmount_sdcard_partitions
burn_image

mount_data_partition
copy_configuration_files
update_configuration_files
eject_sdcard

print_first_boot_instructions
