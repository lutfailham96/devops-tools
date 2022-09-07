#!/bin/bash

date_time="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"

json_data=$(cat <<EOF
{
  "username": "DevOps Bot",
  "avatar_url": "${avatar_url}",
  "embeds": [
    {
      "title": "${jenkins_job_name}",
      "color": "${color}",
      "fields": [
        {
          "name": "Build Status",
          "value": "${jenkins_job_status}"
        },
        {
          "name": "Build Number",
          "value": "#${jenkins_job_number}"
        },
        {
          "name": "Jenkins Job URL",
          "value": "[Jenkins Playcourt](${jenkins_job_url})"
        }
      ],
      "footer": {
        "icon_url": "${footer_icon_url}",
        "text": "Generated from ${jenkins_node_name}"
      },
      "timestamp": "${date_time}"
    }
  ]
}
EOF
)

send_notification() {
  json_data="${1}"
  curl \
      -H "Content-Type: application/json" \
      -d "${json_data}" \
      "${discord_webhook_url}"
}

send_notification "${json_data}"

