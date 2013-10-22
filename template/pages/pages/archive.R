page <- make.samatha.page(content=content(
  m("h2", "Blog Archive"),
  html.postlist(site)),
             title="Archive",
                          layout="default_nocomment_template.R")
