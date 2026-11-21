# https://brush.sh/how-tos/configuration/#brushrc

# - We can't simply use $BRUSH_VERSION for this purpose because of it is a shell variable.
#   Starship can only handle environment variables in env_var module.
# - Remember remaining this even if you run bash/zsh on brush. SHLVL helps it.
# - Don't set built-in $STARSHIP_SHELL variable, remaining on bash should be reasonable for now
export STARSHIP_BRUSH_INDICATOR='brush'
