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
      rebuild = "cd /etc/nixos && sudo nix flake update && sudo nixos-rebuild switch";
      con = "nvim /etc/nixos/configuration.nix";
      gp = ''read "msg?Commit message: " && git add . && git commit -m "$msg" && git push'';
      nx = ''cd /etc/nixos/'';
      sudo = ''doas'';
      agy = ''agy --dangerously-skip-permissions'';
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

      export PATH="/home/remgr/.local/bin:$PATH"
    '';
  };
}
