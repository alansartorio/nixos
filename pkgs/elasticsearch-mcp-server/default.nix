# Elastic's own MCP server for core Elasticsearch, built from source.
#
# Upstream only documents a Docker image, and the old npm package stopped at
# 0.3.1 -- because 0.4.0 rewrote the thing in Rust. That makes it the easiest
# of the four to run natively: one static-ish binary under systemd, no
# container runtime, no node.
#
# It is deprecated upstream in favour of Kibana's Agent Builder MCP endpoint,
# which needs an Enterprise subscription. Talking to Elasticsearch directly
# needs no licence beyond Basic, which is why this exists here.
#
# Cargo.lock is vendored beside this file rather than read from src: the
# manifest pulls elasticsearch-rs from a git branch, so the lockfile has to be
# available at eval time to give that dependency an outputHash.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
}:
rustPlatform.buildRustPackage rec {
  pname = "elasticsearch-mcp-server";
  version = "0.4.6";

  src = fetchFromGitHub {
    owner = "elastic";
    repo = "mcp-server-elasticsearch";
    tag = "v${version}";
    hash = "sha256-caH1jW2Crrjp5KLWfR+MxIUmfW5tFunXPXV3K/eLaaA=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "elasticsearch-9.0.0-alpha.1" = "sha256-/jgXCR0YKi1nqpQzmkj8Tyzy1JLsbcizghqUWZVG+24=";
    };
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  # The suite wants a live Elasticsearch.
  doCheck = false;

  meta = {
    description = "Elastic's MCP server for core Elasticsearch features";
    homepage = "https://github.com/elastic/mcp-server-elasticsearch";
    license = lib.licenses.asl20;
    mainProgram = "elasticsearch-core-mcp-server";
  };
}
