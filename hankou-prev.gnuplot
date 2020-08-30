#!/usr/bin/env gnuplot
UTC_OFFSET=8

set terminal pdfcairo size 12cm,8cm enhanced font 'DejaVu Sans,10'
set datafile separator " "
set output "graphs/hankou-prev.pdf"
set timefmt "%s"

set xdata time

set xlabel "Local time in Hankou (UTC+8)"
set format x "%d/%m %H:%M"
set xtics rotate by 45 right

set y2tics

set ylabel "Water level (meters)"
set y2label "Flow (m^3/s)"

set title "Hankou"
set key right center
set label "3gd.mooo.com" at screen 0.8, screen 0.025 textcolor "#770000"

plot "csv/hankou-prev.csv" using (column("timestamp")+UTC_OFFSET*3600):"level" title 'Current level' with lines axes x1y1 lc rgb '#0000aa' lw 3, \
     "csv/hankou-prev.csv" using (column("timestamp")+UTC_OFFSET*3600):"inflow" title 'Flow' with lines axes x1y2 lc rgb '#aa0000' lw 2
