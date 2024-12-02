#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jul  7 09:16:45 2023

Using: https://github.com/ading2210/passmark-scraper

@author: athan
"""

from scraper import Scraper
import pandas   as pd
import tabulate

## get data fro CPUs
scraper = Scraper("www.cpubenchmark.net")

## search for a specific term
# search_results = scraper.search(query="i5 53",    limit = 4)

CPU = [
    "G3460",              # blue
    "Ryzen 5 5500U",
    "Ryzen 5 5600G",
    "Ryzen 7 Pro 5850U",
    "Ryzen 7 5700G",
    "Xeon Silver 4108",   # yperos
    "i3-3110M",           # crane
    "i5-1135G7",
    "i5-3380M",           # tyler
    "i5-3450",
    "Ryzen 5 2600",
    "i5-4310M",
    "i5-4590",
    "i5-5300U",
    "i5-6200U",
    "i5-6300U",
    "i5-6440HQ",
    "i5-6500",
    "i5-7200U",
    "i5-7300U",
    "i5-7500",
    "i5-7600",
    "i5-8250U",
    "i5-8265U",
    "i5-8350U",
    "i5-8400",
    "i5-8500",
    "i7-3520M",
    "i7-4790",
    "i7-5500U",
    "i7-5600U",
    "i7-6700",
    "i7-6700T",
    "i7-7600U",
    "i7-7820HQ",
    "Q8200",
    "i7-8700",
    "i3-13100",
    "i5-12400",
    "i3-12100",
    "i7-8750H",
]


res = []
for aq in CPU:
    qq = scraper.search(query=aq, limit=1)[0][0]
    qq['key'] = aq
    res.append(qq)

## convert to pandas
data = pd.DataFrame.from_dict(res)

# cnumeric = ['cpumark']
# data[cnumeric] = data[cnumeric].apply(pd.to_numeric)
# data[cnumeric] = data[cnumeric].str.replace(',', '').astype(float)
# data[cnumeric] = data[cnumeric].astype(float)
# data.iloc[:,:].str.replace(',', '').astype(float)

## convert to numeric
data.cpumark = data.cpumark.str.replace(',','').astype(float)
data.thread  = data.thread .str.replace(',','').astype(float)

## set known machines fro id
## is id stable??
data.loc[data["id"] == "1973", "id"] = 'tyler'
data.loc[data["id"] == "2361", "id"] = 'blue'
data.loc[data["id"] == "3099", "id"] = 'sagan'
data.loc[data["id"] == "3167", "id"] = 'yperos'
data.loc[data["id"] == "763",  "id"] = 'crane'

## use tyler as base
refmark   = data.cpumark[data.id == "tyler"]
refthread = data.thread[data.id  == "tyler"]
data['Rel cpumark'] = data.cpumark /   refmark.squeeze()
data['Rel thread']  = data.thread  / refthread.squeeze()

## clean duplicates and save all data
data = data.drop_duplicates()
data.to_csv('CPU_scrap_data.csv')
data.to_csv('~/LOGs/CPU_scrap_data.csv')

## ignore these keys
removekeys = ['price',
              'secondaryCores',
              'secondaryLogicals',
              'output',
              'value',
              'speed',
              'href',
              'rank',
              'powerPerf',
              'socket',
              'cpuCount',
              'threadValue',
              'name',
              'turbo',
              'tdp',
              'thread',
              ]

# ## print a nice format table in console without pandas
# ## remove some keys from dictionaries
# cres = []
# for ar in res:
#     for k in removekeys:
#         ar.pop(k, None)
#         # print(ar)
#     cres.append(ar)
#
# ## create a nice table
# header = cres[0].keys()
# rows = [x.values() for x in cres]
# print(tabulate.tabulate(rows, header))

## print a nice pandas table to terninal
pp = data.drop(removekeys, axis=1)
pp = pp.round(3)
pp = pp.sort_values(by=['cpumark'], ascending=False)

## rearrange columns
pp.insert(1, 'Rel cpumark', pp.pop('Rel cpumark'))
pp.insert(2, 'Rel thread',  pp.pop('Rel thread'))
pp.insert(3, 'cpumark',     pp.pop('cpumark'))
#pp.insert(4, 'thread',      pp.pop('thread'))
pp.insert(4, 'key',         pp.pop('key'))


## output
print("")
print(tabulate.tabulate(pp,
                        headers='keys',
                        tablefmt='simple',
                        showindex="no")
      )
print("")
