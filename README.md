# Raspberry Pi VPN Router Setup

## Introduction

This is the first release of a script for setting up a Raspberri Pi as VPN router, using Raspbian.

This setup will yield a wireless network connected to Internet through the configured VPN; if the VPN connection falls for any reason, the internet connection will be unavailable until the VPN will be up again ("kill switch").

There are use cases where using a RPi as VPN router is very useful, for example, when offering an internet connection to tenants, or more generally, to clients of a business.

There are existing routers preconfigured with this functionality (WRT/Tomato), but:

- they have very limited hardware (CPU/RAM/disk) - I doubt they're powerful enough to handle 20+ MBit/sec of traffic
- they're not as easy to configure and use, and they has much less software available, compared to Debian-based distributions

On an Raspbian-based Raspberry Pi, you can trivially install for example, a local file hosting service, an FTP server, a backup server, or many other services, with great ease and availability of information.

### Requirements

The hardware requirements are:

- the ISP modem/router
- a Raspberry Pi
- a USB Ethernet dongle
- a Wifi access point

The software requirements are:

- a PrivateInternetAccess account (or any other VPN provider, although in this case, additional configuration may be required)

The procedure can be trivially adapted for any VPN provider.

I don't have any relation to PrivateInternetAccess, except that it's been the most reliable of all the VPN providers I've used. Of course, YMMV.

### Note on using RPi[s] as Wifi Access Point/Router

This is **not** a guide for setting up the RPi as Wifi access point+router (for example, using an USB Wifi dongle, or the RPi3 built-in Wifi module).

I have experience on several hardware setups (at least 5) with RPi in AP+router setup, and both the RPi integrated Wifi chip and USB Wifi dongles in general, are simply not cut for working as access point.

For reference, almost all the "it works!" configurations published on the internet, are written by people who didn't bother testing them for more than a few minutes. I did use those setups for weeks, and my current configuration is permanent.

I will elaborate on this subject further in the future.

## Execution

Simple configuration:

- prepare the card by downloading and executing the script:

    `curl https://raw.githubusercontent.com/saveriomiroddi/rpi_vpn_router/master/install_vpn_router.sh | sudo bash -`

- connect the ISP modem/router to the RPi internal ethernet port;
- insert the SD card and plug the ethernet dongle to the RPi, then boot it;
- connect the Wifi access point to the Ethernet dongle.

Enjoy the RPi VPN router!
