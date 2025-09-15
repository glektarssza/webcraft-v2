.jobs[] | walk(
if type == "object" then
    select(.name | test($job_name))
else
    .
end
).id
