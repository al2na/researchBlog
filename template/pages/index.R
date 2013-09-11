layout <- "default_nocomment_template.R"
title <- "home"

currState <- get.site.state(site)

postlist <- list.files(file.path(site, "template/posts"))
postlist <- postlist[str_detect(postlist, "\\.Rmd")]
postmodified <- file.states(file.path(site, "template", "posts", postlist))
postdates <- as.Date(str_extract(postlist, "[[:digit:]]{4}_[[:digit:]]{2}_[[:digit:]]{2}"), format = "%Y_%m_%d")

useorder <- order(postdates, postmodified, decreasing=T)
postlist <- postlist[useorder]
postdates <- postdates[useorder]

curr.post <- str_replace(postlist[1], "\\.Rmd", "\\.md")

page <- content(include.markdown(file.path(site, "template", "posts", curr.post)),
  m("h2", "Older Posts:"),
               html.postlist(site))
 
