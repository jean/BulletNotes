#!/usr/bin/env bash
NOTEID=$(curl -X POST -H "Content-Type:application/json" https://bulletnotes.io/note/inbox --digest -s -d "{\"title\":\"$1\",\"body\":\"$2\",\"apiKey\":\"API_KEY_HERE\"}")
echo "Note saved! Title: $1 Body: $2";
echo "View note: https://bulletnotes.io/note/$NOTEID"
