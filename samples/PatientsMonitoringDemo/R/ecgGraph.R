counter = 0
graph_data = data.frame()
last_window = 0
get_theme <- function(){
    return(theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
                  panel.background = element_rect(fill = "white",
                                colour = "white",
                                size = 0.5, linetype = "solid"),
                panel.grid.major = element_line(size = 0.25, linetype = 'solid',
                                colour = "pink"), 
                panel.grid.minor = element_line(size = 0.25, linetype = 'solid',
                                colour = "white")))
}

refresh <- function(patientId){
    url_ = paste("http://localhost:8014/health/WaveformData/ports/input/0/tuples?partition=", patientId,"&partition=X100-8", sep='')
    summary = next_set(url_, counter, last_window)
    if (length(summary) == 0){
        return (data.frame())
    } else {
        counter <<-summary$counter
        last_window <<-summary$windows
        return (summary$data)
    }
    
}
next_set <- function(url_, lastTotal, lastWindows){
            waveData = poll(url_)
            if (nrow(waveData) == 0){
                return(waveData)
            }
            newWindows <- waveData$windowCount
            obs <- waveData$observations
            unrepeated_windows = setdiff(newWindows, lastWindows)
            #for each set of observations
            #check its window count...if we have already seen it, skip it
            # observations is a  list of dataframes
            # each dataframe is a set of observations
            data = data.frame() 
           for (row in 1:length(obs)) {
               if (row <= length(newWindows)){
                   #if this window is in the set of new windows
                   curentWindow = newWindows[row]
                   if (is.element(curentWindow, unrepeated_windows)){
                       next_frame <- obs[[row]] #this is a dataframe describing this set of observations
                       next_frame <- next_frame
                       data = bind_rows(data, next_frame)
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
    graph_data = data.frame()
}
