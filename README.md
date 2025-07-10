# Bundler App Dev Shell

A convenience function for making declarative, [Bundler](https://bundler.io)-compatible, development environments using [Nix](https://nixos.org).

## Why?

Nix is a tool for precisely specifying, and packaging, build and run-time dependencies for programs. A nifty side-effect is that it can be used to specify isolated, reproducible development environments. However, Nix works best when it's responsible for providing _every_ dependency of a program. Because Nix aims to be precise and predictable integrating with Bundler is a challenge.

Bundler, like Ruby, is very dynamic (read: _un_-predictable) and so attempts to integrate Bundler with Nix have had a tough time (see [Bundix](https://github.com/nix-community/bundix)). So far we've opted to let Bundler and Node manage Ruby and Node packages respectively, without any Nix integration. We don't use Nix to actually package our applications, only for CI and development environments, so it's OK for those dependencies to live outside the Nix dependency-graph.

This does however get us in trouble when we upgrade Ruby or add new system-level dependencies. If a gem has compiled native extensions against the version of Ruby provided by our Nix shell, sometimes Bundler stores that in an ... imprecise ... location, something like `$BUNDLE_PATH/ruby/MAJOR.MINOR.0/...`. If we update our Nix-provided Ruby version the files that gem has linked against with disappear. We need our bundled gems to be stored in a location that relates to the _exact_ Ruby version provided by Nix.

It's not all doom-and-gloom, we get a slight benefit from invalidating bundled gems when the environment changes. Some gems build their native extensions differently depending on the presence of different system libraries. Under normal circumstances you might install the new system dependencies and then either blow away `$BUNDLE_PATH` or run `bundle pristine`. This is a little undesirable, every developer will need to know to run those steps, every CI machine with built-gems will need to be logged into and manually re-bundled. With this Nix function we can skip all of that, every developer gets the new system dependency and their old gems will be kept out of the way of the new environment. Great!

## How?

Import the `default.nix` from this repository using either [Niv](https://github.com/nmattia/niv) or `builtins.fetchTarball`.

### Using Niv

Add the dependency.

```
$ niv add thelookoutway/bundler-app-dev-shell
```

Import and use the function in your `shell.nix` file.

```nix
let
  sources = import ./nix/sources.nix;
  nixpkgs = import sources.nixpkgs;
  mkBundlerAppDevShell =
    nixpkgs.callPackage (import sources.bundler-app-dev-shell) { };
in mkBundlerAppDevShell {
  buildInputs = with nixpkgs;
    [
      # Add your project dependencies
    ];
  shellHook = ''
    # Optionally add any project shell setup you may need
  '';
}
```

### Using `builtins.fetchTarball`

```nix
let
  nixpkgs = import <nixpkgs> { };
  mkBundlerAppDevShell-source = builtins.fetchTarball {
    url =
      "https://github.com/thelookoutway/bundler-app-dev-shell/archive/<GIT REV SHA>.tar.gz";
  };
  mkBundlerAppDevShell =
    nixpkgs.callPackage (import mkBundlerAppDevShell-source) { };
in mkBundlerAppDevShell {
  buildInputs = with nixpkgs;
    [
      # Add your project dependencies
    ];
  shellHook = ''
    # Optionally add any project shell setup you may need
  '';
}
```
