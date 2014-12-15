cv <- include.markdown(file.path(site, "template/resources/rmf_cv.md"))


page <- make.samatha.page(content=content(
  m("h2", "Curriculam Vitae"),
  m("div.row-fluid",
    cv)),
  title="CV",
  layout="default_nocomment_template.R")
