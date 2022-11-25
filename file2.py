import pandas as pd
import numpy as np
import rpy2.robjects as robjects
from rpy2.robjects.pandas2ri import rpy2py
import matplotlib.pyplot as plt
import seaborn as sns
import locale
locale.setlocale(locale.LC_ALL, 'EN_US')
import calendar

# Import cleaned dataframes
r = robjects.r
r['source']('file1.R')
monthly_delay = rpy2py(r.monthly_delay)
monthly_delay_type = rpy2py(r.monthly_delay_type)


color = {'AA':'#14ACDC', 'DL':'#C01933', 'UA':'#0f1f37', 'AS':'#44ABC3', 'B6':'#0b51a0',
         'F9':'#248168', 'HA':'#9D178D', 'NK':'#D9D913', 'VX':'#8031A7', 'WN':'#FFBF27'}

# Fig1: delay across airlines
ax = sns.lineplot(x='month', 
             y='average_delay', 
             hue='airline', 
             palette=color,
             linewidth=1.25,
             data=monthly_delay)
ax.set(title='Delay Across Airlines in 2015',
       xlabel='', 
       ylabel='Fraction of Delayed Flights',
       xticks=np.arange(0,13,1),
       yticks=np.arange(0,0.4,0.05))
ax.set_xticklabels(list(calendar.month_name), rotation=45)
plt.legend(title='Airline', loc='upper right')
plt.show()


# Fig2: delay across airline types
ax = sns.lineplot(x='month', 
             y='average_delay', 
             hue='type', 
             linewidth=1.25,
             data=monthly_delay_type)
ax.set(title='Delay Across Airlines in 2015',
       xlabel='', 
       ylabel='Fraction of Delayed Flights',
       xticks=np.arange(0,13,1),
       yticks=np.arange(0,0.4,0.05))
ax.set_xticklabels(list(calendar.month_name), rotation=45)
plt.legend(title='Airline Type', loc='upper right')
plt.show()