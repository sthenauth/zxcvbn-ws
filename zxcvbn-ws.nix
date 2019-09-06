{ mkDerivation, aeson, base, filepath, servant, servant-server
, servant-websockets, stdenv, text, time, warp, websockets
, zxcvbn-hs
}:
mkDerivation {
  pname = "zxcvbn-ws";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  enableSeparateDataOutput = true;
  executableHaskellDepends = [
    aeson base filepath servant servant-server servant-websockets text
    time warp websockets zxcvbn-hs
  ];
  description = "Web Socket server for measuring password strength";
  license = stdenv.lib.licenses.mit;
}
