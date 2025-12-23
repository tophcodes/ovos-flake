{
  pkgs ? import <nixpkgs> {},
  self,
}:
pkgs.testers.runNixOSTest {
  name = "ovos-messagebus-basic";

  nodes.machine = {
    config,
    pkgs,
    ...
  }: {
    imports = [self.nixosModules.default];

    services.ovos = {
      enable = true;
      openFirewall = true;
    };
  };

  testScript = ''
    start_all()

    # Wait for the messagebus service to start
    machine.wait_for_unit("ovos-messagebus.service")

    # Check that the port is open
    machine.wait_for_open_port(8181)

    # Verify the service is running
    machine.succeed("systemctl status ovos-messagebus.service")

    # Check that the ovos user exists
    machine.succeed("id ovos")

    # Verify directories were created
    machine.succeed("test -d /var/lib/ovos")
    machine.succeed("test -d /etc/ovos")

    # Check that configuration was generated
    machine.succeed("test -f /etc/ovos/mycroft.conf")

    print("✓ All basic checks passed!")
  '';
}
