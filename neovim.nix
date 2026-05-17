{ inputs, pkgs, ... }:

{
  imports = [
    inputs.nixvim.homeModules.nixvim
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    # Extra System Packages
    extraPackages = with pkgs; [
      git 
      lua-language-server 
      stylua 
      ripgrep 
      fd 
      gcc
      lazygit
      wl-clipboard # For Wayland clipboard support
      xclip        # For X11 clipboard support
    ];

    # Core Options
    opts = {
      termguicolors = false;
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      fillchars = { eob = " "; };
      ruler = false;
    };

    # Custom Keymaps
    keymaps = [
      {
        mode = "n";
        key = "<leader>gg";
        action = "<cmd>lua Snacks.lazygit()<CR>";
        options.desc = "Open LazyGit";
      }
      {
        mode = "v";
        key = "d";
        action = "\"_d"; # Uses the blackhole register to delete without saving
        options.desc = "Delete without yanking";
      }
      {
        mode = "v";
        key = "x";
        action = "\"+d"; # Uses the + register to cut to the system clipboard
        options.desc = "Cut to system clipboard";
      }
    ];

    # Plugins
    plugins = {
      web-devicons.enable = true;
      lualine.enable = true;
      telescope.enable = true;
      
      # Syntax Highlighting
      treesitter = {
        enable = true;
        settings = { highlight.enable = true; };
      };

      # Language Servers (LSP)
      lsp = {
        enable = true;
        servers = {
          rust_analyzer.enable = true;
          gopls.enable = true;
          jdtls.enable = true;
          kotlin_language_server.enable = true;
          nixd.enable = true;
          ruby_lsp.enable = true;
          clangd.enable = true;
          pyright.enable = true;
          yamlls.enable = true;
          marksman.enable = true;
        };
        keymaps.lspBuf = {
          K = "hover";
          gd = "definition";
          gr = "references";
          "<leader>rn" = "rename";
          "<leader>ca" = "code_action";
        };
      };

      # AI Assistants
      copilot-lua = {
        enable = true;
        settings = {
          suggestion.auto_trigger = true;
          panel.enabled = false;
        };
      };
      avante = {
        enable = true;
        settings.provider = "claude";
      };

      # Quality of Life Plugins
      render-markdown.enable = true;
      comment.enable = true;
      which-key.enable = true;
      nvim-autopairs.enable = true;
      gitsigns.enable = true;
      
      neo-tree = {
        enable = true;
        closeIfLastWindow = true;
      };

      conform-nvim = {
        enable = true;
        settings = {
          format_on_save = { lsp_fallback = true; timeout_ms = 500; };
          formatters_by_ft.lua = [ "stylua" ];
        };
      };

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
            sections = [
              { section = "header"; }
              { section = "keys"; gap = 1; padding = 1; }
              { section = "recent_files"; icon = " "; title = "Recent Files"; padding = 1; }
              { section = "projects"; icon = " "; title = "Projects"; padding = 1; }
              {
                __raw = ''
                  function()
                    local in_git = Snacks.git.get_root() ~= nil
                    local cmds = {
                      {
                        title = "Notifications",
                        cmd = "gh notify -s -a -n5",
                        action = function() vim.ui.open("https://github.com/notifications") end,
                        key = "n", icon = " ", height = 15, enabled = true,
                      },
                      {
                        title = "Status", cmd = "gh status", icon = "", height = 5, enabled = true,
                      },
                    }
                    return vim.tbl_map(function(cmd)
                      return vim.tbl_extend("force", {
                        pane = 2, section = "terminal", enabled = in_git, padding = 1, ttl = 5 * 60, indent = 3,
                      }, cmd)
                    end, cmds)
                  end
                '';
              }
            ];
          };
        };
      };
    };
  };
}
