#!/usr/bin/gnuplot -persist
#
#    
#    	G N U P L O T
#    	Version 5.4 patchlevel 3    last modified 2021-12-24 
#    
#    	Copyright (C) 1986-1993, 1998, 2004, 2007-2021
#    	Thomas Williams, Colin Kelley and many others
#    
#    	gnuplot home:     http://www.gnuplot.info
#    	faq, bugs, etc:   type "help FAQ"
#    	immediate help:   type "help"  (plot window: hit 'h')
# set terminal wxt 0 size 2427, 1500 enhanced
# set output
unset clip points
set clip one
unset clip two
unset clip radial
set errorbars front 2.000000
set border 31 front lt black linewidth 1.000 dashtype solid
set zdata 
set ydata 
set xdata 
set y2data 
set x2data 
set boxwidth 0.9 absolute
set boxdepth 0
set style fill   solid 1.00 border lt -1
set style rectangle back fc  bgnd fillstyle   solid 1.00 border lt -1
set style circle radius graph 0.02 
set style ellipse size graph 0.05, 0.03 angle 0 units xy
set dummy x, y
set format x "% h" 
set format y "% h" 
set format x2 "% h" 
set format y2 "% h" 
set format z "% h" 
set format cb "% h" 
set format r "% h" 
set ttics format "% h"
set timefmt "%d/%m/%y,%H:%M"
set angles radians
set tics back
set grid nopolar
set grid noxtics nomxtics ytics nomytics noztics nomztics nortics nomrtics \
 nox2tics nomx2tics noy2tics nomy2tics nocbtics nomcbtics
set grid layerdefault   linecolor rgb "#737373"  linewidth 2.000 dashtype solid,  lt 0 linecolor 0 linewidth 0.500 dashtype solid
unset raxis
set theta counterclockwise right
set style parallel front  lt black linewidth 2.000 dashtype solid
set key title "" center
set key fixed right top vertical Left reverse enhanced autotitle nobox
set key noinvert samplen 4 spacing 1 width 0 height 0 
set key maxcolumns 0 maxrows 0
set key noopaque
unset label
unset arrow
set style increment userstyles
unset style line
set style line 1  linecolor rgb "#737373"  linewidth 2.000 dashtype solid pointtype 6 pointsize default
set style line 2  linecolor rgb "#e41a1c"  linewidth 2.000 dashtype solid pointtype 4 pointsize default
set style line 3  linecolor rgb "grey40"  linewidth 2.000 dashtype solid pointtype 8 pointsize default
set style line 4  linecolor rgb "#4daf4a"  linewidth 2.000 dashtype solid pointtype 10 pointsize default
set style line 5  linecolor rgb "#984ea3"  linewidth 2.000 dashtype solid pointtype 12 pointsize default
set style line 6  linecolor rgb "#ff7f00"  linewidth 2.000 dashtype solid pointtype 14 pointsize default
set style line 7  linecolor rgb "#a65628"  linewidth 2.000 dashtype solid pointtype 7 pointsize default
set style line 8  linecolor rgb "#f781bf"  linewidth 2.000 dashtype solid pointtype 5 pointsize default
set style line 9  linecolor rgb "#e6ab02"  linewidth 2.000 dashtype solid pointtype 9 pointsize default
set style line 10  linecolor rgb "#7570b3"  linewidth 2.000 dashtype solid pointtype 11 pointsize default
set style line 11  linecolor rgb "#a6761d"  linewidth 2.000 dashtype solid pointtype 13 pointsize default
set style line 20  linecolor rgb "#af272f"  linewidth 2.000 dashtype solid pointtype 6 pointsize default
set style line 21  linecolor rgb "#ee2737"  linewidth 2.000 dashtype solid pointtype 4 pointsize default
set style line 22  linecolor rgb "#006d68"  linewidth 2.000 dashtype solid pointtype 8 pointsize default
set style line 23  linecolor rgb "#00857d"  linewidth 2.000 dashtype solid pointtype 10 pointsize default
set style line 24  linecolor rgb "#006298"  linewidth 2.000 dashtype solid pointtype 12 pointsize default
set style line 25  linecolor rgb "#298fc2"  linewidth 2.000 dashtype solid pointtype 14 pointsize default
set style line 26  linecolor rgb "#563d82"  linewidth 2.000 dashtype solid pointtype 7 pointsize default
set style line 27  linecolor rgb "#6f5091"  linewidth 2.000 dashtype solid pointtype 5 pointsize default
set style line 28  linecolor rgb "#e35205"  linewidth 2.000 dashtype solid pointtype 9 pointsize default
set style line 29  linecolor rgb "#ff7f41"  linewidth 2.000 dashtype solid pointtype 11 pointsize default
set style line 30  linecolor rgb "#89813d"  linewidth 2.000 dashtype solid pointtype 13 pointsize default
set style line 31  linecolor rgb "#afa96e"  linewidth 2.000 dashtype solid pointtype 15 pointsize default
set style line 32  linecolor rgb "#7c878e"  linewidth 2.000 dashtype solid pointtype 14 pointsize default
set style line 33  linecolor rgb "#c1c6c8"  linewidth 2.000 dashtype solid pointtype 16 pointsize default
unset style arrow
set style histogram errorbars gap 2 lw 2 title textcolor lt -1 font "Times Bold, 24" boxed offset character 0, 1
unset object
unset walls
set style textbox  transparent margins  1.0,  1.0 border  lt -1 linewidth  1.0
set offsets 0, 0, 0, 0
set pointsize 1
set pointintervalbox 1
set encoding default
unset polar
unset parametric
unset spiderplot
unset decimalsign
unset micro
unset minussign
set view 60, 30, 1, 1
set view azimuth 0
set rgbmax 255
set samples 500, 500
set isosamples 10, 10
set surface 
unset contour
set cntrlabel  format '%8.3g' font '' start 5 interval 20
set mapping cartesian
set datafile separator whitespace
set datafile nocolumnheaders
unset hidden3d
set cntrparam order 4
set cntrparam linear
set cntrparam levels 5
set cntrparam levels auto
set cntrparam firstlinetype 0 unsorted
set cntrparam points 5
set size ratio 0 1,1
set origin 0,0
set style data histograms
set style function lines
unset xzeroaxis
unset yzeroaxis
unset zzeroaxis
unset x2zeroaxis
unset y2zeroaxis
set xyplane relative 0.5
set tics scale  1, 0.5, 1, 1, 1
set mxtics default
set mytics default
set mztics default
set mx2tics default
set my2tics default
set mcbtics default
set mrtics default
set nomttics
set xtics border in scale 1,0.5 nomirror rotate by -45  autojustify
set xtics  norangelimit  font ", 28"
set xtics   ()
set ytics border in scale 1,0.5 mirror norotate  autojustify
set ytics  norangelimit autofreq  font ", 28"
set ztics border in scale 1,0.5 nomirror norotate  autojustify
set ztics  norangelimit autofreq 
unset x2tics
unset y2tics
set cbtics border in scale 1,0.5 mirror norotate  autojustify
set cbtics  norangelimit autofreq 
set rtics axis in scale 1,0.5 nomirror norotate  autojustify
set rtics  norangelimit autofreq 
unset ttics
set title "CGNS serial, Jelly^{ntimes=10}" 
set title  font ", 36" textcolor lt -1 norotate
set timestamp bottom 
set timestamp "" 
set timestamp  font "" textcolor lt -1 norotate
set trange [ * : * ] noreverse nowriteback
set urange [ * : * ] noreverse nowriteback
set vrange [ * : * ] noreverse nowriteback
set xlabel "HDF5 version" 
set xlabel  offset character 0, -3, 0 font "Times Bold,36" textcolor lt -1 norotate
set x2label "" 
set x2label  font "" textcolor lt -1 norotate
set xrange [ * : * ] noreverse writeback
set x2range [ * : * ] noreverse writeback
set ylabel "Time CGNS \"make check\", Serial (seconds)" 
set ylabel  offset character -3, 0, 0 font "Times Bold,36" textcolor lt -1 rotate
set y2label "" 
set y2label  font "" textcolor lt -1 rotate
set yrange [ 0.00000 : * ] noreverse writeback
set y2range [ * : * ] noreverse writeback
set zlabel "" 
set zlabel  font "" textcolor lt -1 norotate
set zrange [ * : * ] noreverse writeback
set cblabel "" 
set cblabel  font "" textcolor lt -1 rotate
set cbrange [ * : * ] noreverse writeback
set rlabel "" 
set rlabel  font "" textcolor lt -1 norotate
set rrange [ * : * ] noreverse writeback
unset logscale
unset jitter
set zero 1e-08
set lmargin  13
set bmargin  10
set rmargin  -1
set tmargin  -1
set locale "en_US.UTF-8"
set pm3d explicit at s
set pm3d scansautomatic
set pm3d interpolate 1,1 flush begin noftriangles noborder corners2color mean
set pm3d clip z 
set pm3d nolighting
set palette positive nops_allcF maxcolors 0 gamma 1.5 color model RGB 
set palette rgbformulae 7, 5, 15
set colorbox default
set colorbox vertical origin screen 0.9, 0.2 size screen 0.05, 0.6 front  noinvert bdefault
set style boxplot candles range  1.50 outliers pt 7 separation 1 labels auto unsorted
set loadpath 
set fontpath
set psdir
set fit brief errorvariables nocovariancevariables errorscaling prescale nowrap v5
GNUTERM = "qt"
I = {0.0, 1.0}
VoxelDistance = 0.0
date = strftime("%Y-%m-%d", time(0))

set grid y lt 1

filename = "cgns-timings.2022.07.29-16.50.01"
## Last datafile plotted: "cgns-timings.2022.07.29-16.50.01"
plot newhistogram "1.8" tc rgb "#003f5c" font "Times Bold,28", \
filename i 0 using 2:3:4:xtic(1) noti lt 3 linecolor rgb "#003f5c",newhistogram "1.10" tc rgb "#58508d" font "Times Bold,28",'' i 1 using 2:3:4:xtic(1) noti lt 3 linecolor rgb "#58508d",newhistogram "1.12" tc rgb "#bc5090" font "Times Bold,28", '' i 2 using 2:3:4:xtic(1) noti lt 3 linecolor rgb "#bc5090",newhistogram "1.13" tc rgb "#ff6361" font "Times Bold,28", '' i 3 using 2:3:4:xtic(1) noti lt 3 linecolor rgb "#ff6361",newhistogram date tc rgb "#ffa600" font "Times Bold,28", '' i 4 using 2:3:4:xtic(1) noti lt 3 linecolor rgb "#ffa600"
#    EOF
