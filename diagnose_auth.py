
import os
import re

def check_file_exists(path):
    exists = os.path.exists(path)
    print(f"[{'OK' if exists else 'MISSING'}] Checking {path}")
    return exists

def check_content(path, regex, description):
    if not os.path.exists(path):
        return False
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    match = re.search(regex, content)
    print(f"[{'OK' if match else 'MISSING'}] {description}")
    return bool(match)

print("=== BizAgent Google Auth Diagnostic Tool ===\n")

# 1. Check Pubspec Dependencies
has_google_sign_in = check_content('pubspec.yaml', r'google_sign_in:', 'Dependency: google_sign_in')
has_firebase_auth = check_content('pubspec.yaml', r'firebase_auth:', 'Dependency: firebase_auth')

# 2. Check Android Config
check_file_exists('android/app/google-services.json')

# 3. Check Web Config
has_web_meta_tag = check_content('web/index.html', r'google-signin-client_id', 'Web Meta Tag: google-signin-client_id')
check_file_exists('web/favicon.png')

print("\n=== DIAGNOSTIC REPORT ===")
if not has_web_meta_tag:
    print("❌ CRITICAL: Missing Google Client ID in web/index.html")
    print("   Fix: Add <meta name=\"google-signin-client_id\" content=\"YOUR_CLIENT_ID.apps.googleusercontent.com\">")
else:
    print("✅ Web configuration looks active.")

if check_file_exists('android/app/google-services.json'):
    print("✅ Android configuration found (google-services.json).")
else:
    print("❌ CRITICAL: Missing google-services.json for Android.")

print("\nNote: This script checks local files. Ensure 'Authorized Origins' are set in Google Cloud Console.")
