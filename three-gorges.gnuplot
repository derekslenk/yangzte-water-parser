#!/usr/bin/env gnuplot
UTC_OFFSET=8

set terminal pdfcairo size 12cm,8cm enhanced font 'DejaVu Sans,10'
set datafile separator " "
set timefmt "%s"

stats "csv/three-gorges.csv" using (column("timestamp")) name "timestamp" nooutput
set xdata time

set xlabel "Local time in Yichang (UTC+8)"
set format x "%d/%m %H:%M"
set xtics rotate by 45 right

set y2tics

set ylabel "Water level (meters)"
set y2label "Flow (m^3/s)"

set title "Three Gorges Reservoir"
set key bottom center horizontal outside
set label "3gd.slenk.com" at screen 0.81, screen 0.085 textcolor "#770000"

# set yrange [135:181]

set output "graphs/three-gorges.pdf"
plot "csv/three-gorges.csv" using (column("timestamp")+UTC_OFFSET*3600):"level" title 'Current level' with lines axes x1y1 lc rgb '#0000aa' lw 3, \
     "csv/three-gorges.csv" using (column("timestamp")+UTC_OFFSET*3600):"outflow" title 'Outflow' with lines axes x1y2 lc rgb '#aa0000' lw 2, \
     "csv/three-gorges.csv" using (column("timestamp")+UTC_OFFSET*3600):(column("inflow") == 0 ? NaN : column("inflow")) title 'Inflow' axes x1y2 with points ls 7 lc rgb '#007700'
#     "three-gorges.csv" using (column("timestamp")+UTC_OFFSET*3600):(140) title "Summer pool" axes x1y1 with lines, \
#     "three-gorges.csv" using (column("timestamp")+UTC_OFFSET*3600):(175) title "Winter pool" axes x1y1 with lines

set xrange [timestamp_max-3*86400+UTC_OFFSET*3600:timestamp_max+UTC_OFFSET*3600]
set output "graphs/three-gorges-3d.pdf"
replot

set xrange [timestamp_max-86400+UTC_OFFSET*3600:timestamp_max+UTC_OFFSET*3600]
set output "graphs/three-gorges-24h.pdf"
replot
