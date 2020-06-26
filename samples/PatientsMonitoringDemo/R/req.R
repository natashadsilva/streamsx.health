library("httr")
library("jsonlite")

NAMES = fromJSON("names.json")


set_config(config(ssl_verifypeer = 0L))
get_json_from_url <- function(url) {
    r <- GET(url, add_headers("Accept" = "application/json"))
    r$status_code
    if (r$status_code == 200){
        elems = content(r, "text")
        df = fromJSON(elems) 
        return( df)
    } else {
        warn_for_status(r, "Error retrieving JSON")
        return (data.frame())
    }
}

get_all_patients_as_df <- function(filtr){
    mydf <- get_json_from_url(STATUS_URL)$patientMap
    #each patient is a column, but we need to pack this data frame
    # so that each patient is a row
    packed = pivot_longer(mydf, starts_with("patient-"), names_to = "id")
    packed = packed$value
    if (nrow(packed) <= nrow(NAMES)) {
        name_and_gender = NAMES[c(1:nrow(packed)),]
        packed$name = name_and_gender$name
        packed$gender = name_and_gender$gender
    }
    if (filtr){
      packed  = dplyr::filter(packed, alert == TRUE)
    }
    packed
    return(packed)
    
}