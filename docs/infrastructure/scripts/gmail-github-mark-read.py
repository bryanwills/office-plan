#!/usr/bin/env python3
"""One-time deterministic cleanup: marks unread GitHub notification/digest
emails as read (left in inbox, not trashed), then emails a summary report.
No LLM involved, no Gmail filters/labels created.

Usage:
  gmail-github-mark-read.py --dry-run     (default; only prints/reports what would be marked read)
  gmail-github-mark-read.py --execute     (actually marks read + sends the report email)
"""
import argparse
import base64
import json
from email.mime.text import MIMEText

from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

CRED_PATH = "/home/bryan/.gmail-mcp/credentials.json"
OAUTH_KEYS_PATH = "/home/bryan/.gmail-mcp/gcp-oauth.keys.json"
REPORT_TO = "bryan@bryanwills.dev"

SENDER_DOMAIN = "github.com"


def load_credentials():
    with open(CRED_PATH) as f:
        cred_data = json.load(f)
    with open(OAUTH_KEYS_PATH) as f:
        oauth_keys = json.load(f)["installed"]

    return Credentials(
        token=cred_data["access_token"],
        refresh_token=cred_data.get("refresh_token"),
        token_uri=oauth_keys["token_uri"],
        client_id=oauth_keys["client_id"],
        client_secret=oauth_keys["client_secret"],
        scopes=cred_data.get("scope", "").split(),
    )


def build_query():
    return f"is:unread from:{SENDER_DOMAIN}"


def list_all_matching(service, query):
    ids = []
    page_token = None
    while True:
        resp = (
            service.users()
            .messages()
            .list(userId="me", q=query, pageToken=page_token, maxResults=500)
            .execute()
        )
        ids.extend(m["id"] for m in resp.get("messages", []))
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    return ids


def get_summary_line(service, msg_id):
    msg = (
        service.users()
        .messages()
        .get(userId="me", id=msg_id, format="metadata", metadataHeaders=["From", "Subject", "Date"])
        .execute()
    )
    headers = {h["name"]: h["value"] for h in msg.get("payload", {}).get("headers", [])}
    return f"- {headers.get('Date', '?')} | {headers.get('From', '?')} | {headers.get('Subject', '(no subject)')}"


def batch_mark_read(service, ids):
    for i in range(0, len(ids), 1000):
        chunk = ids[i : i + 1000]
        service.users().messages().batchModify(
            userId="me", body={"ids": chunk, "removeLabelIds": ["UNREAD"]}
        ).execute()


def send_report(service, subject, body_text):
    msg = MIMEText(body_text)
    msg["to"] = REPORT_TO
    msg["subject"] = subject
    raw = base64.urlsafe_b64encode(msg.as_bytes()).decode()
    service.users().messages().send(userId="me", body={"raw": raw}).execute()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--execute", action="store_true", help="Actually mark read + send report (default: dry-run)")
    args = parser.parse_args()

    creds = load_credentials()
    service = build("gmail", "v1", credentials=creds)

    query = build_query()
    print(f"Query: {query}")
    ids = list_all_matching(service, query)
    print(f"Matched {len(ids)} unread message(s).")

    if not ids:
        print("Nothing to do.")
        return

    print("Fetching summaries (first 50 shown)...")
    summaries = []
    for msg_id in ids[:50]:
        summaries.append(get_summary_line(service, msg_id))
    for s in summaries:
        print(s)
    if len(ids) > 50:
        print(f"... and {len(ids) - 50} more (report email will note the total count only for the rest)")

    if not args.execute:
        print("\nDRY RUN — nothing marked. Re-run with --execute to actually mark these read and email a report.")
        return

    print(f"\nMarking {len(ids)} message(s) as read (left in inbox)...")
    batch_mark_read(service, ids)

    report_lines = [
        "Gmail GitHub-notifications cleanup report",
        f"Query: {query}",
        f"Total messages marked as read (left in inbox): {len(ids)}",
        "",
        "Sample (first 50):",
    ] + summaries
    if len(ids) > 50:
        report_lines.append(f"... and {len(ids) - 50} more (not listed individually)")

    send_report(service, f"Gmail cleanup: {len(ids)} GitHub emails marked read", "\n".join(report_lines))
    print(f"Done. Report sent to {REPORT_TO}.")


if __name__ == "__main__":
    main()
