defmodule QemuTest do
  use ExUnit.Case
  doctest Qemu

  test "talks to qemu nerves using peer" do
    Extrace.calls({:erlang, :open_port, :_}, 10)

    peer_bridge = Application.app_dir(:peer_bridge, ["priv", "peer_bridge"]) |> to_charlist()

    {:ok, peer, _node} =
      :peer.start_link(%{
        connection: :standard_io,
        wait_boot: 50000,
        exec: {peer_bridge, []},
        args: ~w(-heart -env HEART_BEAT_TIMEOUT 30)c,
        post_process_args: fn args ->
          args =
            args
            |> Enum.join(" ")
            |> String.replace(",", ",,")

          [
            ~c"--raw-to-link",
            ~c"--",
            ~c"qemu-system-aarch64",
            ~c"-machine",
            ~c"virt,accel=hvf",
            ~c"-cpu",
            ~c"host",
            ~c"-smp",
            ~c"1",
            ~c"-m",
            ~c"256M",
            ~c"-kernel",
            ~c"#{System.user_home!()}/.nerves/artifacts/nerves_system_qemu_aarch64-portable-0.2.0/images/little_loader.elf",
            ~c"-netdev",
            ~c"user,id=eth0",
            ~c"-device",
            ~c"virtio-net-device,netdev=eth0,mac=fe:db:ed:de:d0:01",
            ~c"-global",
            ~c"virtio-mmio.force-legacy=false",
            ~c"-drive",
            ~c"if=none,file=qemu.img,format=raw,id=vdisk",
            ~c"-device",
            ~c"virtio-blk-device,drive=vdisk,bus=virtio-mmio-bus.0",
            ~c"-nographic",
            ~c"-fw_cfg",
            ~c"name=opt/erl,string=#{args}"
          ]
        end
      })

    results = :peer.call(peer, Nerves.Runtime.KV, :get_all, [])

    assert is_map(results)
    IO.inspect(results)
  rescue
    e ->
      Process.sleep(1000)
      reraise e, __STACKTRACE__
  end
end
