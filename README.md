# Raspberry Pi VPN Router Setup

## Introduction

This is the first release of the procedure for setting up a Raspberri Pi (3) as VPN router

This setup will yield a wireless network connected to Internet through the configured VPN; if the VPN connection falls for any reason, the internet connection will be unavailable until the VPN will be up again ("kill switch").

There are use cases where using a RPi as VPN router is very useful, for example, when offering an internet connection to tenants, or more generally, to clients of a business.

There are existing routers preconfigured with this functionality (WRT/Tomato), but:

- they're very weak for the VPN (or for any software in generale); I doubt they're powerful enough to handle 20+ MBit/sec of traffic;
- they're not as easy to configure, or to install programs onto.

You can trivially install for example, in addition to the VPN service, a local file hosting service, an FTP server, or anything else.

### Requirements

The hardware requirements are:

- the ISP modem/router
- an RPi3
- a USB Ethernet dongle
- a Wifi access point

The software requirements are:

- a PrivateInternetAccess account

The procedure can be trivially adapted for any RPi and any VPN provider.

I don't have any relation to PrivateInternetAccess, except that it's been the most reliable of all the VPN providers I've used. Of course, YMMV.

### Note on using RPi[s] as Wifi Access Point/Route

This is **not** a guide for setting up the RPi as Wifi access point+router.

I have a significant experience (at least 5 different setups) with RPi in AP+router setup, and both the RPi integrated Wifi chip and USB Wifi dongles in general, are simply not cut for working as access point.

I will elaborate on this subject further in the future.

## Execution

Preparation:

- connect the ISP modem/router to the RPi internal ethernet port
- take note of the modem/router subnet
- plug the Ethernet dongle to the RPi
- connect the Wifi access point to the Ethernet dongle
- configure the access point Ethernet-side connection (subnet/ip/gateway), using an ip that does *not* end with `.1` (that will be the RPi)

Fill with relevant data:

    export ROUTER_SETUP_PATH=$HOME/rpi_vpn_router_setup     # RPi image and setup files will be downloaded here
    export SDCARD_DRIVE=/dev/sdX                            # path of the sdcard device. BE VERY CAREFUL!!
    export MODEM_SIDE_RPI_IP=192.168.X.Y                    # RPi IP address on the side of the modem/router; eth0 on the RPi
    export ACCESS_POINT_SIDE_RPI_IP=192.168.Z.1             # RPi IP address on the side of the Wifi access point; eth1 (USB network adapter) on the RPi
    export PIA_USER=foo
    export PIA_PASSWORD=bar
    export PIA_SERVER=baz.privateinternetaccess.com         # list here: https://www.privateinternetaccess.com/pages/network

Prepare data:

    mkdir $ROUTER_SETUP_PATH && cd $ROUTER_SETUP_PATH
    
    wget https://www.finnie.org/software/raspberrypi/ubuntu-rpi3/ubuntu-16.04-preinstalled-server-armhf+raspi3.img.xz
    git clone git@github.com:saveriomiroddi/rpi_vpn_router.git

Sudo time!:

    # Paranoid users can pass all the variables instead of using `-E`, although the
    # operations executed as sudo are trivial.
    sudo -E su

Write the image to the sdcard and mount the partition:

    xz -dc ubuntu-16.04-preinstalled-server-armhf+raspi3.img.xz | dd of=$SDCARD_DRIVE
    umount ${SDCARD_DRIVE}2 2> /dev/null    # dismount if automount kicks in!
    mount ${SDCARD_DRIVE}2 /mnt

Write the configuration files:

    # Copy the configuration files
    rsync --recursive --links --perms --exclude=.git --exclude=README.md $ROUTER_SETUP_PATH/rpi_vpn_router/ /mnt
    
    # Setup the PIA configuration
    perl -i -pe "s/__PIA_USER__/$PIA_USER/" /mnt/etc/openvpn/pia/auth.conf
    perl -i -pe "s/__PIA_PASSWORD__/$PIA_PASSWORD/" /mnt/etc/openvpn/pia/auth.conf
    perl -i -pe "s/__PIA_SERVER_ADDRESS__/$PIA_SERVER/" /mnt/etc/openvpn/pia/default.ovpn
    
    # Fix the hosts file - the localhost name is currently missing from the image.
    [[ ! $(grep ubuntu /mnt/etc/hosts) ]] && echo '127.0.0.1 ubuntu' >> /mnt/etc/hosts
    
    # Setup the networking
    export MODEM_IP=$(perl -pe 's/\.\d+$/.1/' <<< $MODEM_SIDE_RPI_IP)
    perl -i -pe "s/__MODEM_SIDE_RPI_IP__/$MODEM_SIDE_RPI_IP/" /mnt/etc/network/interfaces
    perl -i -pe "s/__MODEM_IP__/$MODEM_IP/" /mnt/etc/network/interfaces
    perl -i -pe "s/__ACCESS_POINT_SIDE_RPI_IP__/$ACCESS_POINT_SIDE_RPI_IP/" /mnt/etc/network/interfaces
    
    # Disable the automatic update, due to a critical bug (see https://bugs.launchpad.net/ubuntu-pi-flavour-maker/+bug/1697637)
    #
    perl -i -pe 's/"1"/"0"/' /mnt/etc/apt/apt.conf.d/20auto-upgrades
    
    # Finished!
    eject $SDCARD_DRIVE

Now, insert the SD card in the RPi, turn it on, and logon.  
The system will start an autoupdate; it can be checked using

    watch -n 1 'pgrep -a dpkg'

Attempts to update the apt cache and/or to install any package will result in `Could not get lock /var/lib/dpkg/lock`.

Once the update is completed, install openvpn and reboot:

    apt install -y openvpn
    reboot

Enjoy the RPI3 VPN router!
