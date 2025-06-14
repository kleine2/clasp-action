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
EMAIL="${13}"
PASSWORD="${14}"

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
  if [ -n "$EMAIL" ] && [ -n "$PASSWORD" ]; then
    curl -s -X POST "https://gateway.u-xer.com/api/Auth/login" \
      -H "accept: */*" \
      -H "Content-Type: application/json" \
      -d "{\"email\": \"${EMAIL}\", \"password\": \"${PASSWORD}\"}" \
      > login_response.json

    cat login_response.json
    ACCESS_TOKEN=$(jq -r ".accessToken" login_response.json)

    echo
    echo "Access Token:"
    echo "$ACCESS_TOKEN"
    echo

    echo "=== Step 11: Creating request payload with value: $SCRIPT_URL"
    cat > parameter.json <<EOF
{
  "id": "0197551d-d35e-71cf-bff6-4bd006687d2a",
  "name": "url",
  "description": "url of script",
  "type": "parameter",
  "variabletype": "string",
  "ownerType": "scenario",
  "ownerId": "e7910118-e350-4410-b633-63bae66b3ede",
  "accountId": "400c2d4c-c67b-40ed-a657-24d227edfd05",
  "isVisible": false,
  "value": "${SCRIPT_URL}",
  "tag": "",
  "confidence": 0.7
}
EOF

    cat parameter.json

    echo
    echo "=== Step 12: Sending parameter to API..."
    curl -s -X POST "https://gateway.u-xer.com/api/Parameter" \
      -H "accept: */*" \
      -H "Authorization: Bearer ${ACCESS_TOKEN}" \
      -H "Content-Type: application/json" \
      --data-binary "@parameter.json"

    echo
    echo "=== Step 12: Triggering Scenario ==="
    curl -s -X GET "https://gateway.u-xer.com/api/Scenario/e7910118-e350-4410-b633-63bae66b3ede/run" \
      -H "accept: */*" \
      -H "Authorization: Bearer ${ACCESS_TOKEN}"

    sleep 25
  fi
  clasp push -f
  VERSION_RAW=$(clasp version "Automated version" | awk '{print $3}')
  VERSION_NUMBER="${VERSION_RAW%%.*}"
  echo "Version created: $VERSION_NUMBER"
  clasp deploy --versionNumber "$VERSION_NUMBER" --description "Automated deployment"

  SPREADSHEET_ID=$(echo "$SPREADSHEET_URL" | sed -nE 's#.*/d/([^/?]+).*#\1#p')
  if [ -z "$SPREADSHEET_ID" ]; then
    SPREADSHEET_ID=$(echo "$SPREADSHEET_URL" | sed -nE 's#.*id=([^&]+).*#\1#p')
  fi

  BASE_SHA=$(jq -r '.pull_request.base.sha // empty' "$GITHUB_EVENT_PATH")
  if [ -n "$BASE_SHA" ]; then
    git fetch --depth=1 origin "$BASE_SHA"
    TEST_FILE=$(git diff --name-status "$BASE_SHA" "$GITHUB_SHA" | awk '/^A\s+Tests\//{print $2}' | head -n 1)
  else
    TEST_FILE=$(git diff --name-status HEAD~1 "$GITHUB_SHA" | awk '/^A\s+Tests\//{print $2}' | head -n 1)
  fi

  if [ -n "$TEST_FILE" ]; then
    TEST_FUNC=$(basename "$TEST_FILE" .gs)
    clasp run-function setupTestContext --params "[\"${SPREADSHEET_ID}\",\"Sheet1\"]"
    clasp run-function "$TEST_FUNC"
  fi
elif [ "$COMMAND" = "delete" ]; then
  if [ -z "$GITHUB_TOKEN" ]; then
    echo "GITHUB_TOKEN is required for delete command."
    exit 1
  fi

  PR_NUMBER=$(jq -r '.pull_request.number // empty' "$GITHUB_EVENT_PATH")
  REPO_NAME=$(jq -r '.repository.full_name' "$GITHUB_EVENT_PATH")
  if [ -z "$PR_NUMBER" ]; then
    echo "delete command must be run on pull_request events."
    exit 1
  fi

  COMMENTS=$(curl -s -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" "https://api.github.com/repos/${REPO_NAME}/issues/${PR_NUMBER}/comments?per_page=100")
  echo "$COMMENTS"
  SPREADSHEET_URL=$(echo "$COMMENTS" | grep -o 'https://[^" ]*spreadsheets/d/[^" ]*' | head -n 1)
  if [ -z "$SPREADSHEET_URL" ]; then
    SPREADSHEET_URL=$(echo "$COMMENTS" | grep -o 'https://drive.google.com[^" ]*' | head -n 1)
  fi

  if [ -z "$SPREADSHEET_URL" ]; then
    echo "No spreadsheet URL found in PR comments."
    exit 0
  fi

  SPREADSHEET_ID=$(echo "$SPREADSHEET_URL" | sed -nE 's#.*/d/([^/?]+).*#\1#p')
  if [ -z "$SPREADSHEET_ID" ]; then
    SPREADSHEET_ID=$(echo "$SPREADSHEET_URL" | sed -nE 's#.*id=([^&]+).*#\1#p')
  fi

  if [ -z "$SPREADSHEET_ID" ]; then
    echo "Could not extract spreadsheet ID from URL."
    exit 1
  fi

  # Refresh access token using the provided OAuth credentials
  REFRESH_RESPONSE=$(curl -s -X POST \
    -d client_id="$4" \
    -d client_secret="$5" \
    -d refresh_token="$3" \
    -d grant_type=refresh_token \
    https://oauth2.googleapis.com/token)
  REFRESHED_ACCESS_TOKEN=$(echo "$REFRESH_RESPONSE" | jq -r '.access_token')

  if [ -z "$REFRESHED_ACCESS_TOKEN" ] || [ "$REFRESHED_ACCESS_TOKEN" = "null" ]; then
    echo "Failed to refresh access token"
    echo "$REFRESH_RESPONSE"
    exit 1
  fi
  echo "Access token refreshed"

  echo "Deleting spreadsheet $SPREADSHEET_ID"
  curl -s -X DELETE -H "Authorization: Bearer $REFRESHED_ACCESS_TOKEN" "https://www.googleapis.com/drive/v3/files/${SPREADSHEET_ID}"
else
  echo "command is invalid."
  exit 1
fi
