# Raspberry Pi VPN Router Setup

## Introduction

Raspberry Pi VPN Router Setup is a shell program for setting up a Raspberri Pi as VPN router.

This setup will yield a wireless network connected to Internet through the configured VPN; if the VPN connection falls for any reason, the internet connection will be unavailable until the VPN will be up again ("kill switch").

There are use cases where using a RPi as VPN router is very useful, in particular, when offering an internet connection in a commercial context/location, or even at home.

There are existing routers preconfigured with this functionality (WRT/Tomato), but:

- they have very limited hardware (CPU/RAM/disk) - I doubt they're powerful enough to handle 20+ MBit/sec of traffic
- they're not as easy to configure and use, and they has much less software available, compared to Debian-based distributions

On an Raspbian-based Raspberry Pi, you can trivially install for example, a local file hosting service, an FTP server, a backup server, or many other services, with great ease and availability of information.

### Status

This project solved a very specific project of mine, so it's completed.

If anybody required support for another VPN provider, I'll be happy to work on it - just open an issue.

Since I have in plan to move to an RK3399-based board, I will also add support for it once I'll have it.

### Screenshots

![USB Devices menu](/screenshots/02_usb_device_menu.png?raw=true)
![Downloading Raspbian](/screenshots/03_download_raspbian.png?raw=true)
![Completed](/screenshots/04_completed.png?raw=true)

## Requirements

Knowledge:

- in the most basic functional form, only the VPN details are required
- the access point may need to be configured (or not, depending on the model); if it does, you will need to be able to open the administrative interface, and specify that DHCP must be used for the IP configuration

Hardware:

- the ISP modem/router
- a Raspberry Pi (any version supported by Raspbian)
- a USB Ethernet dongle
- a Wifi access point

Software/Services:

- VPN connection: you'll need a PrivateInternetAccess account (or any other VPN provider)
- host O/S: you can execute this application on any reasonably recent Ubuntu/Debian-based distro (it's been tested on an Ubuntu 16.04)

For other VPN providers, the procedure needs to be adapted; open a GitHub issue with the details, and I'll update the project.

I don't have any relation to PrivateInternetAccess, except that it's been the most reliable of all the VPN providers I've used. Of course, YMMV.

See the [specific wiki page](wiki/Using-RPi%5Bs%5D-as-Wifi-Access-Point-Router) for notes about using RPi in a single-device access point+router setup.

## Execution

Simple configuration:

- prepare the card by downloading and executing the script:

    `curl https://raw.githubusercontent.com/saveriomiroddi/rpi_vpn_router/master/install_vpn_router.sh | sudo bash -`

- connect the ISP modem/router to the RPi internal ethernet port;
- insert the SD card and plug the ethernet dongle to the RPi, then boot it;
- connect the Wifi access point to the Ethernet dongle

... now enjoy the RPi VPN router!

The credentials are the standard Raspbian [user: pi, password: raspberry].
