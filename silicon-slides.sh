bg=${bg:-"#000000"}
size=${size:-"1920x1080"}
outdir=${outdir:-"$PWD"}
silicon_config=""

while [ $# -gt 0 ]; do
  case "$1" in
  --background)
    bg="$2"
    shift
    ;;
  --size)
    size="$2"
    shift
    ;;
  --outdir)
    outdir="$2"
    shift
    ;;
  --silicon-config)
    silicon_config="$2"
    shift
    ;;
  *)
    break
    ;;
  esac
  shift
done

slides="$1"
if [ -z "$slides" ]; then
  echo "Usage: silicon-slides.sh [options] <slides>"
  echo "Options:"
  echo "  --background <color>  Background color of the slides (default: #000000)"
  echo "  --size <size>         Size of the slides (default: 1920x1080)"
  echo "  --outdir <dir>        Output directory (default: current directory)"
  echo "  --silicon-config <file>  Silicon config file"
  exit 1
fi

if [ -n "$silicon_config" ]; then
  config_path=$(silicon --config-file)
  cp -L "$silicon_config" "$config_path"
fi

max_row=0
max_col=0

while IFS= read -r input_line; do
  input_file=$(echo "$input_line" | awk '{print $1}')

  rows=$(wc -l <"$input_file")
  if [ "$rows" -gt "$max_row" ]; then
    max_row=$rows
  fi

  cols=$(wc -L <"$input_file")
  if [ "$cols" -gt "$max_col" ]; then
    max_col=$cols
  fi

done <"$slides"

tmpdir=$(mktemp -d)
# for input_file in "$@"; do
while IFS= read -r input_line; do
  input_file=$(echo "$input_line" | awk '{print $1}')

  # second column and after are input arguments
  input_args=$(echo "$input_line" | awk '{$1=""; print $0}')

  cp -L "$input_file" "$tmpdir/tmp0.txt"
  chmod 600 "$tmpdir/tmp0.txt"

  last_line=$(tail -n 1 "$tmpdir/tmp0.txt")
  last_line_col=${#last_line}
  col_pad_len=$((max_col - last_line_col))

  head -n -1 "$tmpdir/tmp0.txt" >"$tmpdir/tmp0.txt.tmp"
  mv "$tmpdir/tmp0.txt.tmp" "$tmpdir/tmp0.txt"
  printf "%s%-${col_pad_len}s" "$last_line" "" >>"$tmpdir/tmp0.txt"

  row_pad=$((max_row - $(wc -l <"$input_file")))

  i=0
  while [ $i -le $row_pad ]; do
    echo >>"$tmpdir/tmp0.txt"
    i=$((i + 1))
  done

  out_path=$(basename "$input_file")

  # remove extension
  out_path=${out_path%.*}

  out_path="$outdir/$out_path.png"

  ext=${input_file##*.}
  mv "$tmpdir/tmp0.txt" "$tmpdir/tmp0.$ext"

  # shellcheck disable=SC2086
  silicon "$tmpdir/tmp0.$ext" --output "$tmpdir/tmp1.png" $input_args

  magick "$tmpdir/tmp1.png" \
    -resize "$size^" \
    "$tmpdir/tmp2.png"

  magick "$tmpdir/tmp2.png" \
    -background "$bg" \
    -gravity center \
    -resize "$size" \
    -extent "$size" \
    "$tmpdir/tmp3.png"

  mv "$tmpdir/tmp3.png" "$out_path"
done <"$slides"
