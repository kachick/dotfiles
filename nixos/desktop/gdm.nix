{
  config,
  lib,
  ...
}:

{
  # Put custom GDM settings ahead of the upstream greeter defaults in the dconf
  # profile so overrides such as sleep-inactive-ac-type take precedence.
  programs.dconf.profiles.gdm.databases = lib.mkBefore [
    {
      settings = {
        "org/gnome/desktop/peripherals/mouse" = {
          natural-scroll = true;
        };

        "org/gnome/desktop/peripherals/touchpad" = {
          tap-to-click = true;
          natural-scroll = true;
        };

        "org/gnome/desktop/interface" = {
          clock-show-weekday = true;
          show-battery-percentage = true;
        };

        # Keep SSH and Cockpit reachable while sitting at the login screen on AC power.
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
          sleep-inactive-ac-timeout = lib.gvariant.mkInt32 0;
        };

        "org/gnome/login-screen" = {
          banner-message-enable = true;
          banner-message-text = config.networking.hostName;
        };
      };
    }
  ];
}
