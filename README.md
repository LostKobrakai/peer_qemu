# Qemu

Build `erlinit` branch locally:

https://github.com/nerves-project/erlinit?tab=readme-ov-file#building

Replace `rootfs_overlay/sbin/init` with resulting binary.

```sh
mix deps.get
MIX_TARGET=qemu mix deps.get
MIX_TARGET=qemu mix firmware
MIX_TARGET=qemu mix nerves.gen.qemu _build/qemu_dev/nerves/images/qemu.fw
mix test test/qemu_test.exs:18
```
