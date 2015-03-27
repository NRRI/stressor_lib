# configuration / set up for calc_ED.R

# data table
# change to `d = read.dbf('some/path/wtshds_all.dbf')` etc. as appropriate
d = read.csv('example_data.csv')

# column names for development stressors
dev_stressors = c("roadden", "pop", "pcntdev")

# names of transformations to apply to dev_stressors,
# choices are "identity", "logtrans", "arcsin"
dev_stressors_trans = c("identity", "identity", "identity")

# column names for ag. stressors
ag_stressors = c("pcntag")

# names of transformations to apply to ag_stressors
ag_stressors_trans = c("identity")

# make any fixes to the data as required
for (stress in c(dev_stressors, ag_stressors)) {
    d[stress][d[stress] == -9999] = NA
    d[stress][is.na(d[stress])] = 0
}

# road correction, if F, remaining items can be ignored
use_road_correction = F  # T / F to use / skip road correction
# area field, in m2 - confirm this field is up to date
f_area = "Shape_Area" 
# field containing percent agricultural land cover
f_ag = "pcntag"
# field containing road density in km/km2
f_rlua = "roadden"
roadwidth = 15  # road width in meters, incl. shoulder etc.,
                # typical of rural roads missed by land cover
