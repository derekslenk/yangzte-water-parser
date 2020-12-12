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

#printf "Joining cuntan and wulong\n"
join csv/cuntan.csv csv/wulong.csv > csv/cuntan-wulong.csv
#printf "Joining shashi and chenglinji\n"
#join csv/shashi.csv csv/chenglingji.csv > csv/shashi-chenglingji.csv

rm -rf graphs

mkdir graphs


./three-gorges.gnuplot &
#./cuntan.gnuplot &
#./hankou.gnuplot &
#./hankou-prev.gnuplot &
./yichang.gnuplot &
#./shashi-chenglingji.gnuplot &

wait

ALL="three-gorges three-gorges-3d three-gorges-24h yichang yichang-3d yichang-24h"

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

for fn in $ALL; do
    cp graphs/$fn.png /mnt/obs/tgd/graphs &
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
rm index.html && touch index.html
printf "<html><body>" > index.html

printf "CURRENT WATER LEVELS\n" | tee -a levels.txt index.html

printf "<br/>" >> index.html

if echo $CUNTAN $PREVCUNTAN | awk '{exit !( $1 > $2)}'; then
    printf "Chongqing: %s ↑\n" $CUNTAN | tee -a  levels.txt index.html
elif echo $CUNTAN $PREVCUNTAN | awk '{exit !( $1 < $2)}'; then
    printf "Chongqing: %s ↓\n" $CUNTAN | tee -a  levels.txt index.html
else
    printf "Chongqing: %s ‒\n" $CUNTAN | tee -a  levels.txt index.html
fi

printf "<br/>" >> index.html

if echo $TGD $PREVTGD | awk '{exit !( $1 > $2)}'; then
    printf "Three Gorges Dam: %s ↑\n" $TGD | tee -a levels.txt index.html
elif echo $TGD $PREVTGD | awk '{exit !( $1 < $2)}'; then
    printf "Three Gorges Dam: %s ↓\n" $TGD | tee -a  levels.txt index.html
else
    printf "Three Gorges Dam: %s ‒\n" $TGD | tee -a  levels.txt index.html
fi

printf "<br/>" >> index.html

if echo $YICHANG $PREVYICHANG | awk '{exit !( $1 > $2)}'; then
    printf "Yichang: %s ↑\n" $YICHANG | tee -a  levels.txt index.html
elif echo $YICHANG $PREVYICHANG | awk '{exit !( $1 < $2)}'; then
    printf "Yichang: %s ↓\n" $YICHANG | tee -a  levels.txt index.html
else
    printf "Yichang: %s ‒\n" $YICHANG | tee -a  levels.txt index.html
fi

printf "<br/>" >> index.html

if echo $HANKOU $PREVHANKOU | awk '{exit !( $1 > $2)}'; then
    printf "Hankou/Wuhan: %s ↑\n" $HANKOU | tee -a  levels.txt index.html
elif echo $HANKOU $PREVHANKOU | awk '{exit !( $1 < $2)}'; then
    printf "Hankou/Wuhan: %s ↓\n" $HANKOU | tee -a  levels.txt index.html
else
    printf "Hankou/Wuhan: %s ‒\n" $HANKOU | tee -a  levels.txt index.html
fi

printf "<br/>" >> index.html
printf "<br/>" >> index.html

printf "\nCURRENT FLOW RATES\n" | tee -a  levels.txt index.html

printf "<br/>" >> index.html

printf "Prev outflow is: %s\n" $OUTFLOW
printf "New outflow is: %s\n" $NEWOUTFLOW


if (( $NEWOUTFLOW > $OUTFLOW )); then
    printf "Outflow: %s m³/s ↑\n" $NEWOUTFLOW | tee -a levels.txt index.html
elif (( $NEWOUTFLOW < $OUTFLOW )); then
    printf "Outflow: %s m³/s ↓\n" $NEWOUTFLOW | tee -a  levels.txt index.html
else
    printf "Outflow: %s m³/s ‒\n" $NEWOUTFLOW | tee -a  levels.txt index.html
fi

printf "<br/>" >> index.html

printf "Prev inflow is: %s\n" $PREVINFLOW

printf "New inflow is: %s\n" $NEWINFLOW

if (( $NEWINFLOW > $PREVINFLOW )); then
    printf "Inflow: %s m³/s ↑\n" $NEWINFLOW | tee -a  levels.txt index.html
elif (( $NEWINFLOW < $PREVINFLOW )); then
    printf "Inflow: %s m³/s ↓\n" $NEWINFLOW | tee -a  levels.txt index.html
else
    printf "Inflow: %s m³/s ‒\n" $NEWINFLOW | tee -a  levels.txt index.html
fi

printf "<br/>" >> index.html
printf "<br/>" >> index.html

cp  levels.txt /mnt/obs/tgd/levels.txt
printf "taking a break for the weekend. stay safe." >> index.html
printf "<br/>" >> index.html
printf "&nbsp; -derek" >> index.html
printf "</body></html>" >> index.html

sed -i 's/↑/(up)/g' index.html
sed -i 's/↓/(down)/g' index.html
sed -i 's/‒/(no change)/g' index.html
sed -i 's/³/^3/g' index.html

aws s3 cp index.html s3://3gd.slenk.com/index.html
# aws s3 cp csv/ s3://3gd.slenk.com/csv --recursive
