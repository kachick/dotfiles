{
  pkgs,
}:

pkgs.my.lima.override {
  withAdditionalGuestAgents = true;
}
