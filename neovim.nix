{ inputs, pkgs, ... }:

{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    # Extra System Packages
    extraPackages = with pkgs; [
      git 
      lua-language-server 
      stylua 
      ripgrep 
      fd 
      gcc
    ];

    # Core Options
    opts = {
      termguicolors = false;
      number = true;
      relativenumber = true;
      shiftwidth = 2;
    };

    # Plugins
    plugins = {
      lualine.enable = true;
      telescope.enable = true;
      treesitter.enable = true;
      
      # Snacks Configuration
      snacks = {
        enable = true;
        settings = {
          dashboard = {
            preset.header = ''
                        ###                 
             ::                  ###     
             ##                  #:#     
                      :::    #            
           :.:            ДДДДД             #.# 
            #             :%%%:             ### 
                :     #                       
               .%.                    %%#      
                             %%%          ::       
                             :::                
            '';
          };
        };
      };
    };
  };
}
