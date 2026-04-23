#!/usr/bin/env bash

REPO_PRIVATE=$(jq -r '.repository.private | tostring' "$GITHUB_EVENT_PATH" 2>/dev/null || echo "")
UPSTREAM="anishathalye/proof-html"
ACTION_REPO="${GITHUB_ACTION_REPOSITORY:-}"
DOCS_URL="https://docs.stepsecurity.io/actions/stepsecurity-maintained-actions"

echo ""
echo -e "\033[1;36mStepSecurity Maintained Action\033[0m"
echo "Secure drop-in replacement for $UPSTREAM"
if [ "$REPO_PRIVATE" = "false" ]; then
  echo -e "\033[32m✓ Free for public repositories\033[0m"
fi
echo -e "\033[36mLearn more:\033[0m $DOCS_URL"
echo ""

if [ "$REPO_PRIVATE" != "false" ]; then
  SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"

  if [ "$SERVER_URL" != "https://github.com" ]; then
    BODY=$(printf '{"action":"%s","ghes_server":"%s"}' "$ACTION_REPO" "$SERVER_URL")
  else
    BODY=$(printf '{"action":"%s"}' "$ACTION_REPO")
  fi

  API_URL="https://agent.api.stepsecurity.io/v1/github/$GITHUB_REPOSITORY/actions/maintained-actions-subscription"

  RESPONSE=$(curl --max-time 3 -s -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$BODY" \
    "$API_URL" -o /dev/null) && CURL_EXIT_CODE=0 || CURL_EXIT_CODE=$?

  if [ $CURL_EXIT_CODE -ne 0 ]; then
    echo "Timeout or API not reachable. Continuing to next step."
  elif [ "$RESPONSE" = "403" ]; then
    echo -e "::error::\033[1;31mThis action requires a StepSecurity subscription for private repositories.\033[0m"
    echo -e "::error::\033[31mLearn how to enable a subscription: $DOCS_URL\033[0m"
    exit 1
  fi
fi

failed=0

check_html="${INPUT_CHECK_HTML:-true}"
if [[ "$check_html" =~ ^t.*|^T.*|^y.*|^Y.*|^1.* ]]; then
  check_css="${INPUT_CHECK_CSS:-true}"
  check_css_arg=""
  if [[ "$check_css" =~ ^t.*|^T.*|^y.*|^Y.*|^1.* ]]; then
      check_css_arg="--also-check-css"
  fi
  if ! java -jar /bin/vnu.jar --errors-only --filterpattern "${INPUT_VALIDATOR_IGNORE}" --skip-non-html ${check_css_arg} "${INPUT_DIRECTORY}"; then
    failed=1
  fi
fi

tries="${INPUT_RETRIES:-3}"

while [ "$tries" -ge 1 ]; do
  tries=$((tries-1))
  if RUBYOPT="-W0" ruby /proof-html.rb; then
    break
  fi
  if [ "$tries" -ge 1 ]; then
    sleep 5
  fi
  if [ "$tries" -eq 0 ]; then
    failed=1
  fi
done

exit $failed
