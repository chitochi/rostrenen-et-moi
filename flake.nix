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
      buildToolsVersion = "30.0.3";
      androidComposition = pkgs.androidenv.composeAndroidPackages {
        buildToolsVersions = ["31.0.0" buildToolsVersion];
        platformVersions = ["34" "33" "32" "31" "28"];
        abiVersions = ["armeabi-v7a" "arm64-v8a"];
      };
      androidSdk = androidComposition.androidsdk;
      pythonPkgs = with pkgs.python3Packages; [
        pillow
        django_5
        (django-ninja.override {
          django = django_5;
        })
        (django-environ.override {
          django = django_5;
        })
        (whitenoise.override {
          django = django_5;
        })
        (django-phonenumber-field.override {
          django = django_5;
        })
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
            contents = [backend pkgs.python3Packages.gunicorn];
            config = {
              Env = [
                "PYTHONPATH=${backend.pythonPath}"
                "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              ];
              Cmd = ["gunicorn" "--bind" "0.0.0.0:8000" "--chdir" pkgs.python3.sitePackages "rostrenenetmoi.wsgi"];
            };
          };
      };

      devShell = with pkgs;
        mkShell rec {
          packages =
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
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/31.0.0/aapt2";

          SECRET_KEY = "django-insecure-(hx(p9v^v0%i8y+r435gu@vs6&5x6t*$&x8mdcp$cskx8j!!@^";
          DEBUG = "true";
        };
    });
}
