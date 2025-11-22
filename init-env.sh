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
  
  # renv.lock があり、FORCEでないなら Restore
  if [ "${FORCE}" = false ] && [ -f "renv.lock" ]; then
    echo "Found renv.lock. Restoring environment..."
    Rscript -e 'if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv"); renv::restore(prompt = FALSE)'
  else
    # 新規作成
    echo "Creating new R environment..."
    if [ -f ".Rprofile" ] && grep -q 'source("renv/activate.R")' .Rprofile; then
      sed -i '/source("renv\/activate.R")/d' .Rprofile
    fi
    Rscript -e 'renv::init(bare = FALSE)'
    Rscript -e "renv::install(c('${deps_vector}'))"
    Rscript -e 'renv::snapshot(type = "all", prompt = FALSE)'
  fi
}

initialise_uv() {
  local deps=$1
  deps_space=$(echo "${deps}" | sed 's/,/ /g')

  echo "----------------------------------------------------------------"
  echo "Initializing Python (uv) environment..."

  # uv.lock があり、FORCEでないなら Sync (Restore)
  if [ "${FORCE}" = false ] && [ -f "uv.lock" ]; then
    echo "Found uv.lock. Syncing environment..."
    uv sync
    source .venv/bin/activate
  else
    # 新規作成
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

  # Project.toml があり、FORCEでないなら Instantiate (Restore)
  # Manifest.toml があればバージョン完全固定で復元され、なければProject.tomlから解決されます
  if [ "${FORCE}" = false ] && [ -f "Project.toml" ]; then
    echo "Found Project.toml. Instantiating environment..."
    if [ -f "Manifest.toml" ]; then
        echo "  (Manifest.toml found: Restoring exact versions)"
    else
        echo "  (Manifest.toml NOT found: Resolving versions from Project.toml)"
    fi
    julia --project=. -e 'using Pkg; Pkg.instantiate()'
  
  else
    # 新規作成
    echo "Creating new Julia environment..."
    # 強制モードの場合は既存の設定ファイルを削除してクリーンにする
    if [ "${FORCE}" = true ]; then
       rm -f Project.toml Manifest.toml
    fi
    
    # 現在のディレクトリでActivateし、パッケージを追加
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
R_PKGS="AIPW,broom,cobalt,tidyverse,tidymodels,easystats,grf,highs,marginaleffects,MatchIt,modelsummary,rms,tmle,WeightIt,SuperLearner,skimr,reticulate,rootSolve,survival,languageserver,nx10/httpgd@v2.0.4"
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