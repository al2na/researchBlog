layout <- "default_nocomment_template.R"
title <- "home"

page <- content(m("h2", "Post:"),
               html.postlist(site))
 
