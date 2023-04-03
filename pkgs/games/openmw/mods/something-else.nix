{ lib
, pkgs
, stdenv
, luajit
, openmw
, openmw-modded
, fetchgit
, fetchzip
, fetchFromGitLab
, symlinkJoin
}:

let
  # luajit_somethingelse = luajit.withPackages(ps: [ps.luaipc]);
  openmw_somethingelse = openmw.override {
    # luajit = luajit_somethingelse;
    source = fetchFromGitLab {
      owner = "Netruk44";
      repo = "openmw";
      rev = "something-else-mod-v0.3c";
      sha256 = "sha256-rzsXYqoWD54L1sj70uqW55HhPUdkatZTpuIVGUKysBI=";
    };
  };
  #openmw-modded_somethingelse = openmw-modded.override {
  #  openmw = openmw_somethingelse;
  #  luamods = [
  #    {
  #      name = "Something Else";
  #      src = fetchgit {
  #        url = "https://:$ACCESS_KEY@storage.danieltperry.me:3000/danielperry/openmw-something-else";
  #        rev = "se-test-v5-2";
  #        sha256 = "sha256-D7C+iOPEdoAanrgcgER1S9Dkzr0lr1WsNfIe6jDpFx8=";
  #      };
  #      root_dir = "something_else/";
  #      content_file = "something_else.omwscripts";
  #    }
  #  ];
  #};

  mlInterfaceRepository = fetchgit {
    url = "https://github.com/Netruk44/ml-interface";
    rev = "v0.4";
    sha256 = "sha256-gBcO+Yd0Cl1zecIqbJbLjgJb6MYSKIvVRxCp3x5vD+Y=";
  };

  # Create a script that runs the ml interface script with all arguments
  customAnswerScriptFile = pkgs.writeTextFile {
    name = "custom_answer";
    destination = if stdenv.isDarwin then 
      "/OpenMW.app/Contents/MacOS/custom_answer" 
    else 
      "/bin/custom_answer";

    text = ''
      # Run ml interface script with all arguments
      export OPENAI_API_KEY=""
      ${mlInterfaceRepository}/ml-interface.sh "$@"
    '';
    executable = true;
  };
in
symlinkJoin {
  name = "openmw-something-else";
  inherit (openmw) version meta;
  # TODO: Meta
  #paths = [ openmw-modded_somethingelse ];
  paths = [ openmw_somethingelse customAnswerScriptFile ];
}