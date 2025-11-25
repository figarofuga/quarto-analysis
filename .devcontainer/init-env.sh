#!/bin/bash
set -e

# -----------------------------------------------------------------------------
# 1. R Setup (CmdStan & brms)
# -----------------------------------------------------------------------------

echo ">>> 1. R Setup <<<"
# CmdStanRのインストールとCmdStan本体のセットアップ
# brms等のインストール (Linuxバイナリを使う設定になっているので高速です)
Rscript -e "install.packages(c('reticulate', 'tidyverse', 'easystats', 'here', 'data.table', 'modelsummary', 'broom', 'MatchIt', 'WeightIt', 'cobalt', 'highs', 'rootSolve', 'rms', 'Hmisc', 'marginaleffects', 'grf', 'tmle', 'AIPW'))"

# -----------------------------------------------------------------------------
# 2. Python Setup (uv & PyMC/Bambi)
# -----------------------------------------------------------------------------

echo ">>> 2. Python Setup <<<"
# uvのインストール
# uv のインストール
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # このスクリプト内ですぐ使えるように一時的にsourceする
    export PATH="$HOME/.local/bin:$PATH"
fi


# プロジェクトのセットアップ

if [ -f "pyproject.toml" ]; then
    echo "Found pyproject.toml. Syncing environment..."
    
    uv sync
else
    echo "No pyproject.toml found. Initializing new environment..."
    uv init --no-package --vcs none --bare
    
    # 【ここが修正ポイント】
    # uvが独自にDLするPythonではなく、コンテナのPython(/usr/local/bin/python)を使う
    echo "Creating virtual environment using System Python (shared library enabled)..."
    uv venv --python $(which python)
    
    echo "Adding packages: pymc, bambi, arviz, jupyter, radian..."
    uv add pymc arviz bambi jupyter pandas numpy matplotlib radian
fi

# 仮想環境のアクティベート
source .venv/bin/activate

# -----------------------------------------------------------------------------
# 【追加】Reticulate & Radian Configuration
# -----------------------------------------------------------------------------
echo "Configuring Reticulate and Radian..."

# 1. .Rprofile に RETICULATE_PYTHON を設定
# これにより、Rを起動した瞬間に uv の Python が認識されます
if ! grep -q "RETICULATE_PYTHON" .Rprofile 2>/dev/null; then
  echo 'Sys.setenv(RETICULATE_PYTHON = file.path(getwd(), ".venv", "bin", "python"))' >> .Rprofile
fi

# -----------------------------------------------------------------------------
# 3. Julia Setup (Turing)
# -----------------------------------------------------------------------------
echo ">>> [Julia] Setting up Environment..."

if [ -f "Project.toml" ]; then
    echo "Found Project.toml. Instantiating environment..."
    julia --project=. -e 'using Pkg; Pkg.instantiate()'
else
    echo "No Project.toml found. Adding packages..."
    julia --project=. -e 'using Pkg; Pkg.add(["DataFrames", "DataFramesMeta", "Plots", "StatsModels", "StatsPlots", "IJulia"])'
fi

# IJuliaカーネル登録
julia --project=. -e 'using IJulia; IJulia.installkernel("Julia")'

echo ">>> Setup Complete! <<<"