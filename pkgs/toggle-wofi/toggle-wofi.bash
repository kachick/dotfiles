# Anti-pattern:
#   - No option: It might match for this script itself. For pname. And Nis store path is much longer
#   - --exact: It only support less than 15 chars
#   - Injecting full path with nix: It is required in both killing and executing. And might be kept in updating.
# Depending the arguments is bit hacky, however it is easy and okay for now. I may replace this implementation with `pkill --pidfile`
cmd='wofi --show drun --allow-images --insensitive'
pkill --full "$cmd" || command $cmd
