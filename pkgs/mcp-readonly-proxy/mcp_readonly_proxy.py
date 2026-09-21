#!/usr/bin/env python3
"""A default-deny reverse proxy for MCP Streamable HTTP backends.

The point of this sitting between VibeVM and the MCP servers is that Claude
runs there with --dangerously-skip-permissions and passwordless sudo, so
nothing on that machine is a boundary: it can rewrite its own settings.json
and its own .mcp.json. This process runs on the other side of the firewall,
where it cannot.

Streamable HTTP is JSON-RPC over HTTP POST to a single endpoint, so the tool
being invoked is right there in the request body as params.name -- which is
what makes filtering possible at all. Two rules do the work:

  * an allowlist of JSON-RPC methods, so an unrecognised verb is refused
    rather than forwarded and hoped about, and
  * an allowlist of tool names on tools/call.

Both are per route. tools/call is the one that matters; filtering only
tools/list would be theatre, since a tool absent from the listing is still
perfectly callable by name.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import os
import sys
from dataclasses import dataclass, field
from pathlib import Path

import aiohttp
from aiohttp import web

log = logging.getLogger("mcp-readonly-proxy")

# Per RFC 9110; these describe a single hop and must not be relayed.
HOP_BY_HOP = frozenset(
    {
        "connection",
        "keep-alive",
        "proxy-authenticate",
        "proxy-authorization",
        "te",
        "trailer",
        "transfer-encoding",
        "upgrade",
    }
)

# Dropped on the way upstream.
#
# Origin and Sec-Fetch-Site are not hygiene, they are load-bearing: gitea-mcp
# wraps /mcp in Go's http.CrossOriginProtection and forces the check onto every
# method, including the safe ones. That check passes a request carrying neither
# header (it is assumed non-browser) and rejects one whose Origin host does not
# match Host. Since we rewrite Host on the way through, forwarding a client
# Origin would earn a 403 on every call.
#
# Authorization and Cookie go because the client has no business supplying
# credentials: whatever it sends is discarded and replaced by the route's own.
STRIP_FROM_CLIENT = frozenset(
    {
        "origin",
        "sec-fetch-site",
        "sec-fetch-mode",
        "sec-fetch-dest",
        "authorization",
        "cookie",
        "host",
        "content-length",
    }
)

# Backends invent their own credential headers, so an explicit list is a game
# of whack-a-mole: mcp-outline honours a per-request `x-outline-api-key` under
# the HTTP transport, which `authorization` above would not have caught. The
# rule is simply that the client never supplies a credential of any shape --
# the route's own is attached instead. None of the headers MCP actually needs
# (accept, content-type, mcp-session-id, mcp-protocol-version, last-event-id)
# matches any of these substrings.
CREDENTIAL_HEADER_MARKERS = ("api-key", "apikey", "token", "secret", "password", "auth")


def is_credential_header(name: str) -> bool:
    lowered = name.lower()
    return any(marker in lowered for marker in CREDENTIAL_HEADER_MARKERS)

# JSON-RPC verbs allowed through at all, before any tool-level check. Anything
# absent is refused: the MCP surface is small enough to enumerate, and a method
# this proxy has not heard of is a method whose semantics it cannot vouch for.
ALLOWED_RPC_METHODS = frozenset(
    {
        "initialize",
        "ping",
        "completion/complete",
        "logging/setLevel",
        "prompts/get",
        "prompts/list",
        "resources/list",
        "resources/read",
        "resources/subscribe",
        "resources/templates/list",
        "tools/call",
        "tools/list",
    }
)

MAX_BODY_BYTES = 1 << 20

# JSON-RPC reserved codes.
PARSE_ERROR = -32700
INVALID_REQUEST = -32600
METHOD_NOT_FOUND = -32601


@dataclass
class Route:
    name: str
    url: str
    tools: frozenset[str]
    auth: str | None = field(default=None, repr=False)


def jsonrpc_error(req_id, code: int, message: str) -> web.Response:
    """A refusal the client can actually read.

    HTTP 200 with a JSON-RPC error rather than an HTTP 403: a 403 surfaces at
    the client as a transport failure, which tends to be reported as "the MCP
    server is down" rather than "that tool is not allowed".
    """
    return web.json_response(
        {
            "jsonrpc": "2.0",
            "id": req_id,
            "error": {"code": code, "message": message},
        }
    )


def filter_tools_payload(payload: dict, route: Route) -> dict:
    """Drop tools the route would refuse to call from a tools/list result."""
    result = payload.get("result")
    if not isinstance(result, dict):
        return payload
    tools = result.get("tools")
    if not isinstance(tools, list):
        return payload
    kept = [
        t
        for t in tools
        if isinstance(t, dict) and t.get("name") in route.tools
    ]
    dropped = len(tools) - len(kept)
    if dropped:
        log.info("%s: hid %d write tool(s) from tools/list", route.name, dropped)
    result["tools"] = kept
    return payload


def rewrite_sse(body: str, route: Route) -> str:
    """Filter tools/list results carried in SSE data frames.

    A Streamable HTTP server may answer a POST with either application/json or
    a text/event-stream carrying the response as one data frame -- FastMCP
    picks the latter -- so a listing has to be filtered in both shapes.
    """
    out = []
    for line in body.split("\n"):
        if line.startswith("data:"):
            raw = line[5:].strip()
            try:
                payload = json.loads(raw)
            except json.JSONDecodeError:
                out.append(line)
                continue
            if isinstance(payload, dict):
                payload = filter_tools_payload(payload, route)
            out.append("data: " + json.dumps(payload, separators=(",", ":")))
        else:
            out.append(line)
    return "\n".join(out)


def upstream_headers(request: web.Request, route: Route) -> dict[str, str]:
    headers = {}
    for k, v in request.headers.items():
        lowered = k.lower()
        if lowered in STRIP_FROM_CLIENT or lowered in HOP_BY_HOP:
            continue
        if is_credential_header(lowered):
            log.warning("%s: dropped client credential header %r", route.name, k)
            continue
        headers[k] = v
    if route.auth:
        headers["Authorization"] = route.auth
    return headers


async def forward(
    request: web.Request,
    route: Route,
    body: bytes | None,
    *,
    buffer: bool = False,
) -> web.StreamResponse:
    session: aiohttp.ClientSession = request.app["session"]
    try:
        upstream = await session.request(
            request.method,
            route.url,
            headers=upstream_headers(request, route),
            data=body,
            allow_redirects=False,
        )
    except aiohttp.ClientError as exc:
        log.warning("%s: upstream unreachable: %s", route.name, exc)
        return jsonrpc_error(None, INVALID_REQUEST, f"upstream unreachable: {exc}")

    async with upstream:
        # Content-Length goes because the body may be rewritten below, and is
        # streamed (hence chunked) when it is not.
        headers = {
            k: v
            for k, v in upstream.headers.items()
            if k.lower() not in HOP_BY_HOP and k.lower() != "content-length"
        }

        if buffer:
            # Not content.read(MAX_BODY_BYTES): StreamReader.read(n) returns up
            # to n bytes, whatever has arrived, so a chunked listing comes back
            # truncated mid-JSON about half the time. Drain it properly instead.
            chunks: list[bytes] = []
            total = 0
            async for chunk in upstream.content.iter_any():
                total += len(chunk)
                if total > MAX_BODY_BYTES:
                    log.warning("%s: upstream response too large", route.name)
                    return jsonrpc_error(
                        None, INVALID_REQUEST, "upstream response too large"
                    )
                chunks.append(chunk)
            raw = b"".join(chunks)
            content_type = upstream.headers.get("Content-Type", "")
            text = raw.decode("utf-8", errors="replace")
            if "text/event-stream" in content_type:
                text = rewrite_sse(text, route)
            elif "application/json" in content_type:
                try:
                    payload = json.loads(text)
                except json.JSONDecodeError:
                    pass
                else:
                    if isinstance(payload, dict):
                        payload = filter_tools_payload(payload, route)
                        text = json.dumps(payload, separators=(",", ":"))
            return web.Response(
                status=upstream.status, headers=headers, body=text.encode()
            )

        response = web.StreamResponse(status=upstream.status, headers=headers)
        await response.prepare(request)
        try:
            async for chunk in upstream.content.iter_any():
                await response.write(chunk)
        except (aiohttp.ClientError, asyncio.CancelledError):
            # Client hung up mid-stream, or the tunnel dropped. Nothing to say.
            pass
        await response.write_eof()
        return response


async def handle(request: web.Request) -> web.StreamResponse:
    route: Route | None = request.app["routes"].get(request.match_info["route"])
    if route is None:
        raise web.HTTPNotFound(text="no such route\n")

    # GET opens the server-to-client SSE stream, DELETE tears a session down.
    # Neither carries a JSON-RPC body to inspect.
    if request.method in ("GET", "DELETE"):
        return await forward(request, route, None)

    raw = await request.content.read(MAX_BODY_BYTES + 1)
    if len(raw) > MAX_BODY_BYTES:
        return jsonrpc_error(None, INVALID_REQUEST, "request body too large")

    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        return jsonrpc_error(None, PARSE_ERROR, f"invalid JSON: {exc}")

    # Batching was dropped in the 2025-06-18 revision, and a batch would let a
    # denied call ride along beside an allowed one. Refuse the shape entirely.
    if not isinstance(payload, dict):
        return jsonrpc_error(None, INVALID_REQUEST, "batched requests are not accepted")

    method = payload.get("method")
    req_id = payload.get("id")

    # Notifications are one-way and carry no tool invocation.
    if isinstance(method, str) and method.startswith("notifications/"):
        return await forward(request, route, raw)

    if method not in ALLOWED_RPC_METHODS:
        log.warning("%s: refused JSON-RPC method %r", route.name, method)
        return jsonrpc_error(
            req_id, METHOD_NOT_FOUND, f"method {method!r} is not permitted by the proxy"
        )

    if method == "tools/call":
        params = payload.get("params")
        name = params.get("name") if isinstance(params, dict) else None
        if name not in route.tools:
            log.warning("%s: DENIED tools/call %r", route.name, name)
            return jsonrpc_error(
                req_id,
                METHOD_NOT_FOUND,
                f"tool {name!r} is not permitted by the read-only proxy",
            )
        log.info("%s: tools/call %s", route.name, name)

    # tools/list is the one response worth buffering: it is small, it never
    # streams in practice, and rewriting it keeps Claude from being shown
    # tools that a later tools/call would refuse.
    return await forward(request, route, raw, buffer=(method == "tools/list"))


async def healthz(_: web.Request) -> web.Response:
    return web.Response(text="ok\n")


def load_routes(path: Path) -> dict[str, Route]:
    config = json.loads(path.read_text())
    routes: dict[str, Route] = {}
    for name, spec in config["routes"].items():
        auth = None
        # The credential is read from a file rather than taken as a string, so
        # it never appears in the unit's ExecStart, in /proc/<pid>/cmdline, or
        # in the nix store. sops renders the file; only its path is public.
        if spec.get("authHeaderFile"):
            # expandvars so a unit can hand over $CREDENTIALS_DIRECTORY/<id>
            # and keep the config file free of a systemd-generated path.
            auth = Path(os.path.expandvars(spec["authHeaderFile"])).read_text().strip()
        routes[name] = Route(
            name=name,
            url=spec["url"],
            tools=frozenset(spec.get("tools", [])),
            auth=auth,
        )
    return routes


async def make_app(routes: dict[str, Route]) -> web.Application:
    app = web.Application()
    app["routes"] = routes

    async def with_session(app: web.Application):
        # No total timeout: an idle SSE stream is normal and must not be cut.
        timeout = aiohttp.ClientTimeout(total=None, connect=15, sock_read=None)
        async with aiohttp.ClientSession(timeout=timeout) as session:
            app["session"] = session
            yield

    app.cleanup_ctx.append(with_session)
    app.router.add_route("*", "/{route}/mcp", handle)
    app.router.add_get("/healthz", healthz)
    return app


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=18100)
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format="%(levelname)s %(message)s",
        stream=sys.stderr,
    )

    routes = load_routes(args.config)
    for route in routes.values():
        log.info(
            "route /%s/mcp -> %s (%d tool(s) allowed)",
            route.name,
            route.url,
            len(route.tools),
        )

    web.run_app(
        make_app(routes),
        host=args.host,
        port=args.port,
        print=None,
        access_log=None,
    )


if __name__ == "__main__":
    main()
