#!/bin/bash

# ===============================
# Lab Status Export Script
# ===============================

# Detect Network
NETWORK=$(ip route | grep default | awk '{print $3}' | cut -d. -f1-3)

# Date & Time
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# Folder Path (Phone Storage)
FOLDER="/storage/emulated/0/Lab_Data"

# File Name
FILE="$FOLDER/Lab_Status_$DATE.txt"


# Create Folder If Not Exists
mkdir -p "$FOLDER"


echo "===================================" > "$FILE"
echo "       LAB PC STATUS REPORT        " >> "$FILE"
echo "===================================" >> "$FILE"
echo "Date & Time : $(date)" >> "$FILE"
echo "Network     : $NETWORK.0/24" >> "$FILE"
echo "===================================" >> "$FILE"
echo >> "$FILE"


# -------------------------------
# LIVE PCs (Online Devices)
# -------------------------------
echo ">>> ONLINE / LIVE DEVICES:" >> "$FILE"
echo "----------------------------" >> "$FILE"

nmap -sn $NETWORK.0/24 | \
grep "Nmap scan report" | \
sed 's/Nmap scan report for //' >> "$FILE"

echo >> "$FILE"


# -------------------------------
# READY PCs (SSH Enabled)
# -------------------------------
echo ">>> READY FOR COMMAND (SSH ON):" >> "$FILE"
echo "--------------------------------" >> "$FILE"

nmap -p 22 --open $NETWORK.0/24 | \
grep "Nmap scan report" | \
sed 's/Nmap scan report for //' >> "$FILE"

echo >> "$FILE"


# -------------------------------
# Summary
# -------------------------------
LIVE_COUNT=$(nmap -sn $NETWORK.0/24 | grep "Nmap scan report" | wc -l)
READY_COUNT=$(nmap -p 22 --open $NETWORK.0/24 | grep "Nmap scan report" | wc -l)

echo "===================================" >> "$FILE"
echo "SUMMARY:" >> "$FILE"
echo "Total Online Devices : $LIVE_COUNT" >> "$FILE"
echo "Ready PCs (SSH ON)   : $READY_COUNT" >> "$FILE"
echo "===================================" >> "$FILE"


# -------------------------------
# Display Result
# -------------------------------
echo
echo "Report Saved Successfully!"
echo "Location: $FILE"
echo
