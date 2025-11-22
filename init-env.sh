#!/usr/bin/env bash

show_help() {
  echo "Usage: $0 [--what/-w all|r|python|julia|r_py] [--force/-f] [--help/-h]"
  echo "  --what/-w: Specify what to initialise (default: all)."
  echo "    all: Initialise R (renv), Python (uv), and Julia (project)."
  echo "    r: Initialise R (renv)."
  echo "    python: Initialise Python (uv)."
  echo "    julia: Initialise Julia (project)."
  echo "  --force/-f: Force initialisation regardless of existing files."
  echo "  --help/-h: Show this help message."
}

initialise_r() {
  local deps=$1
  deps_vector=$(echo "${deps}" | sed 's/,/","/g')
  
  echo "----------------------------------------------------------------"
  echo "Initializing R environment..."

  # Linux用バイナリリポジトリの設定 (Posit Public Package Manager)
  # これを設定するとコンパイル不要になり、インストールが高速かつ安定します
  local R_REPO_SETUP="options(repos = c(PPM = 'https://packagemanager.posit.co/cran/__linux__/jammy/latest', CRAN = 'https://cloud.r-project.org'))"
  
  # 条件: renv.lock があり、FORCEでないなら Restore
  if [ "${FORCE}" = false ] && [ -f "renv.lock" ]; then
    echo "Found renv.lock."
    
    # 重要: renvフォルダ構造(activate.Rなど)がない場合、scaffoldで足場を作成する
    # これがないと .Rprofile から activate.R を呼べず環境が壊れた扱いになる
    if [ ! -f "renv/activate.R" ]; then
      echo "renv infrastructure missing. Scaffolding..."
      Rscript -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv'); renv::scaffold()"
    fi

    echo "Restoring environment from lockfile..."
    # リポジトリ設定を適用しつつ restore を実行
    Rscript -e "${R_REPO_SETUP}; if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv'); renv::restore(prompt = FALSE)"
  
  else
    # 新規作成
    echo "Creating new R environment..."
    if [ -f ".Rprofile" ] && grep -q 'source("renv/activate.R")' .Rprofile; then
      sed -i '/source("renv\/activate.R")/d' .Rprofile
    fi
    
    # init -> install -> snapshot
    Rscript -e "${R_REPO_SETUP}; renv::init(bare = FALSE)"
    Rscript -e "${R_REPO_SETUP}; renv::install(c('${deps_vector}'))"
    Rscript -e 'renv::snapshot(type = "all", prompt = FALSE)'
  fi
}

initialise_uv() {
  local deps=$1
  deps_space=$(echo "${deps}" | sed 's/,/ /g')

  echo "----------------------------------------------------------------"
  echo "Initializing Python (uv) environment..."

  if [ "${FORCE}" = false ] && [ -f "uv.lock" ]; then
    echo "Found uv.lock. Syncing environment..."
    uv sync
    source .venv/bin/activate
  else
    echo "Creating new Python environment..."
    if [ "${FORCE}" = true ]; then
      rm -rf .venv uv.lock pyproject.toml
    fi
    uv init --no-package --vcs none --bare --no-readme --author-from none
    uv venv
    source .venv/bin/activate
    if [ -n "${deps_space}" ]; then
      uv add ${deps_space}
    fi
    uv sync
  fi
}

initialise_julia() {
  local deps=$1
  deps_vector=$(echo "${deps}" | sed 's/,/","/g')

  echo "----------------------------------------------------------------"
  echo "Initializing Julia environment..."

  if [ "${FORCE}" = false ] && [ -f "Project.toml" ]; then
    echo "Found Project.toml. Instantiating environment..."
    if [ -f "Manifest.toml" ]; then
        echo "  (Manifest.toml found: Restoring exact versions)"
    else
        echo "  (Manifest.toml NOT found: Resolving versions from Project.toml)"
    fi
    julia --project=. -e 'using Pkg; Pkg.instantiate()'
  else
    echo "Creating new Julia environment..."
    if [ "${FORCE}" = true ]; then
       rm -f Project.toml Manifest.toml
    fi
    julia --project=. -e "using Pkg; Pkg.activate(\".\"); Pkg.add([\"${deps_vector}\"])"
  fi
}

WHAT="all"
FORCE=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --what|-w)
      WHAT="$2"
      shift
      ;;
    --force|-f)
      FORCE=true
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown parameter passed: $1"
      show_help
      exit 1
      ;;
  esac
  shift
done

# パッケージリスト定義
R_PKGS="AIPW,broom,cobalt,tidyverse,tidymodels,easystats,grf,highs,marginaleffects,MatchIt,modelsummary,rms,tmle,WeightIt,SuperLearner,skimr,reticulate,rootSolve,survival,languageserver"
PY_PKGS="radian,jedi,pandas,polars,tableone,marginaleffects,econml,dowhy,causal-learn,matplotlib,seaborn,plotnine,ipykernel,jupyter,papermill"
JULIA_PKGS="IJulia"

case ${WHAT} in
  all)
    initialise_r "${R_PKGS}"
    initialise_uv "${PY_PKGS}"
    initialise_julia "${JULIA_PKGS}"
    ;;
  r)
    initialise_r "${R_PKGS}"
    ;;
  python)
    initialise_uv "${PY_PKGS}"
    ;;
  julia)
    initialise_julia "${JULIA_PKGS}"
    ;;
  r_py)
    initialise_r "${R_PKGS}"
    initialise_uv "${PY_PKGS}"
    ;;
  *)
    echo "Unknown option for --what: ${WHAT}"
    show_help
    exit 1
    ;;
esac