import pandas as pd
import numpy as np
from scipy.stats import zscore
import matplotlib.pyplot as plt
import matplotlib.colors as colors
import seaborn as sns
import geopandas as gpd
import rpy2.robjects as robjects
from rpy2.robjects.pandas2ri import rpy2py
import locale
locale.setlocale(locale.LC_ALL, 'EN_US')
import calendar

# import cleaned dataframes
r = robjects.r
r['source']('file1.R')
monthly_delay = rpy2py(r.monthly_delay)
monthly_delay_type = rpy2py(r.monthly_delay_type)
delay_state = rpy2py(r.delay_state)
delay_volume = rpy2py(r.delay_volume)


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


shape = gpd.read_file('data/tl_2017_us_state/tl_2017_us_state.shp')
delay_state = delay_state[~delay_state['state'].isin(['AS','AK','HI','VI','PR','GU'])].reset_index()
delay_state['average_delay_std'] = zscore(delay_state['average_delay'])
shape = pd.merge(shape, delay_state, how='right',left_on='STUSPS', right_on='state')
ax = shape.boundary.plot(figsize=(10, 5))
shape.plot(ax=ax,column='average_delay_std', 
           norm=colors.CenteredNorm(),
           legend=True, 
           cmap='coolwarm',
           legend_kwds={'label':'Normalized Delay'})
plt.show()



# Fig3: delay by volume flights
p = sns.scatterplot(x=delay_volume['num_flights'], y=delay_volume['average_delay'])
p.set(title='Percent Delay vs Traffic Volume',
      xlabel='Volume (# of flights in 2015)',
      ylabel='Percent Delay',
      xticks=np.arange(0,300000,20000),
      yticks=np.arange(0,0.55,0.05))
plt.show()