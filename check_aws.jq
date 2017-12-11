map(.InstanceStatuses) |
add |
map( select(
    ( .SystemStatus.Status | test("^ok$") | not ) or
    ( .InstanceStatus.Status | test("^ok$") | not )
)? ) |
map({"key": .AvailabilityZone, "value": .InstanceId}) |
group_by(.key) |
map({(.[0].key): (map(.value) | join(", "))})
