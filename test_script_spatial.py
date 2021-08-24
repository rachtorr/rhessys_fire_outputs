import netCDF4 as nc
import numpy as np
import mysql.connector
import psycopg2

f= nc.Dataset("../out/bigcreek/spatial_data_point_patchvar.nc")

day = f['day'][:].data.tolist()
month = f['month'][:].data.tolist()
year = f['year'][:].data.tolist()

stemc = f['cs.live_stemc'][:]
leafc = f['cs.leafc'][:]
deadc = f['cs.dead_stemc'][:]
plantc = stemc + leafc + deadc
del stemc
del leafc
del deadc

snow = f['snowpack'][:].data.tolist()
burn = f['burn'][:].data.tolist()
patchfamilyIdx = f['patchID'][:].data.tolist()

# warming degree
warm = 1

con = mysql.connector.connect(user='root',
                              host='localhost',
                              database='BigCreek_FutMtn')
                              
cursor = con.cursor(buffered=True)

#cursor.execute("CREATE TABLE spatial_data_point(patchfamilyIdx INT, snowpack FLOAT(8), plantC FLOAT(8), burn FLOAT(8), day int, month int, year int, warmingIdx int)")

# example of one at a time
#insert_q = "INSERT INTO spatial_data_point (patchfamilyIdx, snowpack, plantc, burn, day, month, year) VALUES (%s, %s, %s, %s, %s, %s, %s)"
# insert_val = (patchfamilyIdx.data[1].item(), snow.data[1].item(), plantc.data[1].item(), burn.data[1].item(), day.data[1].item(), month.data[1].item(), year.data[1].item())
# cursor.execute(insert_q, insert_val)
# con.commit()


# several rows 
# keep getting stupid error with executemany, not sure why. no errors thrown when using the exact same insert_q with execute()
n = len(snow)
insert_q = "INSERT INTO spatial_data_point (patchfamilyIdx, snowpack, plantc, burn, day, month, year, warmingIdx) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)"
for i in range(n):
	insert_val = (patchfamilyIdx[i], snow[i], plantc.data.tolist()[i], burn[i], day[i], month[i], year[i], warm)
	cursor.execute(insert_q, insert_val)
	con.commit()






