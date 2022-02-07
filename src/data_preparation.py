import pandas as pd
import os
import csv

#Reading raw data
scores = pd.read_csv("C:/repos/2022/data/raw/Scores.csv")
pd.DataFrame.head(scores)

#Data quality checks

#Data cleaning

#Saving cleaned data
scores.to_csv("C:/repos/2022/data/interim/scores_cleaned.csv")