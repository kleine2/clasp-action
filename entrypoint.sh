#!/bin/sh -l

CLASPRC=$(cat <<-END
    {
        "token": {
            "access_token": "$1",
            "refresh_token": "$3",
            "scope": "https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/drive.file https://www.googleapis.com/auth/service.management https://www.googleapis.com/auth/script.deployments https://www.googleapis.com/auth/logging.read https://www.googleapis.com/auth/script.webapp.deploy https://www.googleapis.com/auth/userinfo.profile openid https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/script.projects https://www.googleapis.com/auth/drive.metadata.readonly",
            "token_type": "Bearer",
            "id_token": "$2"
        },
        "oauth2ClientSettings": {
            "clientId": "$4",
            "clientSecret": "$5",
            "redirectUri": "http://localhost"
        },
        "isLocalCreds": false
    }
END
)

echo $CLASPRC > ~/.clasprc.json

COMMAND="$9"
TITLE="${12}"
PROJECT_ID="$7"

if [ "$COMMAND" = "push" ] || [ "$COMMAND" = "deploy" ]; then
  CLASP="{\n  \"scriptId\": \"$6\""
  if [ -n "$PROJECT_ID" ]; then
    CLASP="$CLASP,\n  \"projectId\": \"$PROJECT_ID\""
  fi
  CLASP="$CLASP\n}"

  if [ -n "$8" ]; then
    if [ -e "$8" ]; then
      cd "$8"
    else
      echo "rootDir is invalid."
      exit 1
    fi
  fi

  printf "%b\n" "$CLASP" > .clasp.json
fi

if [ "$COMMAND" = "push" ]; then
  clasp push -f
elif [ "$COMMAND" = "deploy" ]; then
  if [ -n "$10" ]; then
    clasp push -f

    if [ -n "${11}" ]; then
      clasp deploy --description $10 -i ${11}
    else
      clasp deploy --description $10
    fi
  else
    clasp push -f

    if [ -n "${11}" ]; then
      clasp deploy -i ${11}
    else
      clasp deploy
    fi
  fi
elif [ "$COMMAND" = "create" ]; then
  if [ -z "$TITLE" ]; then
    echo "title is required for create command."
    exit 1
  fi

  if [ -n "$8" ]; then
    CREATE_OUT=$(clasp create-script --type sheets --title "$TITLE" --rootDir "$8" 2>&1)
  else
    CREATE_OUT=$(clasp create-script --type sheets --title "$TITLE" 2>&1)
  fi
  echo "$CREATE_OUT"
  if [ -n "$PROJECT_ID" ]; then
    TARGET_DIR="${8:-.}"
    jq --arg pid "$PROJECT_ID" '. + {projectId: $pid}' "$TARGET_DIR/.clasp.json" > "$TARGET_DIR/.clasp.json.tmp" && mv "$TARGET_DIR/.clasp.json.tmp" "$TARGET_DIR/.clasp.json"
  fi
  SPREADSHEET_URL=$(echo "$CREATE_OUT" | grep -o 'https://drive.google.com[^ ]*')
  SCRIPT_URL=$(echo "$CREATE_OUT" | grep -o 'https://script.google.com[^ ]*')
  if [ -n "$SPREADSHEET_URL" ]; then
    echo "spreadsheet_url=$SPREADSHEET_URL" >> "$GITHUB_OUTPUT"
  fi
  if [ -n "$SCRIPT_URL" ]; then
    echo "script_url=$SCRIPT_URL" >> "$GITHUB_OUTPUT"
  fi
elif [ "$COMMAND" = "create_and_push" ]; then
  if [ -z "$TITLE" ]; then
    echo "title is required for create_and_push command."
    exit 1
  fi

  if [ -n "$8" ]; then
    CREATE_OUT=$(clasp create-script --type sheets --title "$TITLE" --rootDir "$8" 2>&1)
    cd "$8"
  else
    CREATE_OUT=$(clasp create-script --type sheets --title "$TITLE" 2>&1)
  fi
  echo "$CREATE_OUT"
  if [ -n "$PROJECT_ID" ]; then
    jq --arg pid "$PROJECT_ID" '. + {projectId: $pid}' .clasp.json > .clasp.json.tmp && mv .clasp.json.tmp .clasp.json
  fi
  SPREADSHEET_URL=$(echo "$CREATE_OUT" | grep -o 'https://drive.google.com[^ ]*')
  SCRIPT_URL=$(echo "$CREATE_OUT" | grep -o 'https://script.google.com[^ ]*')
  if [ -n "$SPREADSHEET_URL" ]; then
    echo "spreadsheet_url=$SPREADSHEET_URL" >> "$GITHUB_OUTPUT"
  fi
  if [ -n "$SCRIPT_URL" ]; then
    echo "script_url=$SCRIPT_URL" >> "$GITHUB_OUTPUT"
  fi
  clasp push -f
else
  echo "command is invalid."
  exit 1
fi
