{
  description = "Description for the project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devenv.flakeModule
      ];

      systems = ["x86_64-linux"];
      perSystem = {pkgs, ...}: {
        devenv.shells.default = {
          name = "adv360-pro";
          packages = with pkgs; [coreutils gh gnutar];
          pre-commit.hooks = {
            alejandra.enable = true;
          };
          scripts = {
            download-firmware.exec = ''
              mkdir -p ./firmware
              gh run download --dir ./firmware
            '';
            install-firmware.exec = ''
              [ ! -e "./firmware/$1.uf2" ] && echo "Firmware not found: ./firmware/$1.uf2" && exit 1

              while [ ! -e /dev/sda ]; do
                echo 'waiting for /dev/sda...'
                sleep 1s
              done

              echo "flashing firmware (./firmware/$1.uf2)"
              mkdir -p "./firmware/$1"
              sudo mount /dev/sda "./firmware/$1"
              sudo cp -v "./firmware/$1.uf2" "./firmware/$1"
              sudo umount /dev/sda

              while [ -e /dev/sda ]; do
                echo 'waiting for /dev/sda...'
                sleep 1s
              done

              rm "./firmware/$1.uf2"
            '';
          };
        };
      };
    };
}
