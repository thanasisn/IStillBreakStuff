#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jul  7 09:16:45 2023

Using: https://github.com/ading2210/passmark-scraper

@author: athan
"""


from scraper import Scraper
import pandas as pd
import tabulate


scraper = Scraper("www.cpubenchmark.net")

## search for a specific term
# search_results = scraper.search(query="i5 53",    limit = 4)

res = []
res.append(scraper.search(query="G3460",         limit=1)[0][0])  # blue
res.append(scraper.search(query="Ryzen 5 5500U", limit=1)[0][0])
res.append(scraper.search(query="i5-1135G7",     limit=1)[0][0])
res.append(scraper.search(query="i5-3380M",      limit=1)[0][0])  # tyler
res.append(scraper.search(query="i5-4310M",      limit=1)[0][0])
res.append(scraper.search(query="i5-5300U",      limit=1)[0][0])
res.append(scraper.search(query="i5-6300U",      limit=1)[0][0])
res.append(scraper.search(query="i5-6440HQ",     limit=1)[0][0])
res.append(scraper.search(query="i5-7200U",      limit=1)[0][0])
res.append(scraper.search(query="i7-5600U",      limit=1)[0][0])

data = pd.DataFrame.from_dict(res)

cnumeric = ['cpumark']
typeof(data[cnumeric] )
data[cnumeric] = data[cnumeric].apply(pd.to_numeric)
data[cnumeric] = data[cnumeric].str.replace(',', '').astype(float)
data[cnumeric] = data[cnumeric].astype(float)
data.iloc[:,:].str.replace(',', '').astype(float)
data = data.drop_duplicates()
data.to_csv('CPU_scrap_data.csv')

## print pandas dt full table
# print(tabulate.tabulate(data, headers='keys', tablefmt='rst', showindex="no"))



# ## print a nice format table in console without pandas

# ## remove some keys from dictionaries
# cres = []
# removekeys = ['price',
#               'secondaryCores',
#               'secondaryLogicals',
#               'output',
#               'value',
#               'href',
#               'socket',
#               'threadValue',
#               'cat']
# for ar in res:
#     for k in removekeys:
#         ar.pop(k, None)
#         # print(ar)
#     cres.append(ar)

# ## create a nice table
# header = cres[0].keys()
# rows = [x.values() for x in cres]
# print(tabulate.tabulate(rows, header))



## print with pandaw
pp = data.drop(removekeys, axis=1)
pp.sort_values(by=['cpumark'], ascending=False)

print(tabulate.tabulate(pp,
                        headers='keys',
                        tablefmt='simple',
                        showindex="no"))
