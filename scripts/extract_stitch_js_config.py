import requests
import re
import sys


def main():
    url = "https://stitch.withgoogle.com"
    print("Fetching:", url)
    r = requests.get(url, headers={"User-Agent": "sistema_ro-config-extractor/1.0"}, timeout=20)
    print("Status:", r.status_code)
    text = r.text

    # Find URLs
    urls = set(re.findall(r"https?://[\w\-._~:/?#\[\]@!$&'()*+,;=%]+", text))
    print(f"Found {len(urls)} URL candidates (showing up to 50):")
    count = 0
    for u in sorted(urls):
        print(u)
        count += 1
        if count >= 50:
            break

    # Try to extract JSON-like JS config variables
    patterns = [
        r"window\[['\"]ppConfig['\"]]\s*=\s*(\{.*?\});",
        r"window\.__INITIAL_STATE__\s*=\s*(\{.*?\});",
        r"window\.__CONFIG__\s*=\s*(\{.*?\});",
        r"var\s+CONFIG\s*=\s*(\{.*?\});",
    ]

    for pat in patterns:
        m = re.search(pat, text, flags=re.S)
        if m:
            print(f"\nMatched pattern: {pat}\n")
            snippet = m.group(1)
            print(snippet[:2000])
        else:
            print(f"\nNo match for pattern: {pat}")

    # Search for common configuration keys
    keys = ["api", "apiHost", "api_base", "API_BASE", "BASE_URL", "apiKey", "mcp", "preview"]
    print("\nSearching for config keys in HTML...")
    for k in keys:
        if k.lower() in text.lower():
            print(f"Found key fragment: {k}")

    print("\nDone.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print("Error:", e, file=sys.stderr)
        sys.exit(1)
