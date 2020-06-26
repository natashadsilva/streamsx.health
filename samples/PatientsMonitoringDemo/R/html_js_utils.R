

library("jsonlite")
library("shiny")



get_html_css_includes <-  function (){

    return(    tags$head(
              includeCSS("www/css/custom.css"),
              tags$script(HTML(cell_click_handler())))
            )
}


cell_click_handler <- function(){
    return("
    $(document).ready(function(){
    $('body').on('click', '.cell', function(){
        var name = $(this).data('pname'),
            idx = $(this).data('idx');
            //use Math.random so the data is different every time
            //otherwise shiny won't send the event if you click the same  cell twice
        Shiny.setInputValue('cell', {key: Math.random(), name: name, idx: idx});
    });
    });
    ")
}


# generate html grid from data frame
generate_patient_grid <- function (frames) {
  innerhtml = '<div class="container-fluid"><div class="row">'

  for (row in 1:(nrow(frames))) {
    
    patient =  frames[row, ]
    id <- patient$patientId 
    name = patient$name
    alrt_class = "normal"
    alert = patient$alert 
    if (alert == TRUE) {
        alrt_class = "alrt"
    }
    row_html = '<div  class="col-sm-2">'
    
    cell <- sprintf('<div class="cell patient-card fill %s" data-pname="%s" data-idx="%s">', alrt_class, name, row)

    row_html = paste(row_html, cell)   

     row_html = paste(row_html,'<div  class="row">')  

    if (patient$gender == "Female") {
        
         row_html = paste(row_html,'<div  class="col-lg-12">')
        row_html = paste(row_html, '<img src="www/images/female_profile.png" class="icon" /></div>') 
    } else {
         row_html = paste(row_html,'<div  class="col-lg-12">')
        row_html = paste(row_html, '<img src="www/images/male_profile.png" class="icon" /></div>') 
    }
    
                       
     row_html = paste(row_html,'<div  class="col-lg-12 patient-id-row">', name,  '</div>')
     row_html = paste(row_html, '</div>') #end row div


    row_html = paste(row_html, '</div></div>') # end patient card and column
    innerhtml = paste(innerhtml, row_html)
  }
  paste(innerhtml, "</div></div>")
  return (innerhtml)
}