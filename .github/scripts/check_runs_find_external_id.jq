.check_runs[] | walk(
if type == "object" and .external_id != null then
    select(.external_id | test($external_id)) != null
else
    .
end
)
