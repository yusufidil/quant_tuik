# Activate renv for reproducible package management.
# If renv/activate.R exists, use the standard renv bootstrap.
# Otherwise, fall back to adding the local library to .libPaths().
local({
  activate_script <- file.path(getwd(), "renv", "activate.R")
  if (file.exists(activate_script)) {
    source(activate_script)
  } else {
    project_lib <- file.path(getwd(), "renv", "library")
    if (dir.exists(project_lib)) {
      .libPaths(c(normalizePath(project_lib), .libPaths()))
    }
  }
})
