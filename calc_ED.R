require(foreign)

# START: config. things

# data table
d = read.dbf('wtshds_all.dbf')
f_id = 'GLAHFID2'  # unique field

# column names for development stressors
dev_stressors = c("rlua", "popn", "pcntdv")
dev_stressors_trans = c("identity", "identity", "identity")
# dev_stressors_trans = c("logtrans", "logtrans", "logtrans")
# dev_stressors_trans = c("arcsin", "arcsin", "arcsin")

# column names for ag. stressors
ag_stressors = c("pcntag")
ag_stressors_trans = c("identity")
# ag_stressors_trans = c("logtrans")
# ag_stressors_trans = c("arcsin")

# road correction related
use_road_correction = T
f_area = "Shape_Area"  # confirm this field is up to date
f_ag = "pcntag"
f_rlua = "rlua"
roadwidth = sum(c(
    1.0,  # gravel by the shoulder
    1.5,  # the shoulder
    3.4   # width of a lane, arbitrarily from
          # http://en.wikipedia.org/wiki/Lane#Lane_width
)) * 2    # for a two land road

roadwidth = 15  # overwride

# END: config things

if (F) {  # "GLEI-2 5971 ED/AgDev" calc.
    d = read.dbf('~/n/proj/WinStress/export/sumrel5x5971/sumrel5x5971.dbf')
    f_id = 'UNIQ_ID3'
    dev_stressors = c("rlua", "popn", "pcntdev")
}

stressors = c(dev_stressors, ag_stressors)
stressors_trans = c(dev_stressors_trans, ag_stressors_trans)

# make a||b shorthand for paste(a,b,sep='')
"||" <- function(...) UseMethod("||")
"||.default" <- .Primitive("||")
"||.character" <- function(...) paste(...,sep="")

normalize = function(x, minx=NA, maxx=NA) {
    # scale vector x into a 0-1 range
    if (is.na(minx)) {
        minx = min(x)
    }
    if (is.na(maxx)) {
        maxx = max(x)
    }
    return((x-minx) / (maxx-minx))
}
identity = function (x) x
logtrans = function (x) log10(x + if (min(x)==0) min(x[x!=0]) else 0)
arcsin = function (x) asin(sqrt(normalize(x)))

# ArcMap fails to distinguish between Null and zero in DBFs, 
# QGis, R, LibreOffice, Excel, and Access all correctly make
# the distinction.  For this particular application, Null can
# be treated as zero
for (stress in stressors) {
    d[stress][d[stress] == -9999] = NA
    d[stress][is.na(d[stress])] = 0
}

if (use_road_correction) {
    # correction for roads in small ~100% ag. watersheds
    roadlen = d[,f_rlua] * d[,f_area]
    roadarea = roadlen * roadwidth
    overag = d[,f_ag] / 100. * d[,f_area] > d[,f_area] - roadarea
    d[,f_ag||'_raw'] = d[,f_ag]
    d[,f_ag][overag] = ((d[,f_area] - roadarea) / d[,f_area] * 100.)[overag]
}

# normalize all stressors
for (stress in stressors) {
    trans = environment()[[stressors_trans[match(stress, stressors)]]]
    d[stress||'_nrm'] = normalize(trans(d[stress]))
}

summary(d)

# calc. maxRel, drop=F for single column cases
d$dev_maxrel = apply(d[, dev_stressors||'_nrm', drop=F], 1, max)
d$ag_maxrel = apply(d[, ag_stressors||'_nrm', drop=F], 1, max)

# calc. Euc. dist.
d$agdev = sqrt(d$ag_maxrel^2 + d$dev_maxrel^2)
d$agdev = normalize(d$agdev)

plots = c(stressors||'_nrm', c('ag_maxrel', 'dev_maxrel', 'agdev'))
rows = as.integer(sqrt(length(plots))+0.5)
cols = rows + if (rows^2 < length(plots)) 1 else 0
png(filename=ag_stressors_trans[1]||'.png', width=800, height=800)
par(mfrow=c(rows, cols), cex=1.)
for (val in plots) {
    hist(d[,val], main='', xlab=val)
}
mtext(ag_stressors_trans[1], outer=T, side=3, line=-2)
dev.off()

# for verification,
stress = order(d$dev_maxrel + d$ag_maxrel, decreasing=T)
if (f_area %in% names(d)) {
    d$area_nrm = normalize(d[,f_area])
} else {
    d$area_nrm = -9999
}
# stress = order(d[,f_id])
# View(round(d[stress, c(f_id, 'area_nrm', paste(stressors, '_nrm', sep=''),
#     'dev_maxrel', 'ag_maxrel', 'agdev')], 3))

      
