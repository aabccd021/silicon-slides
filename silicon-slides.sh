bg="#000000"
size="1920x1080"
outdir="slides"

max_row=0
max_col=0

input_file="$0"
base_name=$(basename "$input_file")
dir_name=$(dirname "$input_file")

group_name=$(echo "$base_name" | cut -d'-' -f1)

input_files=$(find "$dir_name" -name "$group_name-*.txt" | sort)

for input_file in $input_files; do

  rows=$(wc -l <"$input_file")
  if [ "$rows" -gt "$max_row" ]; then
    max_row=$rows
  fi

  cols=$(wc -L <"$input_file")
  if [ "$cols" -gt "$max_col" ]; then
    max_col=$cols
  fi

done

tmpdir=$(mktemp -d)
for input_file in $input_files; do
  ext=${input_file##*.}

  input_file_padded="$tmpdir/input_file.$ext"

  cp "$input_file" "$input_file_padded"

  last_line=$(tail -n 1 "$input_file_padded")
  last_line_col=${#last_line}
  col_pad_len=$((max_col - last_line_col))
  printf "%-${col_pad_len}s" "" >>"$input_file_padded"

  row_pad=$((max_row - $(wc -l <"$input_file")))

  i=0
  while [ $i -lt $row_pad ]; do
    echo >>"$input_file_padded"
    i=$((i + 1))
  done

  out_path=$(basename "$input_file")
  out_path="$outdir/$out_path.png"

  silicon "$input_file_padded" "--output $tmpdir/tmp1.png --background $bg"

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
