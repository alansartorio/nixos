# Gitea's own MCP server, the one upstream ships at gitea.com/gitea/gitea-mcp.
#
# go_1_27 rather than the default toolchain: its go.mod asks for 1.27 and
# nixpkgs' `go` is still 1.26.7, which refuses the module outright. Drop the
# override once the default catches up.
{
  lib,
  buildGoModule,
  fetchFromGitea,
  go_1_27,
}:
(buildGoModule.override { go = go_1_27; }) rec {
  pname = "gitea-mcp";
  version = "1.7.0";

  src = fetchFromGitea {
    domain = "gitea.com";
    owner = "gitea";
    repo = "gitea-mcp";
    tag = "v${version}";
    hash = "sha256-JVt2nhwrJCqaoGS7NR7qQopRP9gJfxfgGsGTfkq6c/c=";
  };

  vendorHash = "sha256-YV9wmajErWqJE3jaYRZq1POyPfHhmUofNXrwlqmWcNc=";

  # main.go defaults Version to "dev" and only falls back to the build info,
  # which a nix build leaves empty.
  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${version}"
  ];

  meta = {
    description = "MCP server for interacting with Gitea instances";
    homepage = "https://gitea.com/gitea/gitea-mcp";
    license = lib.licenses.mit;
    mainProgram = "gitea-mcp";
  };
}
