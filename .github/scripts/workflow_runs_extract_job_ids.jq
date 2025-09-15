[.jobs[] | walk(
if type == "object" and .name != null then
    select(.name | test($job_name))
else
    .
end
).id]
