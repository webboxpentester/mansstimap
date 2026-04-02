Run this script by copying, pasting, and hitting Enter in your terminal. (required)

echo "" && echo "" echo -n "Which environment are you on? (1=Termux / 2=Linux) Type (1/2): " && read choice && if [ "$choice" -eq 1 ]; then sed -i 's|#for_settings_up 10101010|#!/data/data/com.termux/files/usr/bin/bash|' sstimap.sh && echo "Updated for Termux in sstimap.sh"; elif [ "$choice" -eq 2 ]; then sed -i 's|#for_settings_up 10101010|#!/bin/bash|' sstimap.sh && echo "Updated for Linux in sstimap.sh"; else echo "Invalid choice. Please run again and type 1 or 2."; fi
