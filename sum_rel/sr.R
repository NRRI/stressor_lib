
require(RPostgreSQL)
require(graphics)
require(foreign)  # for write.dbf
# require(plyr)  # for rbind.fill


BASEDIR="/home/tbrown/n/proj/WinStress/gis/sumrel/"
BASEDIR="/home/tbrown/Desktop/Proj/WinStress/sumrel_mar2011/"
BASEDIR="/home/tbrown/Desktop/Proj/WinStress/sumrel_apr2011/"
LIBDIR="/home/tbrown/Desktop/Proj/GLNPO/sumrel/"

"||" <- function(...) UseMethod("||")
"||.default" <- .Primitive("||")
"||.character" <- function(...) paste(...,sep="")

source(LIBDIR||"sumrel.R")

statmode = function(x) {
  return(as.numeric(names(sort(-table(x)))[1]))
}

#con = dbConnect(PostgreSQL(), user="tbrown", 
#  dbname="nrgisl01", host="beaver.nrri.umn.edu")
con = dbConnect(PostgreSQL(), user="tbrown", 
  dbname="nrgisl01", host="127.0.0.1", port='15432')

dbSendQuery(con, "set search_path to winstress, public")

lakes = c('Erie', 'Huron', 'Ontario', 'Superior', 'Michigan', 'All5')  # J3

rs = dbSendQuery(con, "SELECT * from ws_attrib_lookup")
flds = fetch(rs, n=-1)

pdf(BASEDIR||'sumrel_All_ws.pdf')
for (lake in lakes) {

    if (lake == 'J3') {
      lake_re = '(Erie|Huron|Ontario)'
    } else if (lake == 'All5') {
      lake_re = '(Erie|Huron|Ontario|Superior|Michigan)'
    } else {
      lake_re = lake
    }

    query = "select * from ws_attrib_v where downstream ~ '"||lake_re||"'"
    query = "select * from ws_attrib_v_apr_2011 where downstream ~ '"||lake_re||"'"
    rs = dbSendQuery(con, query)
    wsdata_in = fetch(rs, n=-1)

    # wsdata_in$farmsacres = norm(wsdata_in$farmsacres)
    # wsdata_in$numberofpigs = norm(wsdata_in$numberofpigs)
    # wsdata_in$cattleandcalves = norm(wsdata_in$cattleandcalves)
    # wsdata_in$hens19weeks = norm(wsdata_in$hens19weeks)
    # wsdata_in$sheepandlambs = norm(wsdata_in$sheepandlambs)
    # wsdata_in$acresofwheat = norm(wsdata_in$acresofwheat)
    # wsdata_in$acrescorn = norm(wsdata_in$acrescorn)
    # wsdata_in$agcen = (wsdata_in$farmsacres + wsdata_in$numberofpigs +
    #   wsdata_in$cattleandcalves + wsdata_in$hens19weeks + wsdata_in$sheepandlambs +
    #   wsdata_in$acresofwheat + wsdata_in$acrescorn)


    # cols = c(     'ptwgt', 'popn',  'rlua',  'lcindx',    'agcen')  

    # Dec. 2010 version
    cols = c(     'pnts',  'popn',  'rlua',  'lcan',      'agcen')  
    transforms = c(zeroLog, zeroLog, zeroLog, arcsintrans, identity)
    transforms = c(zeroLog, zeroLog, zeroLog, zeroLog, zeroLog)

    # Apr. 2011 version
    cols = c(     'pnts2k',  'popn',  'rlua',  'pcntag',      'pcntdev')  
    transforms = c(zeroLog, zeroLog, zeroLog, zeroLog, zeroLog)

    #plot(sumrel(wsdata_in, cols, transforms))
    #hist(sumrel(wsdata_in, cols, transforms), breaks=40)

    if (1) {
        require(plotrix)
        #pdf(BASEDIR||'sumrel_'||lake||'_ws.pdf')
        weighted.hist(sumrel(wsdata_in, cols, transforms), breaks=40,
          xlab='SUMREL', main='SumRel frequency for '||lake||' by watershed')
        #dev.off()
        #pdf(BASEDIR||'sumrel_'||lake||'_area.pdf')
        weighted.hist(sumrel(wsdata_in, cols, transforms), wsdata_in$aream2/1000000., breaks=40,
          xlab='SUMREL', ylab=expression(paste('Area ', (km^2), ' weighted frequency')),
          main='SumRel frequency for '||lake||' by area')
        #dev.off()
    }
     
    for (cn in cols) {
        pdf(BASEDIR||'dist_'||cn||'_'||lake||'.pdf')
        par(xaxt='n')
        weighted.hist(wsdata_in[,cn], breaks=30, xlab='', ylab='', xaxt='n')
        dev.off()
    }
    pdf(BASEDIR||'dist_sumrel_'||lake||'.pdf')
    par(xaxt='n')
    weighted.hist(sumrel(wsdata_in, cols, transforms), breaks=30, xlab='', ylab='', xaxt='n')
    dev.off()

    SR = sumrel(wsdata_in, cols, transforms)

    wsdata_in$sumrel = SR
    write.dbf(wsdata_in, BASEDIR||"sumrel_"||lake||"_ws.dbf")

    show(range(SR))
    show(nrow(wsdata_in))
}
dev.off()

# END of code for most work

# trans = wsdata_in
# for (clm in cols) {
#     trans[trans[,clm]==0,clm] = min(trans[trans[,clm]!=0,clm])
#     trans[,clm]=log10(trans[,clm])
# }

pdf(BASEDIR||'dist.pdf')
for (clm in cols) {
    # what = flds[flds$abbrev==clm, 'description']
    what = clm
    hist(wsdata_in[,clm], breaks=50, main=what)
    nz = wsdata_in[wsdata_in[,clm] > 0, clm]
    hist(nz, breaks=50, main='Non-zero '||what)
    hist(log10(nz), breaks=50, main='Log non-zero '||what)
    # hist(trans[,clm], breaks=50)
    minned = wsdata_in[,clm]
    minned[wsdata_in[,clm] == 0] = min(nz)
    hist(log10(minned), breaks=50, main='Log min non-zero replacement '||what)
    d = wsdata_in[,clm]
    d = scale(d, center=min(d), scale=max(d)-min(d))
    d = d / 0.5 - 1
    hist(asin(sqrt(wsdata_in[,clm])), breaks=50, main='ASin  '||what)
}
dev.off()

# for (clm in cols) {
#     trans[,clm] = (trans[,clm] - mean(trans[,clm])) / sd(trans[,clm])
#     trans[,clm] = norm(trans[,clm])
# }
# 
# trans$sumrel = rowSums(trans[,cols])
# trans$sumrel = norm(trans$sumrel)
