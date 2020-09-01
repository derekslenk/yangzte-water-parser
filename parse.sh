#!/bin/bash
export timestamp=`printf "$(date '+%F-%H%M%S-%s')"`
printf "Timestamp is %s\n" $timestamp
wget -O out/$timestamp.html http://www.cjh.com.cn/sqindex.html

#Empty out all the CSVs. I am sure there is a better way to do this
echo "timestamp outflow inflow risedrop level" > csv/three-gorges.csv
echo "timestamp outflow inflow risedrop level" > csv/cuntan.csv
echo "timestamp outflow inflow risedrop level" > csv/hankou.csv
echo "timestamp outflow inflow risedrop level" > csv/hankou-prev.csv
echo "timestamp outflow inflow risedrop level" > csv/yichang.csv
echo "timestamp wulong_outflow wulong_inflow wulong_risedrop wulong_level" > csv/wulong.csv
echo "timestamp shashi_outflow shashi_inflow shashi_risedrop shashi_level" > csv/shashi.csv
echo "timestamp chenglingji_outflow chenglingji_inflow chenglingji_risedrop chenglingji_level" > csv/chenglingji.csv

#Launch the json parsin threads as separate processes as to not be linear
cat out/*.html | grep "var sssq =" | cut -d "=" -f 2 | cut -d ";" -f 1 | \
    jq -r '(map(select(.stnm=="三峡水库"))[]) | "\(.tm/1000) \(.oq) \(.q) \(.wptn) \(.z)"' | \
    sort | uniq >> csv/three-gorges.csv &

cat out/*.html | grep "var sssq =" | cut -d "=" -f 2 | cut -d ";" -f 1 | \
    jq -r '(map(select(.stnm=="寸滩"))[]) | "\(.tm/1000) \(.oq) \(.q) \(.wptn) \(.z)"' | \
    sort | uniq >> csv/cuntan.csv &

cat out/*.html | grep "var sssq =" | cut -d "=" -f 2 | cut -d ";" -f 1 | \
    jq -r '(map(select(.stnm=="汉口"))[]) | "\(.tm/1000) \(.oq) \(.q) \(.wptn) \(.z)"' | \
    sort | uniq | \
    egrep -v "^1595113260 0 2330 6 42.57$" >> csv/hankou.csv &

cat out/*.html | grep "var sssq =" | cut -d "=" -f 2 | cut -d ";" -f 1 | \
    jq -r '(map(select(.stnm=="汉口"))[]) | "\(.tm/1000) \(.oq) \(.q) \(.wptn) \(.z)"' | \
    sort | uniq >> csv/hankou-prev.csv &

cat out/*.html | grep "var sssq =" | cut -d "=" -f 2 | cut -d ";" -f 1 | \
    jq -r '(map(select(.stnm=="宜昌"))[]) | "\(.tm/1000) \(.oq) \(.q) \(.wptn) \(.z)"' | \
    sort | uniq >> csv/yichang.csv &

cat out/*.html | grep "var sssq =" | cut -d "=" -f 2 | cut -d ";" -f 1 | \
    jq -r '(map(select(.stnm=="武隆"))[]) | "\(.tm/1000) \(.oq) \(.q) \(.wptn) \(.z)"' | \
    sort | uniq >> csv/wulong.csv &

cat out/*.html | grep "var sssq =" | cut -d "=" -f 2 | cut -d ";" -f 1 | \
    jq -r '(map(select(.stnm=="沙市"))[]) | "\(.tm/1000) \(.oq) \(.q) \(.wptn) \(.z)"' | \
    sort | uniq >> csv/shashi.csv &

cat out/*.html | grep "var sssq =" | cut -d "=" -f 2 | cut -d ";" -f 1 | \
    jq -r '(map(select(.stnm=="城陵矶(七)"))[]) | "\(.tm/1000) \(.oq) \(.q) \(.wptn) \(.z)"' | \
    sort | uniq >> csv/chenglingji.csv &

wait #Wait for the above to finish

printf "Joining cuntan and wulong\n"
join csv/cuntan.csv csv/wulong.csv > csv/cuntan-wulong.csv
printf "Joining shashi and chenglinji\n"
join csv/shashi.csv csv/chenglingji.csv > csv/shashi-chenglingji.csv

rm -rf graphs

mkdir graphs


./three-gorges.gnuplot &
./cuntan.gnuplot &
./hankou.gnuplot &
./hankou-prev.gnuplot &
./yichang.gnuplot &
./shashi-chenglingji.gnuplot &

wait

ALL="three-gorges three-gorges-3d three-gorges-24h cuntan cuntan-3d cuntan-24h hankou hankou-3d hankou-24h hankou-prev yichang yichang-3d yichang-24h shashi-chenglingji shashi-chenglingji-3d shashi-chenglingji-24h"

for fn in $ALL; do
    printf "pdftocairo for %s\n" $fn
    pdftocairo -png graphs/$fn.pdf -singlefile -scale-to 1600 graphs/$fn-upsample &
done

wait

for fn in $ALL; do
    convert graphs/$fn-upsample.png -filter Lanczos -distort Resize 50% graphs/$fn.png &
done

wait

for fn in $ALL; do
    advpng -4 -z graphs/$fn.png &
done

wait

# Previous inflow value
CURINFLOW=`tail -n 1 levels.txt | awk '{ print $2 }'`
PREVINFLOW=`cat csv/three-gorges.csv | cut -d ' ' -f3 | grep -v "^0$" | tail -n 2 | head -n 1`

#Previous outflow value
OUTFLOW=`tail -n 2 levels.txt | head -n 1 | awk '{ print $2}'`

PREVTGD=`tail -n 2 csv/three-gorges.csv | awk  '{print $5}' | head -n 1`
TGD=`tail -n 1 csv/three-gorges.csv | awk  '{print $5}'`

PREVCUNTAN=`tail -n 2 csv/cuntan-wulong.csv | awk  '{print $5}' | head -n 1`
CUNTAN=`tail -n 1 csv/cuntan-wulong.csv | awk  '{print $5}'`

PREVYICHANG=`tail -n 2 csv/yichang.csv | awk  '{print $5}' | head -n 1`
YICHANG=`tail -n 1 csv/yichang.csv | awk  '{print $5}'`

PREVHANKOU=`tail -n 2 csv/hankou.csv | awk  '{print $5}' | head -n 1`
HANKOU=`tail -n 1 csv/hankou.csv | awk '{print $5}'`

NEWOUTFLOW=`tail -n 1 csv/three-gorges.csv | awk  '{print $2}'`
NEWINFLOW=`tail -n 1 csv/three-gorges.csv | awk '{ if ($3==0) print "-"; else print $3 }'`

if [ $NEWINFLOW = "-" ]
then
    NEWINFLOW=$CURINFLOW
fi   

#Thanks https://stackoverflow.com/questions/11237794/how-to-compare-two-decimal-numbers-in-bash-awk

printf "CURRENT WATER LEVELS\n" > levels.txt

if echo $CUNTAN $PREVCUNTAN | awk '{exit !( $1 > $2)}'; then
    printf "Chongqing: %s ↑\n" $CUNTAN >> levels.txt
elif echo $CUNTAN $PREVCUNTAN | awk '{exit !( $1 < $2)}'; then
    printf "Chongqing: %s ↓\n" $CUNTAN >> levels.txt
else
    printf "CHongqing: %s -\n" $CUNTAN >> levels.txt
fi

if echo $TGD $PREVTGD | awk '{exit !( $1 > $2)}'; then
    printf "Three Gorges Dam: %s ↑\n" $TGD >> levels.txt
elif echo $TGD $PREVTGD | awk '{exit !( $1 < $2)}'; then
    printf "Three Gorges Dam: %s ↓\n" $TGD >> levels.txt
else
    printf "Three Gorges Dam: %s -\n" $TGD >> levels.txt
fi

if echo $YICHANG $PREVYICHANG | awk '{exit !( $1 > $2)}'; then
    printf "Yichang: %s ↑\n" $YICHANG >> levels.txt
elif echo $YICHANG $PREVYICHANG | awk '{exit !( $1 < $2)}'; then
    printf "Yichang: %s ↓\n" $YICHANG >> levels.txt
else
    printf "Yichang: %s -\n" $YICHANG >> levels.txt
fi

if echo $HANKOU $PREVHANKOU | awk '{exit !( $1 > $2)}'; then
    printf "Hankou/Wuhan: %s ↑\n" $HANKOU >> levels.txt
elif echo $HANKOU $PREVHANKOU | awk '{exit !( $1 < $2)}'; then
    printf "Hankou/Wuhan: %s ↓\n" $HANKOU >> levels.txt
else
    printf "Hankou/Wuhan: %s -\n" $HANKOU >> levels.txt
fi

printf "\nCURRENT FLOW RATES\n" >> levels.txt

printf "Prev outflow is: %s\n" $OUTFLOW
printf "New outflow is: %s\n" $NEWOUTFLOW
if (( $NEWOUTFLOW > $OUTFLOW )); then
    printf "Outflow: %s m³/s ↑\n" $NEWOUTFLOW >> levels.txt
elif (( $NEWOUTFLOW < $OUTFLOW )); then
    printf "Outflow: %s m³/s ↓\n" $NEWOUTFLOW >> levels.txt
else
    printf "Outflow: %s m³/s -\n" $NEWOUTFLOW >> levels.txt
fi

printf "Prev inflow is: %s\n" $PREVINFLOW
printf "New inflow is: %s\n" $NEWINFLOW
if (( $NEWINFLOW > $PREVINFLOW )); then
    printf "Inflow: %s m³/s ↑\n" $NEWINFLOW >> levels.txt
elif (( $NEWINFLOW < $PREVINFLOW )); then
    printf "Inflow: %s m³/s ↓\n" $NEWINFLOW >> levels.txt
else
    printf "Inflow: %s m³/s -\n" $NEWINFLOW >> levels.txt
fi

aws s3 cp levels.txt s3://3gd.slenk.com/index.html
# aws s3 cp csv/ s3://3gd.slenk.com/csv --recursive
