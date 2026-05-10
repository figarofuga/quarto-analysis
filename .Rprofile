Sys.setenv(RETICULATE_PYTHON = file.path(getwd(), ".venv", "bin", "python"))

if (interactive() &&
    Sys.getenv("TERM_PROGRAM") == "vscode" &&
    Sys.getenv("RSTUDIO") == "") {
  source(file.path(Sys.getenv("HOME"), ".vscode-R", "init.R"))
}
