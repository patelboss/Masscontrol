#!/bin/bash

# ===============================
# Lab Status Export Script
# (Android Termux Compatible)
# ===============================


# Get WiFi IP from Android
MYIP=$(termux-wifi-connectioninfo 2>/dev/null | grep '"ip"' | cut -d'"' -f4)

# Check IP
if [ -z "$MYIP" ]; then
  echo "ERROR: Not connected to WiFi or Termux API not installed."
  exit 1
fi


# Extract Network
NETWORK=$(echo "$MYIP" | cut -d. -f1-3)


# Date & Time
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# Folder
FOLDER="/sdcard/Lab_Data"

# File
FILE="$FOLDER/Lab_Status_$DATE.txt"


# Create folder
mkdir -p "$FOLDER"


# Header
echo "===================================" > "$FILE"
echo "       LAB PC STATUS REPORT        " >> "$FILE"
echo "===================================" >> "$FILE"
echo "===================================" >> "$FILE"
echo "Date & Time : $(date)" >> "$FILE"
echo "Phone IP    : $MYIP" >> "$FILE"
echo "Network     : $NETWORK.0/24" >> "$FILE"
echo "===================================" >> "$FILE"
echo >> "$FILE"


# -------------------------------
# LIVE PCs
# -------------------------------
echo ">>> ONLINE / LIVE DEVICES:" >> "$FILE"
echo "----------------------------" >> "$FILE"

nmap -sn "$NETWORK.0/24" | \
grep "Nmap scan report" | \
sed 's/Nmap scan report for //' >> "$FILE"

echo >> "$FILE"


# -------------------------------
# READY PCs
# -------------------------------
echo ">>> READY FOR COMMAND (SSH ON):" >> "$FILE"
echo "--------------------------------" >> "$FILE"

nmap -p 22 --open "$NETWORK.0/24" | \
grep "Nmap scan report" | \
sed 's/Nmap scan report for //' >> "$FILE"

echo >> "$FILE"


# -------------------------------
# Summary
# -------------------------------
LIVE_COUNT=$(nmap -sn "$NETWORK.0/24" | grep "Nmap scan report" | wc -l)
READY_COUNT=$(nmap -p 22 --open "$NETWORK.0/24" | grep "Nmap scan report" | wc -l)

echo "===================================" >> "$FILE"
echo "SUMMARY:" >> "$FILE"
echo "Total Online Devices : $LIVE_COUNT" >> "$FILE"
echo "Ready PCs (SSH ON)   : $READY_COUNT" >> "$FILE"
echo "===================================" >> "$FILE"


echo
echo "Report Saved:"
echo "$FILE"
echo
