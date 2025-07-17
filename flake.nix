{
  description = "A development environment for Rostrenen et moi.";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          android_sdk.accept_license = true;
          allowUnfree = true;
        };
      };
      androidComposition = pkgs.androidenv.composeAndroidPackages {
        platformVersions = ["35" "34"];
        buildToolsVersions = ["34.0.0"];
        includeNDK = true;
        ndkVersions = ["27.0.12077973"];
        cmakeVersions = ["3.22.1"];
      };
      androidSdk = androidComposition.androidsdk;
      pythonPkgs = with pkgs.python3Packages.override {
        overrides = self: super: {
          django = super.django_5;
        };
      }; [
        pillow
        django
        django-ninja
        django-environ
        whitenoise
        django-phonenumber-field
        django-import-export
      ];
    in {
      packages = {
        backend = pkgs.python3Packages.buildPythonApplication rec {
          pname = "rostrenenetmoi";
          version = "1.0";
          src = ./backend;
          doCheck = false;

          propagatedBuildInputs = pythonPkgs;

          passthru = {
            pythonPath = pkgs.python3Packages.makePythonPath propagatedBuildInputs;
          };
        };

        backendDockerImage = let
          backend = self.packages."${system}".backend;
        in
          pkgs.dockerTools.buildLayeredImage {
            name = "backend";
            tag = "latest";
            contents = [
              backend
              pkgs.python3Packages.gunicorn
              pkgs.dockerTools.caCertificates
            ];
            config = {
              Env = [
                "PYTHONPATH=${backend.pythonPath}"
              ];
              Cmd = ["gunicorn" "--bind" "0.0.0.0:8000" "--chdir" pkgs.python3.sitePackages "rostrenenetmoi.wsgi"];
            };
          };
      };

      devShell = pkgs.mkShell {
        packages = with pkgs;
          [
            # app dependencies
            flutter
            androidSdk
            jdk17
            clang
            cmake
            git
            ninja
            pkg-config
            xz
            gtk3
            glib
            pcre

            # backend dependencies
            ruff
            python3

            # tools
            sqlite
          ]
          ++ pythonPkgs;

        ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
        GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/34.0.0/aapt2";

        SECRET_KEY = "django-insecure-(hx(p9v^v0%i8y+r435gu@vs6&5x6t*$&x8mdcp$cskx8j!!@^";
        DEBUG = "true";
      };
    });
}
