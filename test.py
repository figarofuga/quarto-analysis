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

