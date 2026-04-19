import os
import sys
import json
import traceback

try:
    import requests
except Exception:
    print("requests library required. Install with: pip install requests", file=sys.stderr)
    sys.exit(2)


def try_request(method, url, headers=None, json_payload=None, timeout=10):
    try:
        if method == "OPTIONS":
            r = requests.options(url, headers=headers, timeout=timeout)
        elif method == "GET":
            r = requests.get(url, headers=headers, timeout=timeout)
        elif method == "POST":
            r = requests.post(url, headers=headers, json=json_payload, timeout=timeout)
        else:
            return None, f"unsupported method {method}"
        return r, None
    except Exception as e:
        return None, str(e)


def main():
    key = os.getenv("STITCH_API_KEY")
    base = os.getenv("STITCH_BASE_URL", "https://stitch.withgoogle.com").rstrip("/")
    if not key:
        print("STITCH_API_KEY not set", file=sys.stderr)
        sys.exit(2)

    headers = {
        "Authorization": f"Bearer {key}",
        "Accept": "application/json",
        "User-Agent": "sistema_ro-mcp-discovery/1.0",
    }

    candidates = [
        "/api/preview",
        "/preview",
        "/api/v1/preview",
        "/v1/preview",
        "/api/previews",
        "/previews",
        "/api/mcp/preview",
        "/mcp/preview",
        "/api/v1/mcp",
        "/api/v2/preview",
        "/api/v1",
        "/v1",
        "/api",
        "/graphql",
        "/api/graphql",
        "/.well-known/mcp",
        "/mcp",
        "/api/v1/datasets/preview",
        "/v1/datasets/preview",
    ]

    results = []
    for path in candidates:
        url = base + path
        print("\n---\nChecking:", url)

        r, err = try_request("OPTIONS", url, headers=headers)
        if err:
            print("OPTIONS error:", err)
        else:
            print(f"OPTIONS {r.status_code}")
            allow = r.headers.get("Allow") or r.headers.get("allow")
            print("Allow:", allow)

        r, err = try_request("GET", url, headers=headers)
        if err:
            print("GET error:", err)
        else:
            print(f"GET {r.status_code} Content-Type: {r.headers.get('Content-Type')}")
            ctype = r.headers.get("Content-Type", "")
            if "application/json" in ctype:
                try:
                    print(json.dumps(r.json(), indent=2, ensure_ascii=False))
                except Exception:
                    print("Failed to parse JSON from GET")
            else:
                text = r.text[:1000]
                print("GET body (truncated):\n", text)

        # If path looks like preview, try POST with a safe sample payload
        if "preview" in path or "previews" in path:
            payload = {"sample": "sistema_ro_preview_test"}
            r, err = try_request("POST", url, headers=headers, json_payload=payload)
            if err:
                print("POST error:", err)
            else:
                print(f"POST {r.status_code} Content-Type: {r.headers.get('Content-Type')}")
                ctype = r.headers.get("Content-Type", "")
                if "application/json" in ctype:
                    try:
                        print(json.dumps(r.json(), indent=2, ensure_ascii=False))
                    except Exception:
                        print("Failed to parse JSON from POST")
                else:
                    print("POST body (truncated):\n", r.text[:1000])

    print("\nDiscovery finished.")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        traceback.print_exc()
        sys.exit(1)
