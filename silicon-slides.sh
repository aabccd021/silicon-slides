bg="#000000"
size="1920x1080"
outdir="slides"

max_rows=0
max_cols=0

for input_file in "$@"; do

  rows=$(wc -l <"$input_file")
  if [ "$rows" -gt "$max_rows" ]; then
    max_rows=$rows
  fi

  cols=$(wc -L <"$input_file")
  if [ "$cols" -gt "$max_cols" ]; then
    max_cols=$cols
  fi

done

line=$(printf "%-${max_cols}s" "")

for input_file in "$@"; do
  ext=${input_file##*.}

  tmp0="tmp.$ext"

  echo "$line" >"$tmp0"

  line_pad=$((max_rows - $(wc -l <"$input_file")))

  cat "$input_file" ">>$tmp0"

  i=0
  while [ $i -lt $line_pad ]; do
    echo >>"$tmp0"
    i=$((i + 1))
  done

  echo >>"$tmp0"

  out_path=$(basename "$input_file")
  out_path=${out_path#*-}
  out_path="$outdir/$out_path.png"

  args="--output $tmpdir/tmp1.png --background $bg"

  tmpdir=$(mktemp -d)

  silicon "$tmp0" "$args"

  convert "$tmpdir/tmp1.png" \
    -resize "$size^" \
    "$tmpdir/tmp2.png"

  convert "$tmpdir/tmp2.png" \
    -background "$bg" \
    -gravity center \
    -resize $size \
    -extent $size \
    "$tmpdir/tmp3.png"

  mv "$tmpdir/tmp3.png" "$out_path"
done
