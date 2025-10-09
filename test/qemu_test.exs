defmodule QemuTest do
  use ExUnit.Case
  doctest Qemu

  test "greets the world" do
    assert Qemu.hello() == :world
  end

  test "talks to qemu nerves using peer" do
    Extrace.calls({:erlang, :open_port, :_}, 10)

    {:ok, peer, _node} =
      :peer.start_link(%{
        connection: 0,
        wait_boot: 60000,
        exec:
          {Path.expand("./start_qemu.sh") |> String.to_charlist(),
           ~w(-machine virt,accel=hvf   -cpu host   -smp 1   -m 256M   -kernel ~/.nerves/artifacts/nerves_system_qemu_aarch64-portable-0.1.1/images/little_loader.elf   -netdev user,id=eth0   -device virtio-net-device,netdev=eth0,mac=fe:db:ed:de:d0:01   -global virtio-mmio.force-legacy=false   -drive if=none,file=virtual-disk.img,format=raw,id=vdisk   -device virtio-blk-device,drive=vdisk,bus=virtio-mmio-bus.0   -nographic   --   -heart -env HEART_BEAT_TIMEOUT 30)c}
      })

    {:ok, result} = :peer.call(peer, Nerves.Runtime.KV, :get_all, [])

    IO.inspect(result)
  end
end
