#!/usr/bin/env -S uv run

# /// script
# dependencies = [
#   "rich",
# ]
# [tool.uv]
# exclude-newer = "2025-03-07T00:00:00Z"
# ///

import ssl
import socket
import datetime
import subprocess
import sys
from datetime import datetime
from rich.console import Console
from rich.table import Table
from rich import box

# Configuration variables
CRITICAL_THRESHOLD = 14
WARNING_THRESHOLD = 21

# Status emojis and descriptions
OK_EMOJI = "✅"
WARNING_EMOJI = "⚠️"
CRITICAL_EMOJI = "🔴"
EXPIRED_EMOJI = "🚫"
ERROR_EMOJI = "❌"

# Sites to check
import os
# Get sites from environment variable if set, otherwise use defaults
SITES = os.environ.get('SITES', '').split(',') if os.environ.get('SITES') else []
SITES = [site.strip() for site in SITES if site.strip()]  # Clean up any empty entries

# Exit with error if no sites are provided
if not SITES:
    print("Error: No sites provided. Please set the SITES environment variable.")
    sys.exit(1)

def check_certificate(site):
    """Check the SSL certificate for a site and return certificate details"""
    print(f"Checking certificate for: {site}")

    try:
        # Use subprocess to call openssl to get more reliable certificate information
        cmd = f"echo | openssl s_client -servername {site} -connect {site}:443 2>/dev/null | openssl x509 -noout -enddate"
        result = subprocess.run(cmd, shell=True, text=True, capture_output=True)

        if result.returncode != 0:
            raise Exception(f"Error running openssl: {result.stderr}")

        # Extract end date
        end_date_str = result.stdout.strip().split('=')[1]
        end_date = datetime.strptime(end_date_str, "%b %d %H:%M:%S %Y %Z")

        # Calculate days remaining
        current_date = datetime.now()
        days_remaining = (end_date - current_date).days

        # Determine status
        status = "ok"
        status_emoji = OK_EMOJI
        style = "green"

        if days_remaining <= 0:
            status = "expired"
            status_emoji = EXPIRED_EMOJI
            style = "red bold"
            has_near_expiry_ssl = True
        elif days_remaining <= CRITICAL_THRESHOLD:
            status = "critical"
            status_emoji = CRITICAL_EMOJI
            style = "red"
            has_near_expiry_ssl = True
        elif days_remaining <= WARNING_THRESHOLD:
            status = "warning"
            status_emoji = WARNING_EMOJI
            style = "yellow"
            has_near_expiry_ssl = True
        else:
            has_near_expiry_ssl = False

        return {
            "site": site,
            "expiry_date": end_date_str,
            "days_remaining": days_remaining,
            "status": status,
            "status_emoji": status_emoji,
            "style": style,
            "has_near_expiry_ssl": has_near_expiry_ssl
        }

    except Exception as e:
        print(f"Error checking certificate for {site}: {str(e)}")
        return {
            "site": site,
            "expiry_date": "ERROR",
            "days_remaining": -1,
            "status": "error",
            "status_emoji": ERROR_EMOJI,
            "style": "red bold",
            "has_near_expiry_ssl": True
        }

def main():
    # Initialize Rich console with explicit width
    console = Console(width=120)  # Set a reasonable fixed width for CI environments

    # Check all sites
    results = []
    has_any_near_expiry_ssl = False

    for site in SITES:
        cert_info = check_certificate(site)
        results.append(cert_info)
        if cert_info["has_near_expiry_ssl"]:
            has_any_near_expiry_ssl = True

    # Sort results by days remaining
    sorted_results = sorted(results, key=lambda x: x["days_remaining"])

    # Create a table using rich
    table = Table(title="SSL CERTIFICATE EXPIRY REPORT", box=box.DOUBLE_EDGE)

    # Add columns with adjusted widths
    table.add_column("DOMAIN", style="cyan", no_wrap=True, min_width=30)
    table.add_column("EXPIRY DATE", no_wrap=True, min_width=24)
    table.add_column("DAYS", justify="right", no_wrap=True, min_width=8)
    table.add_column("STATUS", no_wrap=True, min_width=14)

    # Add rows
    for cert in sorted_results:
        table.add_row(
            cert["site"],
            cert["expiry_date"],
            str(cert["days_remaining"]),
            f"{cert['status_emoji']} {cert['status']}",
            style=cert["style"]
        )

    # Print legend
    console.print()
    console.print(f"Status Legend: {OK_EMOJI} OK   {WARNING_EMOJI} Warning (<{WARNING_THRESHOLD} days)   "
                 f"{CRITICAL_EMOJI} Critical (<{CRITICAL_THRESHOLD} days)   {EXPIRED_EMOJI} Expired")
    console.print()

    # Print the table
    console.print(table)

    # Check for critical certificates
    critical_certs = [cert for cert in sorted_results if cert["days_remaining"] <= WARNING_THRESHOLD or cert["status"] == "error"]

    # Print summary for critical certificates
    if critical_certs:
        console.print()
        console.print("⚠️ ATTENTION REQUIRED ⚠️", style="bold yellow")
        console.print("The following certificates need attention:")

        for cert in critical_certs:
            console.print(f"{cert['status_emoji']} https://{cert['site']} - {cert['status'].upper()} - {cert['days_remaining']} days remaining",
                         style=cert["style"])

        # Exit with error if any certificates are expiring soon
        if has_any_near_expiry_ssl:
            console.print()
            console.print("WARNING: One or more sites have SSL certificates expiring soon or errors.", style="bold red")
            sys.exit(1)
    else:
        console.print()
        console.print(f"✅ ALL CERTIFICATES ARE VALID FOR MORE THAN {WARNING_THRESHOLD} DAYS", style="bold green")

    sys.exit(0)

if __name__ == "__main__":
    main()
