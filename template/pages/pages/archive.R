layout <- "default_nocomment_template.R"
title <- "home"

page <- list(content=content(
  m("h2", "Blog Archive"),
  html.postlist(site)),
             title="Archive")
