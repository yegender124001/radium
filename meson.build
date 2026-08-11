project('Radium', 'c', 'cpp', version: '0.1.0')

wayland_client = dependency('wayland-client')
wayland_protos = dependency('wayland-protocols')
wayland_scanner = dependency('wayland-scanner', native: true)
pango = dependency('pango')
cairo = dependency('cairo')
wayland_egl = dependency('wayland-egl')
egl = dependency('egl')
gl = dependency('gl')

wayland_scanner_bin = find_program(wayland_scanner.get_variable('wayland_scanner'))
wayland_protos_dir = wayland_protos.get_variable('pkgdatadir')

protocols = [
  wayland_protos_dir / 'stable/xdg-shell/xdg-shell.xml',
  wayland_protos_dir / 'unstable/linux-dmabuf/linux-dmabuf-unstable-v1.xml',
  wayland_protos_dir / 'stable/viewporter/viewporter.xml',
  wayland_protos_dir / 'staging/fractional-scale/fractional-scale-v1.xml',
  wayland_protos_dir / 'unstable/xdg-decoration/xdg-decoration-unstable-v1.xml',
  'protocols/wlr-layer-shell-unstable-v1.xml',
]

protocol_sources = []

foreach xml : protocols
  protocol_sources += custom_target(
    xml.underscorify() + '_client_h',
    input: xml,
    output: '@BASENAME@.h',
    command: [wayland_scanner_bin, 'client-header', '@INPUT@', '@OUTPUT@'],
  )
  protocol_sources += custom_target(
    xml.underscorify() + '_private_code',
    input: xml,
    output: '@BASENAME@.c',
    command: [wayland_scanner_bin, 'private-code', '@INPUT@', '@OUTPUT@'],
  )
endforeach

lib_radium = shared_library(
  'radium',
  [
    'src/App.cpp',
    'src/Window.cpp',
    'src/Platform/PlatformIntegration.cpp',
    'src/Platform/PlatformWindow.cpp',
    'src/Platform/PlatformBackingStore.cpp',
    'src/Platform/Wayland/Wayland.cpp',
    'src/Platform/Wayland/WlWindow.cpp',
    'src/Platform/Wayland/XdgSurface.cpp',
    'src/Platform/Wayland/XdgToplevel.cpp',
    'src/Platform/Wayland/Surface.cpp',
    'src/Platform/Wayland/WlBackingStore.cpp',
    'src/Platform/Wayland/WlRasterBackingStore.cpp',
    'src/Platform/Wayland/WlEGLBackingStore.cpp',
  ]
  + protocol_sources,
  include_directories: include_directories('src'),
  dependencies: [wayland_client, pango, cairo, wayland_egl, egl, gl],
)

radium_dep = declare_dependency(
  link_with: lib_radium,
  include_directories: include_directories('src'),
  dependencies: [wayland_client, pango, cairo,wayland_egl, egl, gl],
)

executable('radium-test', 'tests/main.cpp', dependencies: [radium_dep])
