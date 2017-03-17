#!/usr/bin/env bash
NOTEID=$(curl -X POST -H "Content-Type:application/json" https://bulletnotes.io/notes/inbox --digest -s -d "{\"title\":\"$1\",\"body\":\"$2\",\"userId\":\"WuQ2ha7E4BRbERWyh\"}")
echo "Note saved! Title: $1 Body: $2";
echo "View note: https://bulletnotes.io/note/$NOTEID"
