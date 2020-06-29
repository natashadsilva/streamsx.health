# 0 based counter for waveform data
counter = 0
# This is effectively used to group waveform data into groups of 1 second
#
last_window = 0
get_theme <- function(){
    return(theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.text.y =element_blank(),
        axis.title.y=element_blank(),
                  panel.background = element_rect(fill = "white",
                                colour = "white",
                                size = 0.5, linetype = "solid"),
                panel.grid.major = element_line(size = 0.25, linetype = 'solid',
                                colour = "pink"), 
                panel.grid.minor = element_line(size = 0.25, linetype = 'solid',
                                colour = "white")))
}

# url - endpoint to query for ecg data, see schemas.md for example output
# patient id  - patient to display 
# returns a data frame with ecg  graph data
# if there is no new data returned from the server, return empty data frame

get_next_ecg_data <- function(url, patientId){
    url_ = paste(url, patientId,"&partition=X100-8", sep='')
    summary = get_next_window_of_data(url_, counter, last_window)
    if (length(summary) == 0){
        summary = list (data =  data.frame(), windows = c())
        return(summary)
    } else {
        
        counter <<-summary$counter
        last_window <<-summary$windows

        return (summary)
    }
    
}
get_next_window_of_data <- function(url_, lastTotal, lastWindows){
    # output sometimes containns windows previously seen
    # this messes up the graph data
    # only return new windows in the data frame
            
            waveData = get_json_from_url(url_)
            
            if (nrow(waveData) == 0){
                return(waveData)
            }
           
            newWindows <- waveData$windowCount
            obs <- waveData$observations
            unrepeated_windows = setdiff(newWindows, lastWindows)
            print(obs)
            #for each set of observations
            #check its window count...if we have already seen it, skip it
            # observations is a  list of dataframes
            # each dataframe is a set of observations
            data = data.frame() 
           for (row in 1:length(obs)) {
               if (row <= length(newWindows)){
                   #if this window is in the set of new windows
                   currentWindow = newWindows[row]
                   if (is.element(currentWindow, unrepeated_windows)){
                       next_frame <- obs[[row]] #this is a dataframe describing this set of observations
                       next_frame <- next_frame
                       data = bind_rows(data, next_frame)
                       data$window = rep(currentWindow, nrow(data))
                   }
               }
                
            }
            summary = list()
            if (nrow(data) > 0){
                new_length = lastTotal + nrow(data)
                data$time = c((lastTotal+1):(new_length))
                summary$data = data
                summary$counter =  new_length
                summary$windows = newWindows
            }
            return(summary)
}

invalidate_ecg <- function(){
    counter <<- 0
    last_window <<- 0
}
