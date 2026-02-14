# %%

# Required libraries
import pandas as pd
from causalml.propensity import LogisticRegressionPropensityModel
from causalml.match import NearestNeighborMatch
import pandas as pd
import numpy as np


lalonde_py = pd.read_csv("rawdata/lalonde.csv")
# Assume X contains your features (covariates), 
# y is the outcome variable (not used in PSM itself, but for effect estimation later),
# and a is a binary indicator (0 or 1) for treatment assignment.
# This data should be loaded into a pandas DataFrame or numpy array.

# Example placeholder data
X = lalonde_py[['age', 'educ', 'race', 'married', 'nodegree', 're74', 're75']] 
a = lalonde_py['treat'] # 0 for control, 1 for treatment

# 1. Estimate propensity scores
# Use a Gradient Boosted Model to predict treatment assignment 'a' based on features 'X'
from causalml.propensity import ElasticNetPropensityModel

pm = ElasticNetPropensityModel(n_fold=5, random_state=42)
ps = pm.fit_predict(X, a)

from causalml.match import NearestNeighborMatch, create_table_one

psm = NearestNeighborMatch(replace=False,
                           ratio=1,
                           random_state=42)
matched = psm.match_by_group(data=lalonde_py,
                             treatment_col='treat',
                             score_cols=['propensity_score'],
                             groupby_col=None)

create_table_one(data=matched,
                 treatment_col='treat',
                 features=['age', 'educ', 'race', 'married', 'nodegree', 're74', 're75'])
# Optional: Add propensity scores to your main DataFrame
lalonde_py['propensity_score'] = propensity_scores


# %%
# I. Create a causal model from the data and domain knowledge.

lalonde_pre = pd.read_csv("rawdata/lalonde.csv")

lalonde = (pd.get_dummies(lalonde_pre, 
                         columns=["race"], dtype=int)
           
           
)


# %%

import dowhy
import networkx as nx
from dowhy import CausalModel


# 2. NetworkXでグラフを定義
causal_graph = nx.DiGraph()
# "age", "educ", "married", "nodegree", "re74", "re75", "race_black", "race_hispan", "race_white"
# ノードとエッジを追加 (交絡構造: Age -> Exercise, Age -> Health)
causal_graph.add_nodes_from(["treat", "age", "educ", "married", "nodegree", "re74", "re75", "race_black", "race_hispan", "race_white", "re78"])
causal_graph.add_edges_from([
    ('treat', 're78'),
    ('re74', 're75'),
    ('age', 'treat'), 
    ('age', 're78'),
    ('educ', 'treat'),
    ('educ', 're78'),
    ('married', 'treat'),
    ('married', 're78'),
    ('nodegree', 'treat'),
    ('nodegree', 're78'),
    ('re74', 'treat'),
    ('re75', 'treat'), 
    ('re75', 're78'), 
    ('race_black', 'treat'),
    ('race_black', 're74'),
    ('race_black', 're75'),
    ('race_black', 're78'),
    ('race_hispan', 'treat'),
    ('race_hispan', 're74'),
    ('race_hispan', 're75'),
    ('race_hispan', 're78'),
    ('race_white', 'treat'),
    ('race_white', 're74'),
    ('race_white', 're75'),
    ('race_white', 're78')
    
])

# 3. NetworkXオブジェクトをGML文字列に変換
# 注意: 文字列内の改行コードなどを整形して渡します
gml_string = "".join(nx.generate_gml(causal_graph))

# 4. モデルの定義
model = CausalModel(
    data=lalonde,
    treatment='treat',
    outcome='re78',
    graph=gml_string
)

# 5. グラフの確認
model.view_model()



# model = CausalModel(
#     data=lalonde_post,
#     treatment="treat",
#     outcome="re78",
#     common_causes=["age", "educ", "married", "nodegree", "re74", "re75", "race_black", "race_hispan", "race_white"],
#     instruments=None)

model.summary()

identified_estimand = model.identify_effect(proceed_when_unidentifiable=True)

print(identified_estimand)

causal_estimate = model.estimate_effect(identified_estimand,
        method_name="backdoor.propensity_score_stratification")
        
print(causal_estimate)

res_random=model.refute_estimate(identified_estimand, causal_estimate, method_name="random_common_cause", show_progress_bar=True)
print(res_random)

#%%
from econml.dml import LinearDML

est = LinearDML()

X = lalonde.loc[:,["age", "married", "educ", "nodegree", "re74", "re75"]].to_numpy()

est.fit(lalonde['re78'], 
        lalonde['treat'], 
        X=X
        )
point = est.effect(X, T0=0, T1=1)

point = est.const_marginal_effect(X)
lb, ub = est.const_marginal_effect_interval(X, alpha=0.05)

# %%

