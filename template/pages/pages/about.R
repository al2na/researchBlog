layout <- "default_nocomment_template.R"
title <- "home"

about.the.blog <- include.markdown(file.path(site, "template/resources/about_blog.md"))

about.me <- include.markdown(file.path(site, "template/resources/about_me.md"))

page <- list(content=content(
    m("h2", "About this site"),
    m("div.row-fluid", 
      about.the.blog),
    m("h2", "About me"),
    m("div.row-fluid",
      about.me)),
             title="About")

