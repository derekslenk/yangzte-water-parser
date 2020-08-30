#!/usr/bin/env gnuplot
UTC_OFFSET=8

set terminal pdfcairo size 12cm,8cm enhanced font 'DejaVu Sans,10'
set datafile separator " "
set timefmt "%s"

stats "csv/cuntan.csv" using (column("timestamp")) name "timestamp" nooutput
set xdata time

set xlabel "Local time in Cuntan (UTC+8)"
set format x "%d/%m %H:%M"
set xtics rotate by 45 right

set y2tics

set ylabel "Water level (meters)"
set y2label "Flow (m^3/s)"

set title "Cuntan (Chongqing)"
set key bottom center horizontal outside
set label "3gd.slenk.com" at screen 0.8, screen 0.025 textcolor "#770000"

set output "graphs/cuntan.pdf"
plot "csv/cuntan.csv" using (column("timestamp")+UTC_OFFSET*3600):"level" title 'Current level' with lines axes x1y1 lc rgb '#0000aa' lw 3, \
     "csv/cuntan.csv" using (column("timestamp")+UTC_OFFSET*3600):"inflow" title 'Flow (Cuntan)' with lines axes x1y2 lc rgb '#aa0000' lw 2, \
     "csv/wulong.csv" using (column("timestamp")+UTC_OFFSET*3600):"wulong_inflow" title 'Flow (Wulong)' with lines axes x1y2 lc rgb '#00aa00' lw 2, \
     "csv/cuntan-wulong.csv" using (column("timestamp")+UTC_OFFSET*3600):(column("inflow")+column("wulong_inflow")) title 'Combined flow' with lines axes x1y2 lc rgb '#aaaa00' lw 2

set xrange [timestamp_max-3*86400+UTC_OFFSET*3600:timestamp_max+UTC_OFFSET*3600]
set output "graphs/cuntan-3d.pdf"
replot

set xrange [timestamp_max-86400+UTC_OFFSET*3600:timestamp_max+UTC_OFFSET*3600]
set output "graphs/cuntan-24h.pdf"
replot
