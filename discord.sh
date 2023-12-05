#!/bin/bash

CHANGES_ADDED=$(git log --grep="Added:" --pretty="- %s" "$CI_COMMIT_BEFORE_SHA..$CI_COMMIT_SHA")
CHANGES_FIXED=$(git log --grep="Fixed:" --pretty="- %s" "$CI_COMMIT_BEFORE_SHA..$CI_COMMIT_SHA")
CHANGES_CHANGED=$(git log --grep="Changed:" --pretty="- %s" "$CI_COMMIT_BEFORE_SHA..$CI_COMMIT_SHA")

CHANGELOG="Added:\n$CHANGES_ADDED\n\nFixed:\n$CHANGES_FIXED\n\nChanged:\n$CHANGES_CHANGED"

if [ "$1" = "success" ] ; then
    EMBED_COLOR='9096238'
    STATUS_MESSAGE='Success'
    COMMIT_SUBJECT='New Build'
    COMMIT_MESSAGE="A new version of the build is available for download\n\n$CHANGELOG"
    ARTIFACT_URL="$CI_JOB_URL/artifacts/download"
    FIELDS='
    "fields": [
    {
        "name": "Download",
        "value": "'"[\`$CI_COMMIT_SHORT_SHA\`]($ARTIFACT_URL)"'",
        "inline": true
    }
    ],'
else
    EMBED_COLOR='15158332'
    STATUS_MESSAGE='Failed'
    COMMIT_SUBJECT='Build Problem'
    ERROR_MESSAGE=$(git log -1 --pretty=%B "$CI_COMMIT_SHA" | sed -n '1!p')
    COMMIT_MESSAGE="Oops, looks like there was a problem during the build:\n\n$ERROR_MESSAGE"
    FIELDS=''
fi

shift

TIMESTAMP=$(date --utc +%FT%TZ)

WEBHOOK_DATA='{
"avatar_url": "https://gitlab.com/favicon.png",
"embeds": [ {
    "color": '"$EMBED_COLOR"',
    "author": {
    "name": "Pipeline #'"$CI_PIPELINE_IID"' '"$STATUS_MESSAGE"' - '"$CI_PROJECT_PATH_SLUG"'",
    "url": "'"$CI_PIPELINE_URL"'",
    "icon_url": "https://gitlab.com/favicon.png"
    },
    "title": "'"$COMMIT_SUBJECT"'",
    "description": "'"$COMMIT_MESSAGE"'",
    '"$FIELDS"'
    "timestamp": "'"$TIMESTAMP"'"
    } ]
}'

for ARG in "$@"; do
  echo -e "[Webhook]: Sending webhook to Discord...\\n";

  (curl --fail --progress-bar -A "GitLabCI-Webhook" -H Content-Type:application/json -H X-Author:k3rn31p4nic#8383 -d "$WEBHOOK_DATA" "$ARG" \
  && echo -e "\\n[Webhook]: Successfully sent the webhook.") || echo -e "\\n[Webhook]: Unable to send webhook."
done
