#!/bash/sh

awk -F';' '
BEGIN { OFS=";" }

NR==1 {
  print $1,$2,$4,$5,$3,$8,$7
  next
}

tolower($1)!="n/a" &&
tolower($3)!="n/a" &&
$1!="" &&
$3!="" &&
length($1)==12 &&
length($3)==12 {

  key=$1 "|" $3

  if (!seen[key]++) {
    print $1,$2,$4,$5,$3,$8,$7
  }
}
' staging_tickers.csv > tickers.csv