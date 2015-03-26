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
    roadlen = d[,f_rlua] * d[,f_area] / 1000  # in m, so * 1,000,000 / 1,000
    roadarea = roadlen * roadwidth  # in m2
    max_ag = d[,f_area] - roadarea
    overag = d[,f_ag] / 100. * d[,f_area] > max_ag
    d[,f_ag||'_raw'] = d[,f_ag]  # save previous value of percent ag.
    d[,f_ag][overag] = (max_ag / d[,f_area] * 100.)[overag]
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

out_filename = sub('\\.r$', '', config_filename, ignore.case=T) || '.csv'
write.csv(d, out_filename, row.names=F)

      
