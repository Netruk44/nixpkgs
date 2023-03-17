{ lib
, stdenv
, pkgs
, fetchgit
, openmw
, symlinkJoin
, luamods ? null
}:

let
  added_luamods = if luamods != null then luamods else [
    # TODO: Add a real mod here.
    {
      name = "learning";
      src = fetchgit {
        url = "https://:$ACCESS_KEY@storage.danieltperry.me:3000/danielperry/openmw-something-else";
        rev = "mod-learning_v0";
        sha256 = "sha256-kjd7elWICrwFmNkFIQwF0xzt6jM6epEyvJVXKamMjTE=";
      };
      root_dir = "my_first_mod/";
      content_file = "my_first_mod.omwscripts";
    }
  ];

  # Path to openmw.cfg
  cfg_dir = if stdenv.isDarwin then
    "OpenMW.app/Contents/Resources"
  else
    "share/games/openmw";

  # First, create a new copy of openmw.cfg with the mods enabled.
  # Do this by appending two new lines for every mod:
  #   data=<mod_src>/<mod_root_dir>
  #   content=<mod_content_file>
  # OpenMW is okay with reading the mods directly from the Nix store,
  # so we don't need to copy them to be next to OpenMW.
  original_cfg_contents = builtins.readFile "${openmw}/${cfg_dir}/openmw.cfg";
  updated_cfg_contents = original_cfg_contents + "\n" + (lib.concatMapStringsSep "\n" (mod: ''
    data=${mod.src}/${(mod.root_dir or '''')}
    content=${mod.content_file}
  '') added_luamods);

  # Then, create a new derivation that places the updated .cfg
  # into the correct directory to be read by OpenMW.
  updated_cfg = pkgs.writeTextFile {
    name = "openmw-modded-cfg";
    destination = "/${cfg_dir}/openmw.cfg";
    text = updated_cfg_contents;
  };
in
symlinkJoin {
  name = "openmw-modded";
  inherit (openmw) version meta;

  # Link updated cfg first, then overlay openmw on top.
  # Files don't get overwritten, so the updated cfg is preserved.
  paths = [ updated_cfg openmw ];
}