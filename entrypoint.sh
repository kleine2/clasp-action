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

COMMAND="$8"
TITLE="${11}"

if [ "$COMMAND" = "push" ] || [ "$COMMAND" = "deploy" ]; then
  CLASP=$(cat <<-END
    {
        "scriptId": "$6"
    }
END
  )

  if [ -n "$7" ]; then
    if [ -e "$7" ]; then
      cd "$7"
    else
      echo "rootDir is invalid."
      exit 1
    fi
  fi

  echo $CLASP > .clasp.json
fi

if [ "$COMMAND" = "push" ]; then
  clasp push -f
elif [ "$COMMAND" = "deploy" ]; then
  if [ -n "$9" ]; then
    clasp push -f

    if [ -n "${10}" ]; then
      clasp deploy --description $9 -i ${10}
    else
      clasp deploy --description $9
    fi
  else
    clasp push -f

    if [ -n "${10}" ]; then
      clasp deploy -i ${10}
    else
      clasp deploy
    fi
  fi
elif [ "$COMMAND" = "create" ]; then
  if [ -z "$TITLE" ]; then
    echo "title is required for create command."
    exit 1
  fi

  if [ -n "$7" ]; then
    CREATE_OUT=$(clasp create-script --type sheets --title "$TITLE" --rootDir "$7" 2>&1)
  else
    CREATE_OUT=$(clasp create-script --type sheets --title "$TITLE" 2>&1)
  fi
  echo "$CREATE_OUT"
  SPREADSHEET_URL=$(echo "$CREATE_OUT" | grep -o 'https://drive.google.com[^ ]*')
  SCRIPT_URL=$(echo "$CREATE_OUT" | grep -o 'https://script.google.com[^ ]*')
  if [ -n "$SPREADSHEET_URL" ]; then
    echo "spreadsheet_url=$SPREADSHEET_URL" >> "$GITHUB_OUTPUT"
  fi
  if [ -n "$SCRIPT_URL" ]; then
    echo "script_url=$SCRIPT_URL" >> "$GITHUB_OUTPUT"
  fi
else
  echo "command is invalid."
  exit 1
fi
