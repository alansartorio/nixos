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
#      API key with read endpoint scopes, an Elasticsearch API key whose role
#      descriptor grants only read + view_index_metadata. Nothing above this
#      can be talked into a write the token cannot perform.
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

  # Not just != null. Every backend silently falls back to a PUBLIC cloud
  # instance when its host is empty -- gitea.com, app.getoutline.com,
  # api.taiga.io -- so an empty string would ship a corporate credential
  # off-site rather than merely fail to work.
  isSet = s: s != null && s != "";

  # Loopback ports for the backends. Arbitrary, but fixed so the proxy config
  # and the units cannot drift apart.
  giteaPort = 18190;
  outlinePort = 18191;
  taigaPort = 18192;
  elasticPort = 18193;

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

  # talhaorak/pytaiga-mcp has no read-only mode: it registers 94 tools and
  # means them, and it authenticates as an ordinary user with full write
  # rights. As with the server it replaced, this list is the only enforcement
  # on the route -- a typo landing on a real write tool name permits that
  # write.
  #
  # Derived from v2.0.1 by AST, not by name: every @mcp.tool function was
  # checked for a mutating call (api.*.{post,put,patch,delete,create,update,
  # edit,remove}) AND for calls to other module functions that mutate, to a
  # fixpoint. The transitive step is load-bearing -- assign_issue_to_user and
  # its siblings perform no mutating call of their own, they delegate to
  # update_issue, so a direct-call check marks four assign and four unassign
  # tools as reads. Validate any re-run against an indirect writer such as
  # assign_issue_to_user, not only against delete_project.
  #
  # That leaves 46 reads of 94. Two further exclusions beyond the write set:
  #
  #   login   takes an arbitrary `host`, so it would let a caller point this
  #           process at any URL -- an SSRF primitive on a machine that holds
  #           the VPN. The env credentials establish a default session at
  #           startup, so nothing needs it.
  #   logout  destroys that default session, leaving every other tool broken
  #           until the unit restarts. A denial of service on ourselves.
  #
  # Unlike the previous server this one writes nothing to disk at all -- no
  # open(), no download-to-path -- so it has no equivalent of the arbitrary
  # file write that kept downloadAttachment off the old list.
  taigaTools = [
    "get_custom_attribute_values"
    "get_default_session"
    "get_epic"
    "get_epic_by_ref"
    "get_filters_data"
    "get_history"
    "get_issue"
    "get_issue_by_ref"
    "get_issue_priorities"
    "get_issue_severities"
    "get_issue_statuses"
    "get_issue_types"
    "get_milestone"
    "get_milestone_stats"
    "get_project"
    "get_project_by_slug"
    "get_project_issue_stats"
    "get_project_members"
    "get_project_stats"
    "get_project_tags"
    "get_project_timeline"
    "get_task"
    "get_task_by_ref"
    "get_task_statuses"
    "get_user_story"
    "get_user_story_by_ref"
    "get_user_story_statuses"
    "get_user_timeline"
    "get_wiki_page"
    "list_all_projects"
    "list_attachments"
    "list_comments"
    "list_custom_attributes"
    "list_epics"
    "list_issues"
    "list_milestones"
    "list_points"
    "list_projects"
    "list_roles"
    "list_tasks"
    "list_user_stories"
    "list_wiki_links"
    "list_wiki_pages"
    "resolve"
    "search"
    "session_status"
  ];

  # Elastic's own server, and the only one of the four whose entire tool set is
  # already read-only -- there is no write tool to exclude, so this list is the
  # whole of what it offers rather than a filtered half.
  #
  # This talks to Elasticsearch directly rather than to Kibana's Agent Builder
  # MCP endpoint, which upstream now prefers: Agent Builder needs an Enterprise
  # subscription, and its tools are whatever that Kibana defines, so neither
  # the licence nor a fixed allowlist was available. Elasticsearch's own
  # security -- API keys, role descriptors -- is Basic-tier and needs none of
  # that, and read + view_index_metadata on the indices is the layer-1
  # enforcement here.
  # get_mappings is kept despite being broken against this cluster: it returns
  # "error decoding response body" on both a data stream and a single backing
  # index, while the same key reads documents fine, so it is a client bug in
  # 0.4.6 rather than a privilege problem. Left in so a version bump fixes it
  # silently; drop it if the dead tool is more annoying than the dead comment.
  elasticTools = [
    "esql"
    "get_mappings"
    "get_shards"
    "list_indices"
    "search"
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
      elastic = {
        url = "http://127.0.0.1:${toString elasticPort}/mcp";
        tools = elasticTools;
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
        assertion = cfg.gitea.enable -> isSet cfg.gitea.host;
        message = ''
          my.services.claudeMcp.gitea.enable requires a non-empty gitea.host.
          Empty is not merely useless: cmd.go:107 falls back to the public
          https://gitea.com, which would send the corporate PAT there.
        '';
      }
      {
        assertion = cfg.outline.enable -> isSet cfg.outline.url;
        message = ''
          my.services.claudeMcp.outline.enable requires a non-empty
          outline.url. Empty is worse than unset: server.py deletes OUTLINE_*
          vars whose value is "", and outline_client.py:146 then falls back to
          https://app.getoutline.com -- the API key for the company wiki would
          go to Outline's cloud.
        '';
      }
      {
        assertion = cfg.taiga.enable -> isSet cfg.taiga.url;
        message = ''
          my.services.claudeMcp.taiga.enable requires a non-empty taiga.url.
          taigaAuth.js:7 otherwise defaults to https://api.taiga.io, and this
          route authenticates with a real password.
        '';
      }
      {
        assertion = cfg.elastic.enable -> isSet cfg.elastic.url;
        message =
          ""
          + "my.services.claudeMcp.elastic.enable requires a non-empty elastic.url:\n"
          + "the Elasticsearch REST endpoint, e.g. https://es.example:9200. Its tool\n"
          + "set is fixed and wholly read-only, so no allowlist is asked for here.";
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
    # restartUnits throughout: rotating a credential re-renders the file at
    # activation, but NixOS only restarts a unit whose *definition* changed,
    # and swapping a token changes none of these units. Without this, a
    # rotated key leaves the service happily holding the revoked one -- which
    # presents as 401 rather than as anything that points at staleness.
    sops.secrets =
      lib.optionalAttrs cfg.gitea.enable {
        claude_mcp_gitea_token.restartUnits = [ "gitea-mcp.service" ];
      }
      // lib.optionalAttrs cfg.outline.enable {
        claude_mcp_outline_api_key = { };
      }
      // lib.optionalAttrs cfg.taiga.enable {
        claude_mcp_taiga_username = { };
        claude_mcp_taiga_password = { };
      }
      // lib.optionalAttrs cfg.elastic.enable {
        claude_mcp_elastic_api_key = { };
      };

    sops.templates =
      lib.optionalAttrs cfg.outline.enable {
        "claude-mcp-outline.env".restartUnits = [ "mcp-outline.service" ];
        "claude-mcp-outline.env".content = ''
          OUTLINE_API_KEY=${config.sops.placeholder.claude_mcp_outline_api_key}
        '';
      }
      // lib.optionalAttrs cfg.taiga.enable {
        "claude-mcp-taiga.env".restartUnits = [ "taiga-mcp.service" ];
        "claude-mcp-taiga.env".content = ''
          TAIGA_USERNAME=${config.sops.placeholder.claude_mcp_taiga_username}
          TAIGA_PASSWORD=${config.sops.placeholder.claude_mcp_taiga_password}
        '';
      }
      // lib.optionalAttrs cfg.elastic.enable {
        "claude-mcp-elastic.env".restartUnits = [ "elasticsearch-mcp.service" ];
        "claude-mcp-elastic.env".content =
          "" + "ES_API_KEY=${config.sops.placeholder.claude_mcp_elastic_api_key}\n";
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
          (lib.getExe pkgs.pytaiga-mcp)
        ];
      };
    };

    systemd.services.elasticsearch-mcp = lib.mkIf cfg.elastic.enable {
      description = "Elasticsearch MCP server (read-only) for Claude on VibeVM";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = noJit // {
        EnvironmentFile = config.sops.templates."claude-mcp-elastic.env".path;
        Environment = [ "ES_URL=${cfg.elastic.url}" ];
        # A Rust binary, so unlike the other three this is one static-ish
        # executable: no node, no python, no container runtime.
        ExecStart = "${lib.getExe pkgs.elasticsearch-mcp-server} http --address 127.0.0.1:${toString elasticPort}";
      };
    };

    systemd.services.mcp-readonly-proxy = {
      description = "Read-only MCP proxy exposed to VibeVM";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = noJit // {
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
