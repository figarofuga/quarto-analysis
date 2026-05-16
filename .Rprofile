Sys.setenv(RETICULATE_PYTHON = file.path(getwd(), ".venv", "bin", "python"))

if (interactive() &&
    Sys.getenv("TERM_PROGRAM") == "vscode" &&
    Sys.getenv("RSTUDIO") == "" &&
    file.exists(file.path(Sys.getenv("HOME"), ".vscode-R", "init.R")) &&
    !isTRUE(getOption("vscode.R.init.loaded"))) {
  options(vscode.R.init.loaded = TRUE)
  source(file.path(Sys.getenv("HOME"), ".vscode-R", "init.R"))
}
