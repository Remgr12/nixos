{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    defaultKeymap = "viins";

    history = {
      path = "$HOME/.histfile";
      size = 1000;
      save = 1000;
    };

    shellAliases = {
      lsa = "ls -a";
      rebuild = "sudo nixos-rebuild switch";
      con = "qs /etc/nixos/configuration.nix";
      gp = ''read "msg?Commit message: " && git add . && git commit -m "$msg" && git push'';
    };

    sessionVariables = {
      GPG_TTY = "$(tty)";
      SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
    };

    initContent = ''
      # Custom Functions
      qs() { micro "$@" }

      chpwd() {
        ls -a
      }

      # GPG Startup
      gpg-connect-agent updatestartuptty /bye > /dev/null
    '';
  };
}
