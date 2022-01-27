{ lib
, stdenv
, dumb-init
, writeTextFile
, buildahBuild
, dockerTools
, fetchzip
}:
let
  name = "cp-schema-registry";
  baseImage = buildahBuild
    {
      name = "${name}-base";
      context = ./context;
      buildArgs = {
        fromTag = "11-jdk-focal";
        fromDigest = "sha256:04183c77cfeec77b6af875d3436fd0edf8fc73aa6801bf110d694a7449d69214";
      };
      outputHash =
        if stdenv.isx86_64 then
          "sha256-61E62Jfj9q6rCuhDBdkuSPo6bqvHK413Mh4PwhN3kx0=" else
          "sha256-ZQ8LtvOq38OqyQSis2dgyNUAunyLByfhXJ4MH+D4+44=";
    };

  package = fetchzip {
    url = "http://packages.confluent.io/archive/7.0/confluent-community-7.0.1.zip";
    sha256 = "sha256-A15hoVxWRouZxOA8qCi+1ineYQfROXg5H9Wbd3yXXqs=";
  };

  entrypoint = writeTextFile {
    name = "entrypoint";
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      exec dumb-init -- ${package}/bin/schema-registry-start "$@"
    '';
  };
  baseImageWithDeps = dockerTools.buildImage {
    inherit name;
    fromImage = baseImage;
    config = {
      Env = [
        "PATH=${lib.makeBinPath [ dumb-init ]}:/opt/java/openjdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
      ];
    };
  };
in
dockerTools.buildLayeredImage {
  inherit name;
  fromImage = baseImageWithDeps;
  config = {
    Entrypoint = [ entrypoint ];
  };
}

