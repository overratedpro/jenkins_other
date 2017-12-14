#!/bin/bash -uef

#
# plugin to monitor AWS cloud health
# requirements:
# 1) packages:
#   - Debian/Ubuntu: apt install -y awscli jq
#   - RHEL/Centos (via EPEL): yum install -y awscli jq
# 2) aws config and credentials setup in ~/.aws
#

read -d '' JQ_TRANSFORMATION <<- 'EOF' || :
map(.InstanceStatuses) |
add |
map( select(
    ( .SystemStatus.Status | test("^ok$") | not ) or
    ( .InstanceStatus.Status | test("^ok$") | not )
)? ) |
map({"key": .AvailabilityZone, "value": .InstanceId}) |
group_by(.key) |
map({(.[0].key): (map(.value) | join(", "))})
EOF

AWS_INSTANCE_STATUS="$( aws ec2 describe-regions --output json |\
    jq --compact-output '.Regions | .[] | .RegionName' |\
    xargs -r -n1 -- aws ec2 describe-instance-status --output json --region |\
    jq --slurp --compact-output --monochrome-output \
        --from-file <(echo "${JQ_TRANSFORMATION}") )"

if [ $(echo "${AWS_INSTANCE_STATUS}" | jq --raw-output 'length') -gt 0 ]; then
    echo 'EC2 instance checks failed: '"${AWS_INSTANCE_STATUS}"
    exit 2
else
    echo 'EC2 instance checks OK'
    exit 0
fi
