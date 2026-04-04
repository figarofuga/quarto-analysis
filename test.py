# %%

import pandas as pd

lalonde = (
    pd.read_csv("rawdata/lalonde.csv")
    .pipe(pd.get_dummies, columns=["race"], drop_first=True, dtype=int)
)

from econml.metalearners import TLearner
import numpy as np
import pandas as pd 
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.model_selection import train_test_split

X = lalonde.loc[:,["age", "married", "educ", "nodegree", "re74", "re75", "race_hispan", "race_white"]]
y = lalonde['re78']
T = lalonde['treat']
n = lalonde.shape[0]

X_train, X_test, y_train, y_test = train_test_split(
    X, 
    y, 
    test_size=0.2, 
    random_state=42, 
    stratify=T
    )

T_train = T.loc[y_train.index]
T_test = T.loc[y_test.index]

# Instantiate T learner
models = GradientBoostingRegressor(n_estimators=100, max_depth=6, min_samples_leaf=int(n/100))
T_learner = TLearner(models=models)
# Train T_learner
T_learner.fit(y_train, T_train, X=X_train)
# Estimate treatment effects on test data
T_te = T_learner.effect(X_test)

print(T_te)

# %%

import numpy as np
import pandas as pd
import lightgbm as lgb
from sklearn.datasets import load_breast_cancer
from sklearn.model_selection import train_test_split
from sklearn.metrics import root_mean_squared_error



lalonde = (
    pd.read_csv("rawdata/lalonde.csv")
    .pipe(pd.get_dummies, columns=["race"], drop_first=True, dtype=int)
)
# 1. データセットの読み込み
# ここでは例としてscikit-learnの乳がんデータセットを使用します
X = lalonde.loc[:,["treat", "age", "married", "educ", "nodegree", "re74", "re75", "race_hispan", "race_white"]]
y = lalonde['re78']
n = lalonde.shape[0]


# 2. データを学習用（80%）とテスト用（20%）に分割
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# 3. モデルの初期化 (scikit-learn API)
# 引数を指定しない場合、デフォルトのハイパーパラメータが適用されます
model = lgb.LGBMRegressor(random_state=42)

# 4. モデルの学習 (fit)
print("モデルの学習を開始します...")
model.fit(X_train, y_train)
print("学習が完了しました。")

# 5. テストデータでの予測と評価（おまけ）
y_pred = model.predict(X_test)

y_true = [3, -0.5, 2, 7]
y_pred = [2.5, 0.0, 2, 8]
rmse = root_mean_squared_error(y_true, y_pred)

print(f"テストデータのRMSE: {rmse:.4f}")


pred_0 = model.predict(X.assign(treat = 0))
pred_1 = model.predict(X.assign(treat = 1))
te = np.mean(pred_1 - pred_0)

print(f"平均処置効果の推定値: {te:.4f}")

X_s_learn = (
    lalonde
    .loc[:,["treat", "age", "married", "educ", "nodegree", "re74", "re75", "race_hispan", "race_white", "re78"]]
    .assign(
        treat_0 = 0,
        effect_0 = pred_0, 
        treat_1 = 1, 
        effect_1 = pred_1,
        treat_effect = pred_1 - pred_0
    ) 
)

X_s_learn.head()


# %%
