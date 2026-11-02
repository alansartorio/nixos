#!/usr/bin/env python3
"""Entry point for pytaiga-mcp.

Upstream declares no [project.scripts] and expects `python src/server.py`,
which only works from a checkout. The installed distribution exposes the
module as `src.server`, so run that instead -- under run_name="__main__" so
its `if __name__ == "__main__": mcp.run()` fires.
"""

import runpy

runpy.run_module("src.server", run_name="__main__")
