import sys
import os
from datetime import datetime, timezone

# Ensure the backend root is in Python path so imports work
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from config.settings import get_settings
from db.collections import get_collections, CALENDAR_CREDENTIALS
import requests

USER_ID = "r1rix8GpmXVooG9dpwKv1Iz5VGe2"
settings = get_settings()

auth_url = (
    "https://accounts.google.com/o/oauth2/v2/auth"
    f"?client_id={settings.google_oauth_client_id}"
    "&response_type=code"
    "&scope=https://www.googleapis.com/auth/calendar.readonly"
    f"&redirect_uri={settings.google_oauth_redirect_uri}"
    "&access_type=offline"
    "&prompt=consent"
)

print("\n--- GOOGLE CALENDAR AUTH ---")
print("1. Click this link and sign in with your Google Account:")
print(f"\n{auth_url}\n")
print("2. Google will redirect you to a broken page (localhost:8080). That's normal!")
print("3. Look at the URL bar of the broken page. Copy the long code starting right after 'code='")

code = input("\nPaste the code here: ").strip()
# If the user pasted the entire URL by mistake, extract the code
if "code=" in code:
    code = code.split("code=")[1].split("&")[0]

print("Exchanging code for tokens...")
resp = requests.post(
    "https://oauth2.googleapis.com/token",
    data={
        "code": code,
        "client_id": settings.google_oauth_client_id,
        "client_secret": settings.google_oauth_client_secret,
        "redirect_uri": settings.google_oauth_redirect_uri,
        "grant_type": "authorization_code",
    }
)

tokens = resp.json()
if "access_token" in tokens:
    get_collections()[CALENDAR_CREDENTIALS].update_one(
        {"user_id": USER_ID},
        {"$set": {
            "access_token": tokens["access_token"],
            "refresh_token": tokens.get("refresh_token", ""),
            "updated_at": datetime.now(timezone.utc),
        }},
        upsert=True
    )
    print("✅ SUCCESS! The Python Backend is now synced with your Google Calendar!")
else:
    print("❌ Failed to get token:", tokens)
