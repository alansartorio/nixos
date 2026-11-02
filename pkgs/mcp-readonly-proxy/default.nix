# The boundary itself. See mcp_readonly_proxy.py for why it exists rather than
# a permissions entry in Claude Code's own config.
{
  lib,
  python3Packages,
}:
python3Packages.buildPythonApplication {
  pname = "mcp-readonly-proxy";
  version = "0.1.0";
  format = "other";

  src = ./.;

  dependencies = [ python3Packages.aiohttp ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 ${./mcp_readonly_proxy.py} $out/bin/mcp-readonly-proxy
    runHook postInstall
  '';

  meta = {
    description = "Default-deny filtering proxy for MCP Streamable HTTP backends";
    license = lib.licenses.mit;
    mainProgram = "mcp-readonly-proxy";
  };
}
