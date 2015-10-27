
# scale values in x into a zero to one range
norm = function(x) {
    return( (x-min(x)) / (max(x)-min(x)) )
}

# return values in x transformed to log10, using the minimum
# non zero value instead of zero values
zeroLog = function(x) {
    x[x==0] = min(x[x!=0])  # set to min non-zero where x is zero
    return(log10(x))
}

# return values in x transformed to the arcsin of the square root of x
arcsintrans = function(x) {
  return(asin(sqrt(x)))
}

# for the columns of dat listed in cols, apply the transforms listed
# in transforms, then perform sumrel analysis.  Example usage:
#   cols = c('lccp', 'lcdv', 'ppsk')
#   transforms = c(identity, zeroLog, zeroLog)
#   sr = sumrel(someData, cols, transforms)
sumrel = function(dat, cols, transforms, handle_missing = FALSE) {
    for (n in 1:length(cols)) {
        clm = cols[n]            # the column name
        trans = transforms[[n]]  # and the transformation

        # deliberately choose to ignore or avoid (handle) missing values

        if (handle_missing) {  # choose to avoid (handle) missing values

            # rows to use
            rows = (!is.na(dat[,clm]) & !is.null(dat[,clm]))

            # apply transformation
            dat[,clm][rows] = trans(dat[,clm][rows])
            # standardize
            dat[,clm][rows] = (dat[,clm][rows] -
                mean(dat[,clm][rows])) / sd(dat[,clm][rows])
            # normalize
            dat[,clm][rows] = norm(dat[,clm][rows])          

        } else {  # choose to ignore missing values

            # apply transformation
            dat[,clm] = trans(dat[,clm])
            # standardize
            dat[,clm] = (dat[,clm] - mean(dat[,clm])) / sd(dat[,clm])
            # normalize
            dat[,clm] = norm(dat[,clm])  
        }        

    }
    # add normalized values

    if (handle_missing) {
        sumrel = rowMeans(dat[,cols], na.rm = TRUE)
    } else {
        sumrel = rowSums(dat[,cols])
    }

    # normalize again, for 0-1 range
    sumrel = norm(sumrel)
    return(sumrel)
}
