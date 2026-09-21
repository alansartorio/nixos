# MCP server for Outline. Community, but it carries a real OUTLINE_READ_ONLY
# mode: with it set, features/documents/__init__.py never registers the
# content, editing, lifecycle, organization or batch modules, and
# collection_tools gates its own writers. What survives is 18 tools, all reads.
{
  lib,
  python3Packages,
  fetchFromGitHub,
}:
python3Packages.buildPythonApplication rec {
  pname = "mcp-outline";
  version = "1.10.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Vortiago";
    repo = "mcp-outline";
    tag = "v${version}";
    hash = "sha256-mqsiNhPkyVgPEApU8V+r8njz/BM8LlktPiijxQ4kEMY=";
  };

  build-system = with python3Packages; [
    setuptools
    setuptools-scm
  ];

  # pyproject sets `dynamic = ["version"]` via setuptools-scm, which needs a
  # git tree it does not get from a tarball.
  env.SETUPTOOLS_SCM_PRETEND_VERSION = version;

  dependencies = with python3Packages; [
    mcp
    httpx
    python-dotenv
  ];

  pythonImportsCheck = [ "mcp_outline" ];

  # The test suite reaches for a live Outline instance.
  doCheck = false;

  meta = {
    description = "MCP server for the Outline knowledge base";
    homepage = "https://github.com/Vortiago/mcp-outline";
    license = lib.licenses.mit;
    mainProgram = "mcp-outline";
  };
}
