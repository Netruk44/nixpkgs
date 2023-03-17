{ lib
, stdenv
, mkDerivation
, fetchgit
, fetchFromGitHub
, fetchFromGitLab
, fetchpatch
, cmake
, pkg-config
, wrapQtAppsHook
, openscenegraph
, mygui
, bullet
, ffmpeg
, boost
, SDL2
, unshield
, openal
, libXt
, lz4
, recastnavigation
, VideoDecodeAcceleration
, libyamlcpp
, luajit
, CoreMedia
, VideoToolbox
, source ? null
}:

let
  openscenegraph_openmw = (openscenegraph.override { colladaSupport = true; })
    .overrideDerivation (self: {
      src = fetchFromGitHub {
        owner = "OpenMW";
        repo = "osg";
        rev = "69cfecebfb6dc703b42e8de39eed750a84a87489";
        sha256 = "sha256-gq8P1DGRzo+D96++yivb+YRjdneSNZC03h9VOp+YXuE=";
      };
      patches = (self.patches or []) ++ [
        (fetchpatch {
          # For Darwin, OSG doesn't build some plugins as they're redundant with QuickTime.
          # OpenMW doesn't like this, and expects them to be there. Apply their patch for it.
          name = "darwin-osg-plugins-fix.patch";
          url = "https://gitlab.com/OpenMW/openmw-dep/-/raw/0abe3c9c3858211028d881d7706813d606335f72/macos/osg.patch";
          sha256 = "sha256-/CLRZofZHot8juH78VG1/qhTHPhy5DoPMN+oH8hC58U=";
        })
      ];
    });

  bullet_openmw = bullet.overrideDerivation (old: rec {
    version = "3.17";
    src = fetchFromGitHub {
      owner = "bulletphysics";
      repo = "bullet3";
      rev = version;
      sha256 = "sha256-uQ4X8F8nmagbcFh0KexrmnhHIXFSB3A1CCnjPVeHL3Q=";
    };
    patches = [];
    cmakeFlags = (old.cmakeFlags or []) ++ [
      "-DUSE_DOUBLE_PRECISION=ON"
      "-DBULLET2_MULTITHREADING=ON"
    ];
  });

  # FIXME: Update actual MyGUI package to 3.4.1.
  # Issues: https://github.com/NixOS/nixpkgs/pull/182905
  #   * Breaks ogre 1.9
  #   * Updates to ogre 1.12 cause build issues elsewhere
  mygui_openmw = mygui.overrideAttrs (old: rec {
    version = "3.4.1";
    src = fetchFromGitHub {
      owner = "MyGUI";
      repo = "mygui";
      rev = "MyGUI${version}";
      sha256 = "sha256-5u9whibYKPj8tCuhdLOhL4nDisbFAB0NxxdjU/8izb8=";
    };
  });
in
mkDerivation rec {
  pname = "openmw";
  version = "48-rc8";

  # FIXME: Go back to GitHub source when 0.48.0 is released
  src = if source != null then source else fetchFromGitLab {
    owner = "OpenMW";
    repo = "openmw";
    rev = "${pname}-${version}";
    sha256 = "sha256-CORUaxfMe2Itk3wYyBX++t4rHYt81wpraJQt7uGRWus=";
  };

  postPatch = lib.optionalString stdenv.isDarwin ''
    # Don't fix Darwin app bundle
    sed -i '/fixup_bundle/d' CMakeLists.txt
  '';

  nativeBuildInputs = [ cmake pkg-config wrapQtAppsHook ];

  # If not set, OSG plugin .so files become shell scripts on Darwin.
  dontWrapQtApps = true;

  buildInputs = [
    SDL2
    boost
    bullet_openmw
    ffmpeg
    libXt
    mygui_openmw
    openal
    openscenegraph_openmw
    unshield
    lz4
    recastnavigation
    libyamlcpp
    luajit
  ] ++ lib.optionals stdenv.isDarwin [
    VideoDecodeAcceleration
    CoreMedia
    VideoToolbox
  ];

  cmakeFlags = [
    # as of 0.46, openmw is broken with GLVND
    "-DOpenGL_GL_PREFERENCE=LEGACY"
    "-DOPENMW_USE_SYSTEM_RECASTNAVIGATION=1"
  ] ++ lib.optionals stdenv.isDarwin [
    "-DOPENMW_OSX_DEPLOYMENT=ON"
  ];

  meta = with lib; {
    description = "An unofficial open source engine reimplementation of the game Morrowind";
    homepage = "https://openmw.org";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ abbradar marius851000 ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
