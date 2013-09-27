currState <- get.site.state(site)

source_posts <- names(currState$source_posts)
postdates <- as.Date(str_extract(source_posts, "[[:digit:]]{4}_[[:digit:]]{2}_[[:digit:]]{2}"), format = "%Y_%m_%d")
postmodified <- currState$source_posts

useorder <- order(postdates, postmodified, decreasing=T)

postmd <- str_replace(source_posts, "\\.Rmd", "\\.md")
postmd <- postmd[useorder]
postdates <- postdates[useorder]

print(postmd[1])

page <- make.samatha.page(content=content(include.markdown(postmd[1]),
                                          m("h6",
                                            link.to(get.postpath(postmd[1]), paste0("Posted on ", postdates[1]))),
                                          m("h2", "Recent Posts:"),
                                          html.postlist(site, 5)),
                          title="Home",
                          layout="default_nocomment_template.R"
              )
 
