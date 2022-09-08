#!/bin/bash

##### reserved vars #####
# avatar_url                  = https://your-awesome-discord-avatar.jpg
# footer_icon_url             = https://your-awesome-discord-icon-footer.jpg
# jenkins_branch_name         = develop | release | master
# jenkins_job_name            = my-jenkins-job
# jenkins_job_status          = SUCCESS | FAILURE | ABORT
# jenkins_job_number          = 12345
# jenkins_job_url             = https://my-jenkins-engine/job/my-jenkins-job/job/develop/12345/console
# jenkins_notification_type   = approval | report
# jenkins_node_name           = my-jenkins-agent-node
# jenkins_build_duration      = "10 Minutes and counting"
# jenkins_changes             = "- Add feature #1\n- Bug fix #1\n- Improvement #2"
# jenkins_blue_ocean_base_url = https://my-jenkins-engine/blue/organizations/jenkins
#########################

jenkins_job_name="$(echo ${JOB_NAME} | awk -F / '{print $1}')"

if [ "${jenkins_notification_type}" = "approval" ]; then
  color="43775"
  jenkins_job_status="WAITING_FOR_APPROVAL"
  jenkins_job_url="${jenkins_blue_ocean_base_url}/${jenkins_job_name}/detail/${jenkins_branch_name}/${jenkins_job_number}/pipeline"
else
  if [ "${jenkins_job_status}" = "SUCCESS" ]; then
    color="65344"
  else
    color="16711701"
  fi
fi

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
        },
        {
          "name": "Changes",
          "value": "${jenkins_changes}"
        },
        {
          "name": "Build Duration",
          "value": "${jenkins_build_duration}"
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

