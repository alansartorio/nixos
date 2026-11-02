# Packages defined in this repo, exposed as an overlay so they are reachable as
# pkgs.<name> from any module.
inputs: final: prev: {
  desktop-scripts = final.callPackage ./desktop-scripts {
    clockin = inputs.clockin.packages.${final.stdenv.hostPlatform.system}.default;
  };

  eww-scripts = final.callPackage ./eww-scripts {
    clockin = inputs.clockin.packages.${final.stdenv.hostPlatform.system}.default;
  };

  # Read-only MCP servers for the intranet, fronted by mcp-readonly-proxy.
  gitea-mcp = final.callPackage ./gitea-mcp { };
  pytaiga-mcp = final.callPackage ./pytaiga-mcp { };
  mcp-readonly-proxy = final.callPackage ./mcp-readonly-proxy { };
  elasticsearch-mcp-server = final.callPackage ./elasticsearch-mcp-server { };
}
