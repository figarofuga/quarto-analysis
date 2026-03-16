uvが起動しない場合は以下を入れてください。

```bash

source .venv/bin/activate

```

もしも、conflictしてgit pullが出来ない時は以下のようにしてください

```bash
git fetch
git reset --hard origin/main
```

renderする時は以下のようにしてください
```bash
quarto preview mlcausal.qmd --to clean-typst --no-watch-inputs --no-browse
```