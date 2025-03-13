##### Exam number: TODO
I have decided to investigate the topic of global warming, and specifically how it can be shown using Irish data.

---

I decided to build an interactive system that clearly and intuitively shows the increase in the air temperature in Ireland.

I also wanted to show the correlation between the temperature and a known effect of global warming, in this case the rate at which glaciers are melting.


---

I took inspiration from some existing interactive information systems I found on the internet:
---
The Central Statistics Office

  ![[Pasted image 20250313161959.png]]
---
The NASA Vital Signs Page
  ![[Pasted image 20250313162156.png]]
  
---
- Our World in Data
- WorldData.info
- Kaggle

---
World Glacier Monitoring Service

![[wgms_darktheme_logol.png]]
---
![[Pasted image 20250313163523.png]]
---

![[Pasted image 20250313171358.png]]
---
## Before cleaning
```
                                YEAR  ...  ANNUAL_BALANCE_UNC
count                          54249  ...        10254.000000
mean   1995-07-03 08:00:22.297185152  ...          110.432915
min              1885-01-01 00:00:00  ...            0.000000
25%              1982-01-01 00:00:00  ...           20.000000
50%              2000-01-01 00:00:00  ...           50.000000
75%              2013-01-01 00:00:00  ...          200.000000
max              2024-01-01 00:00:00  ...         1800.000000
std                              NaN  ...          131.058821

[8 rows x 11 columns]
```

---
## After cleaning
```
                                Date        Change
count                            134  1.340000e+02
mean   1955-07-27 09:40:17.910447744 -3.926690e+05
min              1885-01-01 00:00:00 -2.358840e+06
25%              1923-04-02 06:00:00 -6.404765e+05
50%              1956-07-02 00:00:00 -8.212500e+04
75%              1989-10-01 18:00:00 -4.011450e+04
max              2023-01-01 00:00:00  1.454800e+04
std                              NaN  4.999753e+05
```

---
## Before cleaning
```
                               Month      TLIST(M1)  C02431V02938         VALUE
count                          58500   58500.000000  58500.000000  50355.000000
mean   1990-06-16 13:58:09.230769152  199006.500000      8.000000      9.701348
min              1958-01-01 00:00:00  195801.000000      1.000000    -17.100000
25%              1974-03-24 06:00:00  197403.750000      4.000000      5.100000
50%              1990-06-16 00:00:00  199006.500000      8.000000      9.700000
75%              2006-09-08 12:00:00  200609.250000     12.000000     14.300000
max              2022-12-01 00:00:00  202212.000000     15.000000     32.000000
std                              NaN    1876.185516      4.320531      6.892615
```

---
# After cleaning
```
                                Date  Temperature
count                           3900  3900.000000
mean   1990-06-16 13:58:09.230769280     9.734785
min              1958-01-01 00:00:00    -9.880000
25%              1974-03-24 06:00:00     5.105769
50%              1990-06-16 00:00:00     9.684524
75%              2006-09-08 12:00:00    14.300000
max              2022-12-01 00:00:00    28.366667
std                              NaN     6.784726
```
