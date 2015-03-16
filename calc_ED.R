require(foreign)

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

d = read.dbf('wtshds_all.dbf')

d$popn[d$popn==-9999] = NA

# ArcMap fails to distinquish between Null and zero in DBFs, 
# QGis, R, LibreOffice, Excel, and Access all correctly make
# the distinction.  For this particular application, Null can
# be treated as zero

stressors = c("rlua", "popn", "pcntag", "pcntdv")
for (stress in stressors) {
    d[stress][is.na(d[stress])] = 0
    d[paste(stress, '_nrm', sep='')] = normalize(d[stress])
}

summary(d)

d$dev_maxrel = apply(
    d[, c('rlua_nrm', 'popn_nrm', 'pcntdv_nrm')],
    1,
    max
)

d$agdev = sqrt(d$pcntag_nrm^2 + d$dev_maxrel^2)

stress = order(d$dev_maxrel + d$pcntag_nrm, decreasing=T)

d$area_nrm = normalize(d$Shape_Area)

View(round(d[stress, c('GLAHFID2', 'area_nrm', 'rlua_nrm', 'popn_nrm',
            'pcntdv_nrm', 'pcntag_nrm', 'dev_maxrel', 'agdev')], 3))


      
