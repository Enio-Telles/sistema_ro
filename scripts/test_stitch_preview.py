import os
import sys
import json
import importlib.util
import traceback


def load_dotenv(path: str = ".env") -> None:
    """Load simple key=value lines from a .env file into os.environ if not already set."""
    if not os.path.exists(path):
        return
    try:
        with open(path, "r", encoding="utf8") as f:
            for raw in f:
                line = raw.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                k = k.strip()
                v = v.strip().strip('"').strip("'")
                if k and k not in os.environ:
                    os.environ[k] = v
    except Exception:
        # best-effort; do not crash on malformed .env
        return


def main():
    # Load .env if present so the repo-local `Stitch_API` var is respected
    load_dotenv()

    key = (
        os.getenv("STITCH_API_KEY")
        or os.getenv("STITCH_API")
        or os.getenv("Stitch_API")
        or os.getenv("STITCH_APIKEY")
    )
    if not key:
        print(
            "No Stitch API key found. Set STITCH_API_KEY or Stitch_API in environment or .env",
            file=sys.stderr,
        )
        sys.exit(2)

    repo_root = os.getcwd()
    mod_path = os.path.join(repo_root, "backend", "app", "integrations", "stitch_mcp.py")
    if not os.path.exists(mod_path):
        print(f"Module not found at {mod_path}", file=sys.stderr)
        sys.exit(2)

    spec = importlib.util.spec_from_file_location("stitch_mcp", mod_path)
    module = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(module)
    except Exception as e:
        print("Error importing module:", str(e), file=sys.stderr)
        traceback.print_exc()
        sys.exit(3)

    StitchClient = getattr(module, "StitchClient", None)
    if StitchClient is None:
        print("StitchClient not found in module", file=sys.stderr)
        sys.exit(3)

    try:
        # Use a shorter per-request timeout and enable verbose progress printing
        client = StitchClient(request_timeout=6, verbose=True)
        report = client.probe({"sample": "payload"}, stop_on_first_success=True, max_attempts=60)

        success = report.get("success")
        attempts = report.get("attempts", [])

        if success:
            print("Success:\n", json.dumps(success, indent=2, ensure_ascii=False))
            sys.exit(0)

        # Print first attempts that contain structured JSON-RPC errors or non-2xx responses
        printed = 0
        for a in attempts:
            resp = a.get("response")
            if isinstance(resp, dict) and resp.get("jsonrpc") == "2.0":
                print(json.dumps({
                    "envelope_index": a.get("envelope_index"),
                    "content_type": a.get("content_type"),
                    "envelope": a.get("envelope"),
                    "response": resp,
                }, indent=2, ensure_ascii=False))
                printed += 1
                if printed >= 5:
                    break

        if printed == 0:
            # Fallback: print a short summary of the first 6 attempts
            summary = []
            for a in attempts[:6]:
                summary.append({
                    "envelope_index": a.get("envelope_index"),
                    "content_type": a.get("content_type"),
                    "status": a.get("status"),
                    "response_preview": (str(a.get("response"))[:200] if a.get("response") is not None else None),
                })
            print(json.dumps({"summary": summary}, indent=2, ensure_ascii=False))
        sys.exit(0)
    except Exception as e:
        print("Error calling probe:", str(e), file=sys.stderr)
        traceback.print_exc()
        sys.exit(4)


if __name__ == "__main__":
    main()
