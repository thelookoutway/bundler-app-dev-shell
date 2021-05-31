{ buildInputs, shellHook ? "" }:
{ mkShell, stdenv, lib }:
let
  environment = stdenv.mkDerivation {
    name = "environment";
    phases = [ "installPhase" "fixupPhase" ];
    installPhase = "touch $out";
    buildInputs = buildInputs;
  };
in mkShell {
  buildInputs = environment.drvAttrs.buildInputs;
  shellHook = let
    # We use the store-path for environment as our Bundler cache-key to rebuild gems when the environment changes
    environmentId = lib.last (lib.strings.splitString "/" "${environment}");
  in ''
    if [ -z "$BUNDLE_PATH" ]; then
      export BUNDLE_PATH=.bundle/${environmentId}
    else
      export BUNDLE_PATH=$BUNDLE_PATH/${environmentId}
    fi
  '' + lib.optionalString stdenv.isLinux ''
    # Make sure we have a 'big' enough locale for Heroku output on CI
    export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
  '' + shellHook;
}
