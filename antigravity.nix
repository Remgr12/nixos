{ pkgs, inputs, ... }:

let
  antigravity-nix = inputs.antigravity-nix;
  llm-agents      = inputs.llm-agents;
  system          = pkgs.stdenv.hostPlatform.system;
in
{
  home.packages = [
    antigravity-nix.packages.${system}.default
    llm-agents.packages.${system}.rtk
  ];

  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };
  
  home.sessionPath = [ "$HOME/.npm-global/bin" ];

  home.file.".config/antigravity/mcp-config.json".text = builtins.toJSON {
    mcpServers = {
      toon-context = {
        command = "nix";
        args = [
          "run"
          "github:numtide/llm-agents.nix#toon"
          "--"
          "serve"
        ];
      };
    };
  };
}
