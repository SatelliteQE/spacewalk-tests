#!/usr/bin/python

import random

ENUM_CLASS = ['USB', 'DMI', 'NETINFO', 'OTHER', 'VIDEO',
              'MEMORY', 'NETINTERFACES', 'SCSI', 'CPU', 'HD']

json_data = [
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "330B", "prop1": "8086", "prop2": "3406",
        "prop3": "103C", "detached": "0", "class": "OTHER", "desc": "Intel Corporation|5520 I/O Hub to ESI Port"},
    {"bus": "pci", "driver": "pcieport", "pciType": "1", "prop4": "330B", "prop1": "8086", "prop2": "340C", "prop3": "103C",
        "detached": "0", "class": "OTHER", "desc": "Intel Corporation|5520/X58 I/O Hub PCI Express Root Port 5"},
    {"bus": "pci", "driver": "igb", "pciType": "1", "prop4": "323F", "prop1": "8086", "prop2": "10C9", "prop3": "103C",
        "detached": "0", "class": "OTHER", "desc": "Intel Corporation|82576 Gigabit Network Connection"},
    {"bus": "pci", "driver": "igb", "pciType": "1", "prop4": "323F", "prop1": "8086", "prop2": "10C9", "prop3": "103C",
        "detached": "0", "class": "OTHER", "desc": "Intel Corporation|82576 Gigabit Network Connection"},
    {"bus": "pci", "driver": "pcieport", "pciType": "1", "prop4": "330B", "prop1": "8086", "prop2": "340E", "prop3": "103C",
        "detached": "0", "class": "OTHER", "desc": "Intel Corporation|5520/5500/X58 I/O Hub PCI Express Root Port 7"},
    {"bus": "pci", "driver": "i7core_edac", "pciType": "1", "prop4": "000B", "prop1": "8086", "prop2": "342E", "prop3": "003C",
        "detached": "0", "class": "OTHER", "desc": "Intel Corporation|7500/5520/5500/X58 I/O Hub System Management Registers"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "000B", "prop1": "8086", "prop2": "3422", "prop3": "003C",
        "detached": "0", "class": "OTHER", "desc": "Intel Corporation|7500/5520/5500/X58 I/O Hub GPIO and Scratch Pad Registers"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "000B", "prop1": "8086", "prop2": "3423", "prop3": "003C",
        "detached": "0", "class": "OTHER", "desc": "Intel Corporation|7500/5520/5500/X58 I/O Hub Control Status and RAS Registers"},
    {"bus": "pci", "driver": "pcieport", "pciType": "1", "prop4": "3118", "prop1": "8086", "prop2": "3A40", "prop3": "103C",
        "detached": "0", "class": "OTHER", "desc": "Intel Corporation|82801JI (ICH10 Family) PCI Express Root Port 1"},
    {"bus": "pci", "driver": "pcieport", "pciType": "1", "prop4": "3118", "prop1": "8086", "prop2": "3A44", "prop3": "103C",
        "detached": "0", "class": "OTHER", "desc": "Intel Corporation|82801JI (ICH10 Family) PCI Express Root Port 3"},
    {"bus": "pci", "driver": "mgag200", "pciType": "1", "prop4": "31FA", "prop1": "102B", "prop2": "0522", "prop3": "103C",
        "detached": "0", "class": "VIDEO", "desc": "Matrox Electronics Systems Ltd.|MGA G200e [Pilot] ServerEngines (SEP1)"},
    {"bus": "pci", "driver": "uhci_hcd", "pciType": "1", "prop4": "3118", "prop1": "8086", "prop2": "3A34", "prop3": "103C",
        "detached": "0", "class": "USB", "desc": "Intel Corporation|82801JI (ICH10 Family) USB UHCI Controller #1"},
    {"bus": "pci", "driver": "uhci_hcd", "pciType": "1", "prop4": "3118", "prop1": "8086", "prop2": "3A35", "prop3": "103C",
        "detached": "0", "class": "USB", "desc": "Intel Corporation|82801JI (ICH10 Family) USB UHCI Controller #2"},
    {"bus": "pci", "driver": "uhci_hcd", "pciType": "1", "prop4": "3118", "prop1": "8086", "prop2": "3A36", "prop3": "103C",
        "detached": "0", "class": "USB", "desc": "Intel Corporation|82801JI (ICH10 Family) USB UHCI Controller #3"},
    {"bus": "pci", "driver": "ehci-pci", "pciType": "1", "prop4": "3118", "prop1": "8086", "prop2": "3A3A", "prop3": "103C",
        "detached": "0", "class": "USB", "desc": "Intel Corporation|82801JI (ICH10 Family) USB2 EHCI Controller #1"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "3118", "prop1": "8086", "prop2": "244E", "prop3": "103C", "detached": "0", "class": "OTHER", "desc": "Intel Corporation|82801 PCI Bridge"}, {"bus": "pci",
                                                                                                                                                                                                               "driver": "lpc_ich", "pciType": "1", "prop4": "3118", "prop1": "8086", "prop2": "3A16", "prop3": "103C", "detached": "0", "class": "OTHER", "desc": "Intel Corporation|82801JIR (ICH10R) LPC Interface Controller"},
    {"bus": "pci", "driver": "ahci", "pciType": "1", "prop4": "3A22", "prop1": "8086", "prop2": "3A22", "prop3": "8086",
        "detached": "0", "class": "OTHER", "desc": "Intel Corporation|82801JI (ICH10 Family) SATA AHCI Controller"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C40", "prop3": "8086",
        "detached": "0", "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 QuickPath Architecture Generic Non-Core Registers"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C01", "prop3": "8086",
        "detached": "0", "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 QuickPath Architecture System Address Decoder"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C10",
     "prop3": "8086", "detached": "0", "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 QPI Link 0"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C11",
        "prop3": "8086", "detached": "0", "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 QPI Physical 0"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C14",
        "prop3": "8086", "detached": "0", "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 QPI Link 1"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C15",
        "prop3": "8086", "detached": "0", "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 QPI Physical 1"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C18", "prop3": "8086",
        "detached": "0", "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 Integrated Memory Controller"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C19", "prop3": "8086",
        "detached": "0", "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 Integrated Memory Controller Target Address Decoder"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C1A", "prop3": "8086",
        "detached": "0", "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 Integrated Memory Controller RAS Registers"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C1C", "prop3": "8086",
        "detached": "0", "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 Integrated Memory Controller Test Registers"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C20", "prop3": "8086", "detached": "0",
        "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 Integrated Memory Controller Channel 0 Control Registers"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C21", "prop3": "8086", "detached": "0",
        "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 Integrated Memory Controller Channel 0 Address Registers"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C22", "prop3": "8086", "detached": "0",
        "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 Integrated Memory Controller Channel 0 Rank Registers"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C23", "prop3": "8086", "detached": "0",
        "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 Integrated Memory Controller Channel 0 Thermal Control Registers"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C28", "prop3": "8086", "detached": "0",
        "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 Integrated Memory Controller Channel 1 Control Registers"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C29", "prop3": "8086", "detached": "0",
        "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 Integrated Memory Controller Channel 1 Address Registers"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C2A", "prop3": "8086", "detached": "0",
        "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 Integrated Memory Controller Channel 1 Rank Registers"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C2B", "prop3": "8086", "detached": "0",
        "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 Integrated Memory Controller Channel 1 Thermal Control Registers"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C30", "prop3": "8086", "detached": "0",
        "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 Integrated Memory Controller Channel 2 Control Registers"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C31", "prop3": "8086", "detached": "0",
        "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 Integrated Memory Controller Channel 2 Address Registers"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C32", "prop3": "8086", "detached": "0",
        "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 Integrated Memory Controller Channel 2 Rank Registers"},
    {"bus": "pci", "driver": "unknown", "pciType": "1", "prop4": "8086", "prop1": "8086", "prop2": "2C33", "prop3": "8086", "detached": "0",
        "class": "OTHER", "desc": "Intel Corporation|Xeon 5500/Core i7 Integrated Memory Controller Channel 2 Thermal Control Registers"},
    {"bus": "usb", "driver": "usb", "pciType": "-1", "prop1": "1d6b", "prop2": "0001", "detached": "0", "class": "OTHER",
        "desc": "Linux Foundation|1.1 root hub"}, {"bus": "usb", "driver": "hub", "pciType": "-1", "detached": "0", "class": "OTHER", "desc": "USB Hub Interface"},
    {"bus": "usb", "driver": "usb", "pciType": "-1", "prop1": "1d6b", "prop2": "0001", "detached": "0", "class": "OTHER",
        "desc": "Linux Foundation|1.1 root hub"}, {"bus": "usb", "driver": "hub", "pciType": "-1", "detached": "0", "class": "OTHER", "desc": "USB Hub Interface"},
    {"bus": "usb", "driver": "usb", "pciType": "-1", "prop1": "0000",
        "prop2": "0000", "detached": "0", "class": "OTHER", "desc": "None|None"},
    {"bus": "usb", "driver": "usbhid", "pciType": "-1",
        "detached": "0", "class": "OTHER", "desc": "USB HID Interface"},
    {"bus": "usb", "driver": "usbhid", "pciType": "-1",
        "detached": "0", "class": "OTHER", "desc": "USB HID Interface"},
    {"bus": "usb", "driver": "usb", "pciType": "-1", "prop1": "1d6b", "prop2": "0001",
        "detached": "0", "class": "OTHER", "desc": "Linux Foundation|1.1 root hub"},
    {"bus": "usb", "driver": "hub", "pciType": "-1", "detached": "0",
        "class": "OTHER", "desc": "USB Hub Interface"},
    {"bus": "usb", "driver": "usb", "pciType": "-1", "prop1": "1d6b", "prop2": "0002",
        "detached": "0", "class": "OTHER", "desc": "Linux Foundation|2.0 root hub"},
    {"bus": "usb", "driver": "hub", "pciType": "-1", "detached": "0",
        "class": "OTHER", "desc": "USB Hub Interface"},
    # DISK
    {"bus": "ata", "driver": "unknown", "pciType": "-1", "device": "sda",
        "detached": "0", "class": "HD", "desc": "GB0160EAFJE"},
    #
    {"bus": "scsi", "driver": "sd", "pciType": "-1",
        "detached": "0", "class": "SCSI", "desc": ""},
    # cpu info
    {"count": 4, "model_ver": "26", "speed": 1999, "cache": "4096 KB", "model_number": "6", "bogomips": "4000.31", "socket_count": 1, "platform": "x86_64",
        "other": "fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm dtherm tpr_shadow vnmi flexpriority ept vpid", "model_rev": "5", "model": "Intel(R) Xeon(R) CPU           E5504  @ 2.00GHz", "type": "GenuineIntel", "class": "CPU", "desc": "Processor"},
    # memory  info
    {"ram": "5798", "class": "MEMORY", "swap": "6031"},
    # network info
    {"ip6addr": "2620:52:0:1040:225:b3ff:fe20:34f5",
        "hostname": "hp-sl2x170zg6-02.rhts.eng.bos.redhat.com", "ipaddr": "10.16.66.31", "class": "NETINFO"},
    {"product": "ProLiant SL170z G6", "vendor": "HP", "bios_vendor": "HP", "bios_release": "07/13/2009", "board": "HP",
        "bios_version": "O34", "class": "DMI", "asset": "(chassis: USE936RSDV) (chassis: ) (board: ) (system: USE936RSDV)"},
    # netdevice info
    {
        "docker0": {"ipaddr": "172.17.42.1", "module": "bridge", "broadcast": "0.0.0.0", "netmask": "255.255.0.0", "ipv6": [{"scope": "link", "netmask": 64, "addr": "fe80::5484:7aff:fefe:9799"}], "hwaddr": "56:84:7a:fe:97:99"},
        "veth2fecee7": {"ipaddr": "", "module": "veth", "broadcast": "", "netmask": "", "ipv6": [{"scope": "link", "netmask": 64, "addr": "fe80::644e:6bff:fe7b:55a"}], "hwaddr": "66:4e:6b:7b:05:5a"},
        "veth9af1224": {"ipaddr": "", "module": "veth", "broadcast": "", "netmask": "", "ipv6": [{"scope": "link", "netmask": 64, "addr": "fe80::c8f1:80ff:fee1:bee4"}], "hwaddr": "ca:f1:80:e1:be:e4"},
        "enp5s0f1": {"ipaddr": "10.16.66.31", "module": "igb", "broadcast": "10.16.71.255", "netmask": "255.255.248.0", "ipv6": [{"scope": "link", "netmask": 64, "addr": "fe80::225:b3ff:fe20:34f5"}, {"scope": "site", "netmask": 64, "addr": "fec0::f101:225:b3ff:fe20:34f5"}, {"scope": "universe", "netmask": 64, "addr": "2620:52:0:1040:225:b3ff:fe20:34f5"}], "hwaddr": "00:25:b3:20:34:f5"},
        "enp5s0f0": {"ipaddr": "", "module": "igb", "broadcast": "", "netmask": "", "ipv6": [], "hwaddr": "00:25:b3:20:34:f4"}, "lo": {"ipaddr": "127.0.0.1", "module": "loopback", "broadcast": "0.0.0.0", "netmask": "255.0.0.0", "ipv6": [{"scope": "host", "netmask": 128, "addr": "::1"}], "hwaddr": "00:00:00:00:00:00"}, "class": "NETINTERFACES"}]


def json_load(filename):
    f = open(filename)
    content = f.read()
    f.close()
    import simplejson as json
    content = json.loads(content)
    print content
import sys


import gettext
t = gettext.translation('rhn-client-tools', fallback=True)
_ = t.ugettext

sys.path.append("/usr/share/rhn/")

from up2date_client import up2dateAuth
from up2date_client import rpcServer
from up2date_client import rhncli


def rnd_int(start, end):
    rng = end - start
    r = random.random() * rng
    return start + int(round(r))


class _hardware():

    def Hardware(self):
        data = {
            "ram": rnd_int(10**3, 10**6),
            "swap": rnd_int(10**3, 10**5),
        }
        content = json_data
        for key, it in enumerate(content):
            if it["class"] == "HD":
                pass
            if it["class"] == "NETINFO":
                a = rnd_int(0, 255)
                b = rnd_int(0, 255)
                c = rnd_int(0, 255)
                content[key]["ipaddr"] = "10.%d.%d.%d" % (a, b, c)
                content[key]["hostname"] = "%d.fake.redhat.com" % (a + b + c)
            if it["class"] == "NETINTERFACES":
                for i in range(rnd_int(1, 10)):
                    content[key].update({
                        "br%d" % i: {
                            "ipaddr": "172.%d.%d.%d" % (a, b, i),
                            "module": "bridge",
                            "broadcast": "0.0.0.0",
                            "netmask": "255.255.0.0",
                            "ipv6": [{"scope": "link", "netmask": 64, "addr": "fe80::5484:7aff:fefe:9799"}],
                            "hwaddr": "56:84:7a:fe:97:%02d" % ((i * a) % 100)},
                    })
            for k, v in data.items():
                if k in it.keys():
                    content[key][k] = v

        for i in range(1, rnd_int(5, 15)):
            content.append({"bus": "scsi", "driver": "unknown",
                            "pciType": "-1", "detached": "0", "class": "SCSI", "desc": ""})
        return content


class ProfileCli(rhncli.RhnCli):

    def updateHardware(self):
        hardware = _hardware()

        s = rpcServer.getServer()

        hardwareList = hardware.Hardware()

        s.registration.refresh_hw_profile(up2dateAuth.getSystemId(),
                                          hardwareList)

    def main(self):
        print "update hradware... "
        self.updateHardware()


if __name__ == "__main__":
    cli = ProfileCli()
    cli.run()
