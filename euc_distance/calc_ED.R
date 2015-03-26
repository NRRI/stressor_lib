require(foreign)

# usage: R -f calc_ED.R --args <config. file>

# run the config file, specified on the command line
opts = commandArgs(trailingOnly=T)
config_filename = opts[1]
source(config_filename)

# complete set of stressors
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

# functions for transformations on data
identity = function (x) x
logtrans = function (x) log10(x + if (min(x)==0) min(x[x!=0]) else 0)
arcsin = function (x) asin(sqrt(normalize(x)))

# ArcMap fails to distinguish between Null and zero in DBFs, 
# QGis, R, LibreOffice, Excel, and Access all correctly make
# the distinction.  For this particular application, Null can
# be treated as zero
for (stress in stressors) {
    show(stress)
    d[stress][d[stress] == -9999] = NA
    d[stress][is.na(d[stress])] = 0
}

if (use_road_correction) {
    # correction for roads in small ~100% ag. watersheds
    roadlen = d[,f_rlua] * d[,f_area]
    roadarea = roadlen * roadwidth
    overag = d[,f_ag] / 100. * d[,f_area] > d[,f_area] - roadarea
    d[,f_ag||'_raw'] = d[,f_ag]  # save previous value of percent ag.
    d[,f_ag][overag] = ((d[,f_area] - roadarea) / d[,f_area] * 100.)[overag]
}

# normalize all stressors
for (stress in stressors) {
    # apply requested transforms
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

# just for reference, show impact of different transformations on
# inputs
for (trans_name in c('identity', 'logtrans', 'arcsin')) {
    trans = environment()[[trans_name]]
    plots = c(stressors, c('ag_maxrel', 'dev_maxrel', 'agdev'))
    rows = as.integer(sqrt(length(plots))+0.5)
    cols = rows + if (rows^2 < length(plots)) 1 else 0
    png(filename=trans_name||'.png', width=800, height=800)
    par(mfrow=c(rows, cols), cex=1.)
    for (val in plots) {
        x = d[,val]
        if (val %in% stressors) {
            x = trans(x)
        }
        hist(x, main='', xlab=val)
    }
    mtext(trans_name, outer=T, side=3, line=-2)
    dev.off()
}

out_filename = sub('\\.r$', '', config_filename, ignore.case=T) || '.csv'
write.csv(d, out_filename, row.names=F)

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

      
