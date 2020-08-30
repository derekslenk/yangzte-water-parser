#!/bin/bash
export timestamp=`printf "$(date '+%s')"`
wget -O out/levels-$timestamp.html http://www.cjh.com.cn/sqindex.html

printf "Searching for 3GD\n"
echo "timestamp outflow inflow risedrop level" > csv/three-gorges.csv
cat out/*.html | grep "var sssq =" | cut -d "=" -f 2 | cut -d ";" -f 1 | \
    jq -r '(map(select(.stnm=="三峡水库"))[]) | "\(.tm/1000) \(.oq) \(.q) \(.wptn) \(.z)"' | \
    sort | uniq >> csv/three-gorges.csv

printf "Searching for cuntan\n"
echo "timestamp outflow inflow risedrop level" > csv/cuntan.csv
cat out/*.html | grep "var sssq =" | cut -d "=" -f 2 | cut -d ";" -f 1 | \
    jq -r '(map(select(.stnm=="寸滩"))[]) | "\(.tm/1000) \(.oq) \(.q) \(.wptn) \(.z)"' | \
    sort | uniq >> csv/cuntan.csv

printf "Searching for hankou\n"
echo "timestamp outflow inflow risedrop level" > csv/hankou.csv
cat out/*.html | grep "var sssq =" | cut -d "=" -f 2 | cut -d ";" -f 1 | \
    jq -r '(map(select(.stnm=="汉口"))[]) | "\(.tm/1000) \(.oq) \(.q) \(.wptn) \(.z)"' | \
    sort | uniq | \
    egrep -v "^1595113260 0 2330 6 42.57$" >> csv/hankou.csv

printf "Searching for hankou-prev\n"
echo "timestamp outflow inflow risedrop level" > csv/hankou-prev.csv
cat out/*.html | grep "var sssq =" | cut -d "=" -f 2 | cut -d ";" -f 1 | \
    jq -r '(map(select(.stnm=="汉口"))[]) | "\(.tm/1000) \(.oq) \(.q) \(.wptn) \(.z)"' | \
    sort | uniq >> csv/hankou-prev.csv

printf "Searching for Yichang\n"
echo "timestamp outflow inflow risedrop level" > csv/yichang.csv
cat out/*.html | grep "var sssq =" | cut -d "=" -f 2 | cut -d ";" -f 1 | \
    jq -r '(map(select(.stnm=="宜昌"))[]) | "\(.tm/1000) \(.oq) \(.q) \(.wptn) \(.z)"' | \
    sort | uniq >> csv/yichang.csv

printf "Searching for Wulong\n"
echo "timestamp wulong_outflow wulong_inflow wulong_risedrop wulong_level" > csv/wulong.csv
cat out/*.html | grep "var sssq =" | cut -d "=" -f 2 | cut -d ";" -f 1 | \
    jq -r '(map(select(.stnm=="武隆"))[]) | "\(.tm/1000) \(.oq) \(.q) \(.wptn) \(.z)"' | \
    sort | uniq >> csv/wulong.csv

printf "Searching for Shashi\n"
echo "timestamp shashi_outflow shashi_inflow shashi_risedrop shashi_level" > csv/shashi.csv
cat out/*.html | grep "var sssq =" | cut -d "=" -f 2 | cut -d ";" -f 1 | \
    jq -r '(map(select(.stnm=="沙市"))[]) | "\(.tm/1000) \(.oq) \(.q) \(.wptn) \(.z)"' | \
    sort | uniq >> csv/shashi.csv

printf "Searching for Chengliji\n"
echo "timestamp chenglingji_outflow chenglingji_inflow chenglingji_risedrop chenglingji_level" > csv/chenglingji.csv
cat out/*.html | grep "var sssq =" | cut -d "=" -f 2 | cut -d ";" -f 1 | \
    jq -r '(map(select(.stnm=="城陵矶(七)"))[]) | "\(.tm/1000) \(.oq) \(.q) \(.wptn) \(.z)"' | \
    sort | uniq >> csv/chenglingji.csv

printf "Joining cuntan and wulong\n"
join csv/cuntan.csv csv/wulong.csv > csv/cuntan-wulong.csv
printf "Joining shashi and chenglinji\n"
join csv/shashi.csv csv/chenglingji.csv > csv/shashi-chenglingji.csv

rm -rf graphs

mkdir graphs

printf "3GD graphs\n"
./three-gorges.gnuplot
printf "Cuntan graphs\n"
./cuntan.gnuplot
./hankou.gnuplot
./hankou-prev.gnuplot
./yichang.gnuplot
./shashi-chenglingji.gnuplot

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

INFLOW=`tail -n 1 levels.txt | awk '{ print $2 }'`

TGD=`tail -n 1 csv/three-gorges.csv | awk  '{print $5}'`
CUNTAN=`tail -n 1 csv/cuntan-wulong.csv | awk  '{print $5}'`
YICHANG=`tail -n 1 csv/yichang.csv | awk  '{print $5}'`
HANKOU=`tail -n 1 csv/hankou.csv | awk '{print $5}'`

TGDOUTFLOW=`tail -n 1 csv/three-gorges.csv | awk  '{print $2}'`
TGDINFLOW=`tail -n 1 csv/three-gorges.csv | awk '{ if ($3==0) print "-"; else print $3 }'`

if [ $TGDINFLOW = "-" ]
then
    TGDINFLOW=$INFLOW
fi   

printf "_CURRENT WATER LEVELS_\n" > levels.txt
printf "Chongqing: %s\n" $CUNTAN >> levels.txt
printf "Three Gorges Dam: %s\n" $TGD >> levels.txt
printf "Yichang: %s\n" $YICHANG >> levels.txt
printf "Hankou/Wuhan: %s\n" $HANKOU >> levels.txt

printf "_CURRENT FLOW RATES_\n" >> levels.txt
printf "Outflow: %s m^3/s\n" $TGDOUTFLOW >> levels.txt
printf "Inflow: %s m^3/s\n" $TGDINFLOW >> levels.txt

# aws s3 cp levels.txt s3://3gd.slenk.com
# aws s3 cp csv/ s3://3gd.slenk.com/csv --recursive
