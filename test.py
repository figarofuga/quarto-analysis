#%%

# Required libraries
import pandas as pd


#%%
# I. Create a causal model from the data and domain knowledge.

lalonde_pre = pd.read_csv("lalonde.csv")

lalonde = (pd.get_dummies(lalonde_pre, 
                         columns=["race"], dtype=int)
           .drop(columns=['Unnamed: 0'])
           
           
)

#%%
import dowhy
from dowhy import CausalModel

model = CausalModel(
    data=lalonde,
    treatment="treat",
    outcome="re78",
    common_causes=["age", "educ", "married", "nodegree", "re74", "re75", "race_black", "race_hispan", "race_white"],
    instruments=None)

#%%
model.view_model()
# %%
