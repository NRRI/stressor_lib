require(foreign)

# usage: R -f calc_ED.R --args <config. file>

# run the config file, specified on the command line
opts = commandArgs(trailingOnly=T)
config_filename = opts[1]
source(config_filename)

if (! exists('minmax')) {
    minmax = list(min=list(), max=list())
}

# complete set of stressors
stressors = c(dev_stressors, ag_stressors)
stressors_trans = c(dev_stressors_trans, ag_stressors_trans)

out_fields = c()
if (is.null(extra_fields)) {
    extra_fields = names(d)
}

# make a||b shorthand for paste(a,b,sep='')
"||" <- function(...) UseMethod("||")
"||.default" <- .Primitive("||")
"||.character" <- function(...) paste(...,sep="")

normalize = function(x, minx=NA, maxx=NA, ignore=NULL) {
    # scale vector x into a 0-1 range
    show(length(ignore))
    if (length(ignore) == 0) {
        ignore = rep(FALSE, length(x))
    }
    if (is.na(minx)) {
        minx = min(x[!ignore])
    }
    if (is.na(maxx)) {
        maxx = max(x[!ignore])
    }
    ans = (x-minx) / (maxx-minx)
    ans[ans < 0] = 0
    ans[ans > 1] = 1
    return(ans)
}

# functions for transformations on data
identity = function (x) x
logtrans = function (x) log10(x + if (min(x)==0) min(x[x!=0]) else 0)
arcsin = function (x) asin(sqrt(normalize(x)))

if (use_road_correction) {
    # correction for roads in small ~100% ag. watersheds
    roadlen = d[,f_rlua] * d[,f_area] / 1000  # in m, so * 1,000,000 / 1,000
    roadarea = roadlen * roadwidth  # in m2
    max_ag = d[,f_area] - roadarea
    overag = d[,f_ag] / 100. * d[,f_area] > max_ag
    d[,f_ag||'_raw'] = d[,f_ag]  # save previous value of percent ag.
    out_fields = c(out_fields, f_ag||'_raw')
    d[,f_ag][overag] = (max_ag / d[,f_area] * 100.)[overag]
}

# d_ignore this suitable for use as a subscript
if (length(d_ignore) == 0) {
    d_ignore = rep(FALSE, length(d))
}


# normalize all stressors
for (stress in stressors) {
    # get requested transform
    trans = environment()[[stressors_trans[match(stress, stressors)]]]
    # use or calculate minmax
    if (! stress %in% names(minmax$min)) {
        minmax$min[[stress]] = min(d[,stress][!d_ignore])
    }
    if (! stress %in% names(minmax$max)) {
        minmax$max[[stress]] = max(d[,stress][!d_ignore])
    }
    d[,stress||'_nrm'] = normalize(
        trans(d[,stress]),
        minx=minmax$min[[stress]],
        maxx=minmax$max[[stress]],
        ignore=d_ignore
    )
    out_fields = c(out_fields, stress||'_nrm')
}

summary(d)

# calc. maxRel, drop=F for single column cases
d$dev_maxrel = apply(d[, dev_stressors||'_nrm', drop=F], 1, max)
d$ag_maxrel = apply(d[, ag_stressors||'_nrm', drop=F], 1, max)
out_fields = c(out_fields, c('dev_maxrel', 'ag_maxrel'))

# calc. Euc. dist.
d$agdev = sqrt(d$ag_maxrel^2 + d$dev_maxrel^2)
out_fields = c(out_fields, 'agdev')

out_filename = sub('\\.r$', '', config_filename, ignore.case=T) || '.ed.csv'
write.csv(d[, c(extra_fields, out_fields)], out_filename, row.names=F)
out_filename = sub('\\.r$', '', config_filename, ignore.case=T) || '.ed.dbf'
write.dbf(d[, c(extra_fields, out_fields)], out_filename)
out_filename = sub('\\.r$', '', config_filename, ignore.case=T) || '.ed.minmax.R'
dump("minmax", file=out_filename, control=NULL)
