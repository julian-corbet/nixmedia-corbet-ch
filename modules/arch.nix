# Arch backend — publishes the lists; the host's own reconciler installs them.
#   nixarch.packages.pacman = config.nixmedia.archPackages;
#   nixarch.packages.aur    = config.nixmedia.aurPackages;
{ ... }:
{
  imports = [ ./nixmedia.nix ];
}
