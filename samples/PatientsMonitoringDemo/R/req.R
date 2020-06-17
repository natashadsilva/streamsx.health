library("httr")
library("jsonlite")

poll <- function(url) {
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
