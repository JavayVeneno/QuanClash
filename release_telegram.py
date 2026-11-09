import os
import json
import requests

TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")
TAG = os.getenv("TAG", "")
RUN_ID = os.getenv("RUN_ID", "")

if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
    print("TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID are required; skipping.")
    raise SystemExit(0)

IS_STABLE = "-" not in TAG

CHAT_ID = TELEGRAM_CHAT_ID
API_URL = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMediaGroup"

DIST_DIR = os.path.join(os.getcwd(), "dist")
release = os.path.join(os.getcwd(), "release.md")

text = ""

media = []
files = {}

i = 1

releaseKeywords = [
    "windows-amd64-setup",
    "android-arm64",
    "macos-arm64",
    "macos-amd64"
]

for file in os.listdir(DIST_DIR):
    file_path = os.path.join(DIST_DIR, file)
    if os.path.isfile(file_path):
        file_lower = file.lower()
        if any(kw in file_lower for kw in releaseKeywords):
            file_key = f"file{i}"
            media.append({
                "type": "document",
                "media": f"attach://{file_key}"
            })
            files[file_key] = open(file_path, 'rb')
            i += 1

if TAG:
    text += f"\n**{TAG}**\n"

if IS_STABLE:
    text += f"\nhttps://github.com/JavayVeneno/quanclash/releases/tag/{TAG}\n"
else:
    text += f"\nhttps://github.com/JavayVeneno/quanclash/actions/runs/{RUN_ID}\n"

if os.path.exists(release):
    text += "\n"
    with open(release, 'r') as f:
        text += f.read()
    text += "\n"

if media:
    media[-1]["caption"] = text
    media[-1]["parse_mode"] = "Markdown"

response = requests.post(
    API_URL,
    data={
        "chat_id": CHAT_ID,
        "media": json.dumps(media)
    },
    files=files
)

print("Response JSON:", response.json())
