# Read-only MCP access to the intranet for Claude Code running on VibeVM.
#
# The problem this solves: VibeVM has no VPN of its own, and `claude` runs
# there wrapped in --dangerously-skip-permissions with passwordless sudo. That
# makes Claude root-equivalent on that machine, so nothing configured there is
# a boundary -- it can edit its own settings.json and its own .mcp.json. Any
# credential placed on the VM is a credential Claude can read.
#
# So both the credentials and the enforcement live here, on the machine that
# actually holds the VPN, and the guest is handed one unauthenticated HTTP port
# that speaks MCP and refuses to write.
#
# Three layers, deliberately independent:
#
#   1. The credential itself. A Gitea PAT with only read:* scopes, an Outline
#      API key with read endpoint scopes, a Kibana API key carrying
#      feature_agentBuilder.read. Nothing above this can be talked into a
#      write the token cannot perform.
#
#      Taiga is the exception, deliberately: it logs in as a real user with
#      full write rights, so it has no layer 1 at all. Everything there rests
#      on layer 2 -- see taigaTools.
#   2. mcp-readonly-proxy's per-route tools/call allowlist. This is the layer
#      Claude cannot edit, because it is on the far side of the firewall.
#   3. Each server's own read-only switch, where it has one. Convenience, and
#      it keeps tools/list honest -- but only that. github-mcp-server shipped a
#      --read-only that failed to restrict writes specifically under the HTTP
#      transport (github/github-mcp-server#2156), which is exactly the mode
#      these run in, so it is never the layer relied upon.
#
# The guest reaches only mcp-readonly-proxy; every backend binds to loopback.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.claudeMcp;

  # Loopback ports for the backends. Arbitrary, but fixed so the proxy config
  # and the units cannot drift apart.
  giteaPort = 18190;
  outlinePort = 18191;
  taigaPort = 18192;

  # Tools each route will forward. Every name here was read off a live
  # tools/list, not off a README -- the two disagree more often than not.
  #
  # Gitea groups its operations into dispatcher tools (issue_read takes a
  # `method` enum), so this list is short; `--read-only` already drops the 21
  # write tools and these 33 are what remains.
  giteaTools = [
    "actions_config_read"
    "actions_run_read"
    "attachment_read"
    "get_commit"
    "get_dir_contents"
    "get_file_contents"
    "get_gitea_mcp_server_version"
    "get_latest_release"
    "get_me"
    "get_release"
    "get_repository_tree"
    "get_tag"
    "get_user_orgs"
    "issue_read"
    "label_read"
    "list_branches"
    "list_commits"
    "list_issues"
    "list_my_repos"
    "list_org_repos"
    "list_pull_requests"
    "list_releases"
    "list_tags"
    "milestone_read"
    "notification_read"
    "package_read"
    "pull_request_read"
    "search_issues"
    "search_org_teams"
    "search_repos"
    "search_users"
    "timetracking_read"
    "wiki_read"
  ];

  # What OUTLINE_READ_ONLY=true leaves registered: features/documents/__init__
  # skips the content, editing, lifecycle, organization and batch modules, and
  # collection_tools gates its own writers internally.
  outlineTools = [
    "ask_ai_about_documents"
    "export_all_collections"
    "export_collection"
    "export_document"
    "fetch_attachment"
    "get_attachment_url"
    "get_collection_structure"
    "get_comment"
    "get_document_backlinks"
    "get_document_id_from_title"
    "get_document_toc"
    "list_collections"
    "list_document_attachments"
    "list_document_comments"
    "list_recently_updated_documents"
    "read_document"
    "read_document_section"
    "search_document_content"
    "search_documents"
  ];

  # Taiga's server has no read-only mode at all: it registers 46 tools and
  # means them, and it authenticates as an ordinary user with full write
  # rights. There is no scoped token to fall back on -- Taiga's application
  # tokens would be one, but this server only knows username/password.
  #
  # So unlike every other route, this list is not defence in depth. It is the
  # single thing standing between Claude and deleteWikiPage, and a typo that
  # lands on a real write tool name permits that write. Remove freely; add
  # only after redoing the audit below.
  #
  # Audited against v1.9.20 by source, not by name. Only two files in that
  # tree issue a mutating verb: taigaAuth.js (the login POST) and
  # taigaService.js, whose 19 mutating methods are addComment, create{Epic,
  # Issue,Milestone,Task,UserStory,WikiPage}, delete{Attachment,Comment,
  # WikiPage}, editComment, {link,unlink}StoryToEpic, update{Epic,Issue,
  # UserStory,WikiPage}, watchWikiPage and uploadAttachment. Every tool below
  # was traced to the taigaService.* methods its handler calls; none reaches
  # any of those. advancedSearch/queryHelp/validateQuery go through
  # src/query/, which contains no mutating verb at all.
  #
  # To redo it after a version bump: list each `export const <x>Tool` block
  # with the taigaService.* calls inside it, and check that against the
  # mutating-method set. Verify the check itself on a known write tool first
  # -- an extraction bug looks exactly like a clean pass.
  #
  # `authenticate` is in: it logs in (the one POST reachable from this list),
  # writes no data, and the server expects to refresh its own session.
  taigaTools = [
    "advancedSearch"
    "authenticate"
    "downloadAttachment"
    "getEpic"
    "getIssue"
    "getIssuesByMilestone"
    "getMilestone"
    "getMilestoneStats"
    "getProject"
    "getUserStory"
    "getWikiPage"
    "listAttachments"
    "listComments"
    "listEpics"
    "listIssues"
    "listMilestones"
    "listProjects"
    "listUserStories"
    "listWikiPages"
    "queryHelp"
    "validateQuery"
  ];

  routes =
    lib.optionalAttrs cfg.gitea.enable {
      gitea = {
        url = "http://127.0.0.1:${toString giteaPort}/mcp";
        tools = giteaTools;
      };
    }
    // lib.optionalAttrs cfg.outline.enable {
      outline = {
        url = "http://127.0.0.1:${toString outlinePort}/mcp";
        tools = outlineTools;
      };
    }
    // lib.optionalAttrs cfg.taiga.enable {
      taiga = {
        url = "http://127.0.0.1:${toString taigaPort}/mcp";
        tools = taigaTools;
      };
    }
    // lib.optionalAttrs cfg.elastic.enable {
      # No local backend: on Elastic 9.2+ Kibana serves Agent Builder's own MCP
      # endpoint, so there is nothing to package or run. The API key goes on in
      # the proxy rather than in a server, hence authHeaderFile.
      elastic = {
        url = cfg.elastic.url;
        tools = cfg.elastic.tools;
        authHeaderFile = "$CREDENTIALS_DIRECTORY/elastic-auth";
      };
    };

  proxyConfig = pkgs.writers.writeJSON "mcp-readonly-proxy.json" { inherit routes; };

  # Shared hardening. These processes hold the only intranet credentials on
  # this machine that a compromised guest would want.
  hardening = {
    DynamicUser = true;
    NoNewPrivileges = true;
    PrivateTmp = true;
    PrivateDevices = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = [
      "@system-service"
      "~@privileged"
    ];
    Restart = "always";
    RestartSec = 5;
  };

  # Only for the services that do not JIT. V8 maps memory writable and then
  # executable, so MemoryDenyWriteExecute aborts node before it finishes
  # starting -- which rules it out for taiga-mcp, the one Node backend.
  noJit = hardening // {
    MemoryDenyWriteExecute = true;
  };
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.gitea.enable -> cfg.gitea.host != null;
        message = "my.services.claudeMcp.gitea.enable requires gitea.host.";
      }
      {
        assertion = cfg.outline.enable -> cfg.outline.url != null;
        message = "my.services.claudeMcp.outline.enable requires outline.url.";
      }
      {
        assertion = cfg.taiga.enable -> cfg.taiga.url != null;
        message = "my.services.claudeMcp.taiga.enable requires taiga.url.";
      }
      {
        assertion = cfg.elastic.enable -> (cfg.elastic.url != null && cfg.elastic.tools != [ ]);
        message = ''
          my.services.claudeMcp.elastic.enable requires elastic.url and a
          non-empty elastic.tools. Agent Builder's tools are whatever that
          Kibana defines, so there is no honest default to guess -- list them
          from the Tools UI, or from a tools/list against the endpoint.
        '';
      }
    ];

    # Each secret stays root-owned at its default 0400: systemd reads
    # EnvironmentFile and LoadCredential as PID 1, before dropping to the
    # DynamicUser, so nothing here needs a static uid to own a token.
    #
    # Declared per sub-service rather than unconditionally, the way
    # modules/secrets.nix gates kimai_token: a machine that does not expose
    # Taiga has no business decrypting a Taiga password, and
    # sops-install-secrets fails loudly on a key the yaml lacks.
    sops.secrets =
      lib.optionalAttrs cfg.gitea.enable {
        claude_mcp_gitea_token = { };
      }
      // lib.optionalAttrs cfg.outline.enable {
        claude_mcp_outline_api_key = { };
      }
      // lib.optionalAttrs cfg.taiga.enable {
        claude_mcp_taiga_username = { };
        claude_mcp_taiga_password = { };
      }
      // lib.optionalAttrs cfg.elastic.enable {
        claude_mcp_kibana_api_key = { };
      };

    sops.templates =
      lib.optionalAttrs cfg.outline.enable {
        "claude-mcp-outline.env".content = ''
          OUTLINE_API_KEY=${config.sops.placeholder.claude_mcp_outline_api_key}
        '';
      }
      // lib.optionalAttrs cfg.taiga.enable {
        "claude-mcp-taiga.env".content = ''
          TAIGA_USERNAME=${config.sops.placeholder.claude_mcp_taiga_username}
          TAIGA_PASSWORD=${config.sops.placeholder.claude_mcp_taiga_password}
        '';
      }
      // lib.optionalAttrs cfg.elastic.enable {
        # The whole header value, so the proxy never has to know the scheme.
        "claude-mcp-elastic-auth".content =
          "ApiKey ${config.sops.placeholder.claude_mcp_kibana_api_key}";
      };

    systemd.services.gitea-mcp = lib.mkIf cfg.gitea.enable {
      description = "Gitea MCP server (read-only) for Claude on VibeVM";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = noJit // {
        # GITEA_ACCESS_TOKEN_FILE rather than the token in the environment:
        # an EnvironmentFile value is visible in `systemctl show`, a file is
        # not.
        LoadCredential = [ "gitea-token:${config.sops.secrets.claude_mcp_gitea_token.path}" ];
        Environment = [ "GITEA_ACCESS_TOKEN_FILE=%d/gitea-token" ];
        ExecStart = lib.concatStringsSep " " [
          (lib.getExe pkgs.gitea-mcp)
          "-transport http"
          "-bind 127.0.0.1"
          "-port ${toString giteaPort}"
          "-host ${cfg.gitea.host}"
          "-read-only"
        ];
      };
    };

    systemd.services.mcp-outline = lib.mkIf cfg.outline.enable {
      description = "Outline MCP server (read-only) for Claude on VibeVM";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = noJit // {
        EnvironmentFile = config.sops.templates."claude-mcp-outline.env".path;
        Environment = [
          "OUTLINE_API_URL=${cfg.outline.url}"
          "OUTLINE_READ_ONLY=true"
          "MCP_TRANSPORT=streamable-http"
          "MCP_HOST=127.0.0.1"
          "MCP_PORT=${toString outlinePort}"
        ];
        ExecStart = lib.getExe pkgs.mcp-outline;
      };
    };

    systemd.services.taiga-mcp = lib.mkIf cfg.taiga.enable {
      description = "Taiga MCP server (read-only via proxy allowlist) for Claude on VibeVM";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = hardening // {
        EnvironmentFile = config.sops.templates."claude-mcp-taiga.env".path;
        Environment = [ "TAIGA_API_URL=${cfg.taiga.url}" ];
        # taiga-mcp speaks stdio only, so mcp-proxy fronts it. --stateless
        # because nothing here needs session affinity, and it makes the
        # backend answer with plain application/json rather than an SSE frame.
        ExecStart = lib.concatStringsSep " " [
          (lib.getExe pkgs.mcp-proxy)
          "--host 127.0.0.1"
          "--port ${toString taigaPort}"
          "--stateless"
          "--pass-environment"
          (lib.getExe pkgs.taiga-mcp-server)
        ];
      };
    };

    systemd.services.mcp-readonly-proxy = {
      description = "Read-only MCP proxy exposed to VibeVM";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = noJit // {
        LoadCredential = lib.optional cfg.elastic.enable
          "elastic-auth:${config.sops.templates."claude-mcp-elastic-auth".path}";
        ExecStart = lib.concatStringsSep " " [
          (lib.getExe pkgs.mcp-readonly-proxy)
          "--config ${proxyConfig}"
          "--host ${cfg.listenAddress}"
          "--port ${toString cfg.port}"
        ];
      };
    };
  };
}
