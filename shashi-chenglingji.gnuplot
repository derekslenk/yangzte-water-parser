#!/usr/bin/env gnuplot
UTC_OFFSET=8

set terminal pdfcairo size 12cm,8cm enhanced font 'DejaVu Sans,10'
set datafile separator " "
set timefmt "%s"

stats "csv/shashi-chenglingji.csv" using (column("timestamp")) name "timestamp" nooutput
set xdata time

set xlabel "Local time in Yichang (UTC+8)"
set format x "%d/%m %H:%M"
set xtics rotate by 45 right

set ylabel "Flow (m^3/s)"

set title "Shashi / Chenglingji"
set key bottom center horizontal outside
set label "3gd.mooo.com" at screen 0.81, screen 0.085 textcolor "#770000"

set output "graphs/shashi-chenglingji.pdf"
plot "csv/shashi-chenglingji.csv" using (column("timestamp")+UTC_OFFSET*3600):(column("shashi_inflow") == 0 ? NaN : column("shashi_inflow")) title 'Flow (Shashi)' with lines lc rgb '#aa0000' lw 2, \
     "csv/shashi-chenglingji.csv" using (column("timestamp")+UTC_OFFSET*3600):(column("chenglingji_inflow") == 0 ? NaN : column("chenglingji_inflow")) title 'Flow (Chenglingji)' with lines lc rgb '#00aa00' lw 2, \
     "csv/shashi-chenglingji.csv" using (column("timestamp")+UTC_OFFSET*3600):((column("shashi_inflow") == 0 ? NaN : column("shashi_inflow")) + (column("chenglingji_inflow") == 0 ? NaN : column("chenglingji_inflow"))) title 'Combined flow' with lines lc rgb '#aaaa00' lw 2

set xrange [timestamp_max-3*86400+UTC_OFFSET*3600:timestamp_max+UTC_OFFSET*3600]
set output "graphs/shashi-chenglingji-3d.pdf"
replot

set xrange [timestamp_max-86400+UTC_OFFSET*3600:timestamp_max+UTC_OFFSET*3600]
set output "graphs/shashi-chenglingji-24h.pdf"
replot
