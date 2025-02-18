flags=""
while [ "$#" -gt 1 ]; do
  flags="$flags $1"
  shift
done

slides="$1"

export XDG_CONFIG_HOME="$PWD/config"
export SILICON_CACHE_PATH="$PWD/silicone-cache"

converted_slides=$(mktemp)
while IFS= read -r line; do
  filename=$(echo "$line" | awk '{print $1}')
  args=$(echo "$line" | awk '{$1=""; print $0}')

  # remove nix store hash
  normalized=$(echo "$filename" | xargs basename | sed 's/^[^-]*-//')

  cp -Lv "$filename" "$normalized"
  echo "$normalized $args" >>"$converted_slides"
done <"$slides"

# shellcheck disable=SC2086
silicon-slides $flags "$converted_slides"
