# Taiga MCP server. Community, not upstream -- Taiga ships none -- and picked
# over the alternatives because it is the only one that enumerates its whole
# tool list in its docs, which is what the proxy's allowlist is built from.
#
# It has no read-only mode of its own, and it logs in as an ordinary user with
# full write rights, so the proxy's allowlist is the only thing restricting it.
# Unlike the other backends this one has no second layer -- see taigaTools in
# services/claude-mcp.nix.
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage rec {
  pname = "taiga-mcp-server";
  version = "1.9.20";

  src = fetchFromGitHub {
    owner = "greddy7574";
    repo = "taigaMcpServer";
    tag = "v${version}";
    hash = "sha256-n4UN76bR3AOuVpLolTDPUv8+/CvEgAaqs882ZwcATLI=";
  };

  npmDepsHash = "sha256-DDFFxVJV3wf6NJLg/ljeMRT0Py45+gfTHscdVvkHbyM=";

  # Plain ESM sources, no bundler step; package.json has no `build` script.
  dontNpmBuild = true;

  meta = {
    description = "MCP server for Taiga project management";
    homepage = "https://github.com/greddy7574/taigaMcpServer";
    license = lib.licenses.isc;
    mainProgram = "taiga-mcp";
  };
}
