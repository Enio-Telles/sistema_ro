import os
import uuid
import logging
from typing import Any, Dict, Optional, List

try:
    import requests
except Exception:  # pragma: no cover - requests may not be installed in minimal env
    requests = None


logger = logging.getLogger(__name__)


def _env_first(*names: str) -> Optional[str]:
    """Return first non-empty environment variable from names (order prioritized)."""
    for n in names:
        v = os.getenv(n)
        if v:
            return v
    return None


class StitchClient:
    """
    Minimal client for Stitch MCP integration.

    Environment variables supported:
      - STITCH_BASE_URL (optional, defaults to https://stitch.googleapis.com/mcp)
      - STITCH_API_KEY (optional)  -> sent as X-Goog-Api-Key header
      - STITCH_ACCESS_TOKEN (optional) -> sent as Authorization: Bearer <token>

    Behavior: prefer `STITCH_ACCESS_TOKEN` (Bearer) if present, otherwise use `STITCH_API_KEY`.
    """

    def __init__(self, base_url: Optional[str] = None, api_key: Optional[str] = None, access_token: Optional[str] = None, request_timeout: int = 8, verbose: bool = False):
        self.base_url = (base_url or os.getenv("STITCH_BASE_URL") or "https://stitch.googleapis.com/mcp").rstrip("/")
        # Support multiple environment variable names; the repository .env uses `Stitch_API`
        self.api_key = api_key or _env_first("STITCH_API_KEY", "STITCH_API", "Stitch_API")
        self.access_token = access_token or _env_first("STITCH_ACCESS_TOKEN", "STITCH_TOKEN", "Stitch_Access_Token")
        # Per-request timeout (seconds) and verbose probe printing
        self.request_timeout = int(request_timeout) if request_timeout is not None else 8
        self.verbose = bool(verbose)
        if requests is None:
            raise RuntimeError("requests library required; install with `pip install requests`")
        self.session = requests.Session()
        # Default headers
        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "User-Agent": "sistema_ro-stitch-client/1.0",
        }
        # Prefer short-lived access token (OAuth) if present
        if self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"
        elif self.api_key:
            headers["X-Goog-Api-Key"] = self.api_key

        self.session.headers.update(headers)

    def _candidate_envelopes(self, payload: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Return a list of plausible MCP envelope variants to try against the server.

        We do several common envelope shapes (JSON-RPC, tool-call, generic message)
        so the client can probe what the remote MCP endpoint expects without hard
        coding a single guessed format.
        """
        uid = str(uuid.uuid4())
        candidates: List[Dict[str, Any]] = []

        # JSON-RPC method candidates (many method names to probe what server expects)
        methods = [
            "preview",
            "mcp.preview",
            "tool.preview",
            "callTool",
            "invoke",
            "tool.invoke",
            "tool.call",
            "call",
            "execute",
            "run",
            # discovery / rpc helpers
            "rpc.discover",
            "rpc.methods",
            "rpc.listMethods",
            "rpc.getMethods",
            "rpc.getSupportedMethods",
            "system.listMethods",
            "rpc.describe",
            "rpc.getMethodList",
            "mcp.discover",
            "mcp.getMethods",
            "mcp.listTools",
            # tool listing
            "tool.list",
            "tools.list",
            "tool.describe",
            "tool.methods",
            "tool.get",
            "tool.info",
            "tool.discovery",
            # plugin/agent patterns
            "run_tool",
            "invoke_tool",
            "execute_tool",
            "call_tool",
            "tool.run",
            "tool.execute",
            "agent.invoke",
            "agent.call",
            "agent.run",
            "agent.execute",
            "llm.invoke",
            "plugin.invoke",
            "plugin.call",
            "plugin.run",
            "call_plugin",
            "invoke_plugin",
            "execute_plugin",
            "toolbox.invoke",
            "toolbox.call",
            "toolbox.run",
            "command.run",
            "command.invoke",
            "command.call",
            "commands.list",
            "get_tools",
            "list_tools",
            "get_methods",
            "discover_methods",
            "get_method_info",
            "list_available_tools",
            # Stitch-specific guesses
            "stitch.run",
            "stitch.invoke",
            "stitch.preview",
            "stitch.execute",
            "stitch.call",
            "stitch.tool",
            "preview_tool",
            "preview.run",
            "get_preview",
            "preview.call",
            "preview.invoke",
            "runtime.preview",
            "runtime.invoke",
            "runtime.call",
            "runtime.run",
            "runtime.execute",
            "agregacao.preview",
            "agregacao.run",
            "conversao.preview",
            "estoque.preview",
            "fisconforme.preview",
            "agregation.preview",
        ]

        for method in methods:
            # params as raw payload
            candidates.append({"jsonrpc": "2.0", "method": method, "params": payload, "id": uid})
            # params wrapped
            candidates.append({"jsonrpc": "2.0", "method": method, "params": {"payload": payload}, "id": uid})
            # params with tool/args semantic
            candidates.append({"jsonrpc": "2.0", "method": method, "params": {"tool": "preview", "args": payload}, "id": uid})
            # positional params (array) and tool-style positional params
            candidates.append({"jsonrpc": "2.0", "method": method, "params": [payload], "id": uid})
            candidates.append({"jsonrpc": "2.0", "method": method, "params": ["preview", payload], "id": uid})
            candidates.append({"jsonrpc": "2.0", "method": method, "params": [{"tool": "preview", "args": payload}], "id": uid})
            # id variations: numeric id and explicit null id
            candidates.append({"jsonrpc": "2.0", "method": method, "params": payload, "id": None})
            candidates.append({"jsonrpc": "2.0", "method": method, "params": payload, "id": 0})

        # Other common envelope shapes
        candidates.extend([
            payload,  # raw payload
            {"type": "request", "id": uid, "action": "preview", "body": payload},
            {"mcp_version": "0.1.0", "request": {"tool": "preview", "args": payload, "id": uid}},
            {"tool": "preview", "args": payload, "id": uid},
            {"message": {"type": "preview", "payload": payload, "id": uid}},
            {"method": "preview", "params": payload, "id": uid},
        ])

        return candidates

    def preview(self, payload: Dict[str, Any]) -> Any:
        """
        Send a POST to the MCP endpoint (root) trying several envelope variants.

        Returns parsed JSON when available. If no candidate succeeds, raises
        a RuntimeError summarizing all attempts (status codes and response excerpts).
        """
        url = f"{self.base_url}"

        attempts: List[Dict[str, Any]] = []
        content_types = ["application/json", "application/mcp+json", "application/vnd.mcp+json"]

        for idx, envelope in enumerate(self._candidate_envelopes(payload), start=1):
            for ctype in content_types:
                headers = {"Content-Type": ctype}
                try:
                    logger.debug("StitchClient.preview try %d ctype=%s", idx, ctype)
                    resp = self.session.post(url, json=envelope, headers=headers, timeout=self.request_timeout)
                except Exception as e:  # network/connection errors
                    attempts.append({"envelope_index": idx, "content_type": ctype, "error": str(e)})
                    continue

                status = resp.status_code
                resp_ct = resp.headers.get("Content-Type", "")
                text = resp.text
                parsed: Optional[Any] = None
                if "application/json" in resp_ct or resp_ct.startswith("application/"):
                    try:
                        parsed = resp.json()
                    except Exception:
                        parsed = text

                attempts.append({"envelope_index": idx, "content_type": resp_ct, "status": status, "response": parsed})

                # Accept any 2xx response as success
                if 200 <= status < 300:
                    return parsed if parsed is not None else text

                # Some MCP servers return 400 with a structured JSON error we can return for inspection
                if status == 400 and parsed:
                    return parsed

        # No candidate worked; assemble diagnostic message and raise
        msg_lines = ["All MCP envelope attempts failed:"]
        for i, a in enumerate(attempts, start=1):
            if a.get("error"):
                msg_lines.append(f"- attempt {i}: error={a['error']}")
            else:
                summary = str(a.get("response"))[:300]
                msg_lines.append(f"- attempt {i}: status={a.get('status')} content_type={a.get('content_type')} response={summary}")

        raise RuntimeError("\n".join(msg_lines))

    def probe(self, payload: Dict[str, Any], content_types: Optional[List[str]] = None, stop_on_first_success: bool = False, max_attempts: Optional[int] = None) -> Dict[str, Any]:
        """
        Probe the MCP endpoint using the candidate envelopes and return a diagnostic report.

        Returns a dict: {"success": <attempt> or None, "attempts": [ ... ]}
        Each attempt contains: envelope_index, content_type, envelope, status, response or error.
        """
        url = f"{self.base_url}"
        content_types = content_types or ["application/json", "application/mcp+json", "application/vnd.mcp+json"]
        attempts: List[Dict[str, Any]] = []

        for idx, envelope in enumerate(self._candidate_envelopes(payload), start=1):
            for ctype in content_types:
                headers = {"Content-Type": ctype}
                try:
                    resp = self.session.post(url, json=envelope, headers=headers, timeout=self.request_timeout)
                except Exception as e:
                    attempts.append({"envelope_index": idx, "content_type": ctype, "envelope": envelope, "error": str(e)})
                    # respect max_attempts limit
                    if max_attempts is not None and len(attempts) >= max_attempts:
                        return {"success": None, "attempts": attempts}
                    continue

                status = resp.status_code
                resp_ct = resp.headers.get("Content-Type", "")
                parsed: Optional[Any] = None
                text = resp.text
                if "application/json" in resp_ct or resp_ct.startswith("application/"):
                    try:
                        parsed = resp.json()
                    except Exception:
                        parsed = text

                attempt = {"envelope_index": idx, "content_type": resp_ct, "envelope": envelope, "status": status, "response": parsed}
                attempts.append(attempt)

                # respect max_attempts limit
                if max_attempts is not None and len(attempts) >= max_attempts:
                    return {"success": None, "attempts": attempts}

                # Treat JSON-RPC error objects as non-successful — continue probing
                is_jsonrpc_error = isinstance(parsed, dict) and parsed.get("jsonrpc") == "2.0" and parsed.get("error") is not None
                if 200 <= status < 300 and not is_jsonrpc_error:
                    return {"success": attempt, "attempts": attempts}

                # Optionally print lightweight progress for interactive debugging
                if getattr(self, "verbose", False):
                    try:
                        method_hint = envelope.get("method") if isinstance(envelope, dict) else None
                    except Exception:
                        method_hint = None
                    print(f"[probe] idx={idx} ctype={ctype} method={method_hint} status={status}")

        return {"success": None, "attempts": attempts}


__all__ = ["StitchClient"]
