layout <- "default_nocomment_template.R"
title <- "home"

page <- content(
  m("h2", "Blog Archive"),
  html.postlist(site))
