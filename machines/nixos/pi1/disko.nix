{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/mmcblk0"; # or /dev/disk9 if that's your actual target
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "256M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };

            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
