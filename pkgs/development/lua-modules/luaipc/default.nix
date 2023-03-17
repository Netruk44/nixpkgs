{ stdenv
, fetchFromGitHub
, buildLuarocksPackage
, lua
, lib
}:

buildLuarocksPackage {
    pname = "luaipc";
    version = "scm-0";

    src = fetchFromGitHub {
        owner = "siffiejoe";
        repo = "lua-luaipc";
        rev = "4dae67b99fd5f31ba8e2a5ce2ca1506c66176d9c";
        sha256 = "sha256-R0n+SkYPxs3Wx2hk5qico+y9eGbEHfFokieg5kbmQbI=";
        fetchSubmodules = true;
    };

    meta = {
        description = "Portable inter-process communication for Lua";
        homepage = "https://github.com/siffiejoe/lua-luaipc";
        license = lib.licenses.mit;
        maintainers = [  ]; # FIXME: add yourself
    };
}