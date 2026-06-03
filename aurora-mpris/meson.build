project('aurora-mpris-player', 'c',
  version : '0.1.0',
  default_options : ['c_std=c11', 'warning_level=1']
)

gtk4_dep        = dependency('gtk4')
adwaita_dep     = dependency('libadwaita-1')
json_glib_dep   = dependency('json-glib-1.0')
layer_shell_dep = dependency('gtk4-layer-shell-0')
cc = meson.get_compiler('c')
math_dep = cc.find_library('m', required : true)

sources = [
  'standalone_main.c',
  'src/main.c',
  'src/mpris.c',
  'src/lyrics.c',
  'src/utils.c',
]

executable('aurora-mpris-player',
  sources,
  c_args : ['-pthread', '-D_GNU_SOURCE'],
  include_directories : include_directories('src'),
  dependencies : [gtk4_dep, adwaita_dep, json_glib_dep, layer_shell_dep, math_dep],
  install : true
)

install_data(
  'aurora-mpris-player.desktop',
  install_dir : get_option('datadir') / 'applications'
)
