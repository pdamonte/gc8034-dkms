# GC8034 / GCTI8034 DKMS driver

Linux DKMS package for the GalaxyCore GC8034-compatible sensor exposed on this
machine as ACPI HID `GCTI8034`.

The kernel module built by this package is named `gc8034`.

## Install on Ubuntu

```sh
sudo apt update
sudo apt install dkms build-essential v4l-utils python3-pil "linux-headers-$(uname -r)"
sudo ./install.sh
```

For a non-running target kernel:

```sh
sudo ./install.sh 6.x.y-z-generic
```

## Verify

```sh
lsmod | grep gc8034
dmesg | grep -Ei 'GCTI8034|gc8034'
v4l2-ctl --list-devices
```

## Smoke Test

The capture helper auto-detects the media pipeline, so it does not depend on
fixed `/dev/media*`, `/dev/v4l-subdev*`, or `/dev/video*` numbering.

```sh
sudo tools/capture-gc8034.sh /tmp/gc8034.raw /tmp/gc8034.png
```

To force a media controller:

```sh
sudo MEDIA_DEV=/dev/media0 tools/capture-gc8034.sh /tmp/gc8034.raw /tmp/gc8034.png
```

## IPU6 Bridge Note

The Intel IPU6 bridge must know about `GCTI8034` for the camera to be connected
into the media graph. On kernels that do not already list it, add:

```c
IPU_SENSOR_CONFIG("GCTI8034", 1, 336000000),
```

to `drivers/media/pci/intel/ipu-bridge.c`.

## Related repositories

- [`pdamonte/gc5035-dkms`](https://github.com/pdamonte/gc5035-dkms):
  Ubuntu/Debian DKMS package for the companion `GC5035` / `GCTI5035` camera
  sensor driver.
- [`pdamonte/ipu-bridge-gc-cameras-akmod`](https://github.com/pdamonte/ipu-bridge-gc-cameras-akmod):
  Fedora akmods package for the Intel IPU6 bridge module that advertises
  `GCTI5035` and `GCTI8034` support to the IPU6 media graph.

## License

This project is licensed under `GPL-2.0-only`. See [LICENSE](LICENSE).

## Uninstall

```sh
sudo ./uninstall.sh
```
