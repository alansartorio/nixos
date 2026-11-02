# talhaorak/pytaiga-mcp -- a richer Taiga MCP server than greddy7574's: 94
# tools against 46, adding project and issue stats, history, timelines,
# members, custom attributes, and a resolver.
#
# Two caveats that shape how it is used here:
#
#   * Its one dependency of substance, pytaigaclient, is not on PyPI. uv.lock
#     pins it to a commit of the same author's other repo, which is what the
#     inner derivation reproduces. Neither package has a published artifact to
#     check the source against, unlike the server this replaces.
#   * 49 of the 94 tools write, including delete_project and
#     invite_project_user, and there is no read-only mode. The proxy allowlist
#     is the only thing restricting it -- see taigaTools in
#     services/claude-mcp.nix.
#
# stdio only: src/server.py ends in a bare `mcp.run()` and parses no argv, so
# run.sh's `--sse` is silently ignored whatever the README says. mcp-proxy
# bridges it to HTTP, the same way the previous server was handled.
{
  lib,
  python3Packages,
  fetchFromGitHub,
}:
let
  pytaigaclient = python3Packages.buildPythonPackage {
    pname = "pytaigaclient";
    version = "0.1.0-unstable-2025-04-13";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "talhaorak";
      repo = "pyTaigaClient";
      # The commit uv.lock pins, not a branch tip.
      rev = "30368f9cf35c42c3ce28d8cf17791f29bb5eb81a";
      hash = "sha256-KZbekq1gPnK+3is26w3I48KXxydbJlPLRYCsanqEsG8=";
    };

    build-system = [ python3Packages.hatchling ];
    dependencies = [ python3Packages.requests ];

    doCheck = false;
    pythonImportsCheck = [ "pytaigaclient" ];
  };
in
python3Packages.buildPythonApplication rec {
  pname = "pytaiga-mcp";
  version = "2.0.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "talhaorak";
    repo = "pytaiga-mcp";
    tag = "v${version}";
    hash = "sha256-Jq6aODTHubjgQYj+Ep4eESDIzHD9xqXj6ae8yeCRP1A=";
  };

  build-system = [
    python3Packages.setuptools
    python3Packages.wheel
  ];

  dependencies = with python3Packages; [
    # Uses FastMCP, which mcp 2.x renamed; mcp_1 only exists once nixpkgs ships 2.x.
    (python3Packages.mcp_1 or mcp)
    python-dotenv
    pydantic
    pydantic-settings
    pytaigaclient
  ];

  # pyproject declares no [project.scripts] -- upstream expects
  # `python src/server.py`, which only works from a checkout. The shim is a
  # Python script rather than a sh exec so wrapPythonPrograms puts the
  # dependencies on its PYTHONPATH; a bare interpreter cannot import
  # src.server.
  postInstall = ''
    install -Dm755 ${./pytaiga-mcp.py} $out/bin/pytaiga-mcp
  '';

  # The suite wants a live Taiga.
  doCheck = false;

  # Upstream installs its package as the top-level name `src`.
  pythonImportsCheck = [ "src.server" ];

  meta = {
    description = "MCP server for Taiga project management";
    homepage = "https://github.com/talhaorak/pytaiga-mcp";
    license = lib.licenses.mit;
    mainProgram = "pytaiga-mcp";
  };
}
