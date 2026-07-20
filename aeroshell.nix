{ config, lib, pkgs, ... }:

{
  programs.aeroshell = {
    enable = true;
    fonts.segoe.enable = true;
    polkit.enable = true;
    aerothemeplasma = {
      enable = true;
      sddm.enable = false;
      plymouth.enable = false;
    };
  };
}
