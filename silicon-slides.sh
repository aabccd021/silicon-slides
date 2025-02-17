bg="#000000"
size="1920x1080"
outdir="slides"

max_row=0
max_col=0

input_file="$0"
base_name=$(basename "$input_file")
dir_name=$(dirname "$input_file")

group_name=$(echo "$base_name" | cut -d'-' -f1)

group_files=$(find "$dir_name" -name "$group_name-*.txt")

for group_file in $group_files; do

  rows=$(wc -l <"$group_file")
  if [ "$rows" -gt "$max_row" ]; then
    max_row=$rows
  fi

  cols=$(wc -L <"$group_file")
  if [ "$cols" -gt "$max_col" ]; then
    max_col=$cols
  fi

done

tmpdir=$(mktemp -d)
for group_file in $group_files; do
  ext=${group_file##*.}

  group_file_padded="$tmpdir/group_file.$ext"

  cp "$group_file" "$group_file_padded"

  last_line=$(tail -n 1 "$group_file_padded")
  last_line_col=${#last_line}
  col_pad_len=$((max_col - last_line_col))
  printf "%-${col_pad_len}s" "" >>"$group_file_padded"

  row_pad=$((max_row - $(wc -l <"$group_file")))

  i=0
  while [ $i -lt $row_pad ]; do
    echo >>"$group_file_padded"
    i=$((i + 1))
  done

  out_path=$(basename "$group_file")
  out_path="$outdir/$out_path.png"

  silicon "$group_file_padded" "--output $tmpdir/tmp1.png --background $bg"

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
