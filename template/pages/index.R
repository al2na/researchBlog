layout <- "default_template.R"
title <- "home"

page <- content(m("h2", "Robert's Musings:"),
               html.postlist(site))
 
