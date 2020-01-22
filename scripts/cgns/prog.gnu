#!/sw/bin/gnuplot -persist
#
#    
#    	G N U P L O T
#    	Version 5.0 patchlevel 3    last modified 2016-02-21 
#    
#    	Copyright (C) 1986-1993, 1998, 2004, 2007-2016
#    	Thomas Williams, Colin Kelley and many others
#    
#    	gnuplot home:     http://www.gnuplot.info
#    	faq, bugs, etc:   type "help FAQ"
#    	immediate help:   type "help"  (plot window: hit 'h')
# set terminal wxt 0 enhanced
# set output
unset clip points
set clip one
unset clip two
set bar 1.000000 front
set border 31 front lt black linewidth 1.000 dashtype solid
set zdata 
set ydata 
set xdata 
set y2data 
set x2data 
set boxwidth 0.9 absolute
set style fill   solid 1.00 border lt -1
set style rectangle back fc  bgnd fillstyle   solid 1.00 border lt -1
set style circle radius graph 0.02, first 0.00000, 0.00000 
set style ellipse size graph 0.05, 0.03, first 0.00000 angle 0 units xy
set dummy x, y
set format x "% h" 
set format y "% h" 
set format x2 "% h" 
set format y2 "% h" 
set format z "% h" 
set format cb "% h" 
set format r "% h" 
set timefmt "%d/%m/%y,%H:%M"
set angles radians
set tics back
set grid nopolar
set grid noxtics nomxtics ytics nomytics noztics nomztics \
 nox2tics nomx2tics noy2tics nomy2tics nocbtics nomcbtics
set grid layerdefault   lt 0 linewidth 1.00,  lt 0 linewidth 0.500
set raxis
set style parallel front  lt black linewidth 2.000 dashtype solid
set key title "" center
set key inside right top vertical Right noreverse enhanced autotitle nobox
set key noinvert samplen 4 spacing 1 width 0 height 0 
set key maxcolumns 0 maxrows 0
set key noopaque
unset label
unset arrow
set style increment userstyles
unset style line
set style line 1  linecolor rgb "grey40"  linewidth 2.000 dashtype solid pointtype 6 pointsize default pointinterval 0
set style line 2  linecolor rgb "#e41a1c"  linewidth 2.000 dashtype solid pointtype 4 pointsize default pointinterval 0
set style line 3  linecolor rgb "#377eb8"  linewidth 2.000 dashtype solid pointtype 8 pointsize default pointinterval 0
set style line 4  linecolor rgb "#4daf4a"  linewidth 2.000 dashtype solid pointtype 10 pointsize default pointinterval 0
set style line 5  linecolor rgb "#984ea3"  linewidth 2.000 dashtype solid pointtype 12 pointsize default pointinterval 0
set style line 6  linecolor rgb "#ff7f00"  linewidth 2.000 dashtype solid pointtype 14 pointsize default pointinterval 0
set style line 7  linecolor rgb "#a65628"  linewidth 2.000 dashtype solid pointtype 7 pointsize default pointinterval 0
set style line 8  linecolor rgb "#f781bf"  linewidth 2.000 dashtype solid pointtype 5 pointsize default pointinterval 0
set style line 9  linecolor rgb "#e6ab02"  linewidth 2.000 dashtype solid pointtype 9 pointsize default pointinterval 0
set style line 10  linecolor rgb "#7570b3"  linewidth 2.000 dashtype solid pointtype 11 pointsize default pointinterval 0
set style line 11  linecolor rgb "#a6761d"  linewidth 2.000 dashtype solid pointtype 13 pointsize default pointinterval 0
set style line 20  linecolor rgb "#af272f"  linewidth 2.000 dashtype solid pointtype 6 pointsize default pointinterval 0
set style line 21  linecolor rgb "#ee2737"  linewidth 2.000 dashtype solid pointtype 4 pointsize default pointinterval 0
set style line 22  linecolor rgb "#006d68"  linewidth 2.000 dashtype solid pointtype 8 pointsize default pointinterval 0
set style line 23  linecolor rgb "#00857d"  linewidth 2.000 dashtype solid pointtype 10 pointsize default pointinterval 0
set style line 24  linecolor rgb "#006298"  linewidth 2.000 dashtype solid pointtype 12 pointsize default pointinterval 0
set style line 25  linecolor rgb "#298fc2"  linewidth 2.000 dashtype solid pointtype 14 pointsize default pointinterval 0
set style line 26  linecolor rgb "#563d82"  linewidth 2.000 dashtype solid pointtype 7 pointsize default pointinterval 0
set style line 27  linecolor rgb "#6f5091"  linewidth 2.000 dashtype solid pointtype 5 pointsize default pointinterval 0
set style line 28  linecolor rgb "#e35205"  linewidth 2.000 dashtype solid pointtype 9 pointsize default pointinterval 0
set style line 29  linecolor rgb "#ff7f41"  linewidth 2.000 dashtype solid pointtype 11 pointsize default pointinterval 0
set style line 30  linecolor rgb "#89813d"  linewidth 2.000 dashtype solid pointtype 13 pointsize default pointinterval 0
set style line 31  linecolor rgb "#afa96e"  linewidth 2.000 dashtype solid pointtype 15 pointsize default pointinterval 0
set style line 32  linecolor rgb "#7c878e"  linewidth 2.000 dashtype solid pointtype 14 pointsize default pointinterval 0
set style line 33  linecolor rgb "#c1c6c8"  linewidth 2.000 dashtype solid pointtype 16 pointsize default pointinterval 0
unset style arrow
set style histogram clustered gap 2 title textcolor lt -1 font "Times Bold,18" boxed
unset object
set style textbox transparent margins  1.0,  1.0 border
unset logscale
set offsets 0, 0, 0, 0
set pointsize 1
set pointintervalbox 1
set encoding default
unset polar
unset parametric
unset decimalsign
set view 60, 30, 1, 1
set samples 100, 100
set isosamples 10, 10
set surface 
unset contour
set cntrlabel  format '%8.3g' font '' start 5 interval 20
set mapping cartesian
set datafile separator whitespace
unset hidden3d
set cntrparam order 4
set cntrparam linear
set cntrparam levels auto 5
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
set xtics border in scale 0,0 mirror rotate by -65  autojustify
set xtics  norangelimit 
set xtics font "Times, 18"
set ytics border in scale 1,0.5 mirror norotate  autojustify
set ytics  norangelimit autofreq 
set ztics border in scale 1,0.5 nomirror norotate  autojustify
set ztics  norangelimit autofreq 
unset x2tics
unset y2tics
set cbtics border in scale 1,0.5 mirror norotate  autojustify
set cbtics  norangelimit autofreq 
set rtics axis in scale 1,0.5 nomirror norotate  autojustify
set rtics  norangelimit autofreq 
unset paxis 1 tics
unset paxis 2 tics
unset paxis 3 tics
unset paxis 4 tics
unset paxis 5 tics
unset paxis 6 tics
unset paxis 7 tics
set title "h5diff, 2 runs per HDF5 version, Jelly (CentOS 7)" 
set title  font "" norotate
set timestamp bottom 
set timestamp "" 
set timestamp  font "" norotate
set rrange [ * : * ] noreverse nowriteback
set trange [ * : * ] noreverse nowriteback
set urange [ * : * ] noreverse nowriteback
set vrange [ * : * ] noreverse nowriteback
set xlabel "" 
set xlabel  font "Times Bold,18" textcolor lt -1 norotate
set x2label "" 
set x2label  font "" textcolor lt -1 norotate
set xrange [ * : * ] noreverse nowriteback
set x2range [ * : * ] noreverse nowriteback
set ylabel "Time (seconds)" 
set ylabel  font "Times Bold,18" textcolor lt -1 rotate by -270
set y2label "" 
set y2label  font "" textcolor lt -1 rotate by -270
set yrange [ 0 : * ] noreverse nowriteback
set y2range [ * : * ] noreverse nowriteback
set zlabel "" 
set zlabel  font "" textcolor lt -1 norotate
set zrange [ * : * ] noreverse nowriteback
set cblabel "" 
set cblabel  font "" textcolor lt -1 rotate by -270
set cbrange [ * : * ] noreverse nowriteback
set paxis 1 range [ * : * ] noreverse nowriteback
set paxis 2 range [ * : * ] noreverse nowriteback
set paxis 3 range [ * : * ] noreverse nowriteback
set paxis 4 range [ * : * ] noreverse nowriteback
set paxis 5 range [ * : * ] noreverse nowriteback
set paxis 6 range [ * : * ] noreverse nowriteback
set paxis 7 range [ * : * ] noreverse nowriteback
set zero 1e-08
set lmargin  -1
set bmargin  -1
set rmargin  -1
set tmargin  -1
set locale "en_US.UTF-8"
set pm3d explicit at s
set pm3d scansautomatic
set pm3d interpolate 1,1 flush begin noftriangles noborder corners2color mean
set palette positive nops_allcF maxcolors 0 gamma 1.5 color model RGB 
set palette rgbformulae 7, 5, 15
set colorbox default
set colorbox vertical origin screen 0.9, 0.2, 0 size screen 0.05, 0.6, 0 front bdefault
set style boxplot candles range  1.50 outliers pt 7 separation 1 labels auto unsorted
set loadpath 
set fontpath 
set psdir
set fit brief errorvariables nocovariancevariables errorscaling prescale nowrap v5
GNUTERM = "aqua"
set key top left
set bmargin at screen 0.3
## Last datafile plotted: "h5diff-timings"
plot newhistogram "1.8", \
'prog-timings.1' i 0 u 2:xtic(1) noti linecolor rgb "#377eb8",\
'prog-timings.2' i 0 u 2:xtic(1) noti linecolor rgb "#377eb8",\
newhistogram "1.10",\
'prog-timings.1' i 1 u 2:xtic(1) noti linecolor rgb "#e41a1c",\
'prog-timings.2' i 1 u 2:xtic(1) noti linecolor rgb "#e41a1c",\
newhistogram "1.12", \
'prog-timings.1' i 2 u 2:xtic(1) noti linecolor rgb "#4daf4a",\
'prog-timings.2' i 2 u 2:xtic(1) noti linecolor rgb "#4daf4a",\
newhistogram "", \
'prog-timings.1' i 3 u 2:xtic(1) noti linecolor rgb "#984ea3",\
'prog-timings.2' i 3 u 2:xtic(1) noti linecolor rgb "#984ea3"

