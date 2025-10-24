defmodule QemuTest do
  use ExUnit.Case
  doctest Qemu

  test "greets the world" do
    assert Qemu.hello() == :world
  end

  test "talks to qemu nerves using peer" do
    Extrace.calls({:erlang, :open_port, :_}, 10)

    qemu = :os.find_executable(:"qemu-system-aarch64")

    {:ok, peer, _node} =
      :peer.start_link(%{
        connection: 0,
        wait_boot: 50000,
        exec: {qemu, []},
        detached: false,
        args: ~w(-heart -env HEART_BEAT_TIMEOUT 30)c,
        post_process_args: fn args ->
          args =
            args
            |> Enum.map(fn
              [58, 58, 49 | _] -> ~c"10.0.2.2"
              rest -> rest
            end)
            |> Enum.join(" ")
            |> String.replace(",", ",,")

          [
            ~c"-machine",
            ~c"virt,accel=hvf",
            ~c"-cpu",
            ~c"host",
            ~c"-smp",
            ~c"1",
            ~c"-m",
            ~c"256M",
            ~c"-kernel",
            ~c"/Users/benni/.nerves/artifacts/nerves_system_qemu_aarch64-portable-0.1.1/images/little_loader.elf",
            ~c"-netdev",
            ~c"user,id=eth0",
            ~c"-device",
            ~c"virtio-net-device,netdev=eth0,mac=fe:db:ed:de:d0:01",
            ~c"-global",
            ~c"virtio-mmio.force-legacy=false",
            ~c"-drive",
            ~c"if=none,file=virtual-disk.img,format=raw,id=vdisk",
            ~c"-device",
            ~c"virtio-blk-device,drive=vdisk,bus=virtio-mmio-bus.0",
            ~c"-nographic",
            ~c"-fw_cfg",
            ~c"name=opt/erl,string=#{args}"
          ]
        end
      })

    {:ok, result} = :peer.call(peer, Nerves.Runtime.KV, :get_all, [])

    IO.inspect(result)
  rescue
    e ->
      Process.sleep(1000)
      reraise e, __STACKTRACE__
  end
end
