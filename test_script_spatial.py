import netCDF4 as nc
import numpy as np
import mysql.connector
import psycopg2

f= nc.Dataset("Documents/BigCreek7.2ForExample/out/bigcreek/spatial_data_point_patchvar.nc")

day = f['day'][1:5]
month = f['month'][1:5]
year = f['year'][1:5]

stemc = f['cs.live_stemc'][1:5]
leafc = f['cs.leafc'][1:5]
deadc = f['cs.dead_stemc'][1:5]
plantc = stemc + leafc + deadc

snow = f['snowpack'][1:5].data.tolist()
burn = f['burn'][1:5]
patchfamilyIdx = f['patchID'][1:5]


con = mysql.connector.connect(user='root',
                              host='localhost',
                              database='BigCreek_FutMtn')
                              
cursor = con.cursor(buffered=True)

cursor.execute("CREATE TABLE spatial_data_point(patchfamilyIdx INT, snowpack FLOAT(8), plantC FLOAT(8), burn FLOAT(8), day int, month int, year int)")

# example of one at a time
insert_q = "INSERT INTO spatial_data_point (patchfamilyIdx, snowpack, plantc, burn, day, month, year) VALUES (%s, %s, %s, %s, %s, %s, %s)"
insert_val = (patchfamilyIdx.data[1].item(), snow.data[1].item(), plantc.data[1].item(), burn.data[1].item(), day.data[1].item(), month.data[1].item(), year.data[1].item())
cursor.execute(insert_q, insert_val)
con.commit()

# single column? keep getting syntax errors
insert_q = """INSERT INTO spatial_data_point2 (snowpack, plantC) VALUES (%s, %s)"""
x = snow
y= plantc.data.tolist()
insert_val = (x, y) 

# several rows 
# keep getting stupid error with executemany, not sure why. no errors thrown when using the exact same insert_q with execute()
result = cursor.executemany(insert_q, insert_val)
result
con.commit()
