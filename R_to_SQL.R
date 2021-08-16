# setting up sql db for future mountain 
# aka re-learning sql with R 
# using tutorial from - https://rmariadb.r-dbi.org/

# first in terminal: mysql.server start
library(RMariaDB)

# connect to mysql 
con = dbConnect(RMariaDB::MariaDB(), user = 'root', password = '',host = 'localhost', port=3306, db="BigCreek_FutMtn")

# using cube agg as example
dbWriteTable(con, "aggcube_data_point", cube_agg) # put together in organize_rhessys_to_sql.R 
dbListTables(con)
dbListFields(con, "aggcube_data_point")
dbSendStatement(con, "ALTER TABLE aggcube_data_point
                ADD id int PRIMARY KEY,
                ADD dateIdx int UNIQUE KEY,
                ADD UNIQUE KEY (warmingIdx)")
# then to add warming scenarios to this table 
db_insert_into(con, "aggcube_data_point", cube_agg)


# individual cubes
# to write the first table
dbWriteTable(con, "cube_data_point", allcube_veg) 
dbSendStatement(con, "ALTER TABLE cube_data_point
                ADD id int PRIMARY KEY,
                ADD dateIdx int UNIQUE KEY,
                ADD cubeIdx int UNIQUE KEy, 
                ADD UNIQUE KEY (patchfamilyIdx),
                ADD UNIQUE KEY (warmingIdx)")
dbListFields(con, "cube_data_point")
# then to add warming scenarios to this table 
db_insert_into(con, "cube_data_point", allcube_veg)


# spatial data 
RMariaDB::dbWriteTable(con, "spatial_data_point2", dfspace) 
dbSendStatement(con, "ALTER TABLE spatial_data_point
                ADD id int PRIMARY KEY,
                ADD warmingIdx int UNIQUE KEY,
                ADD UNIQUE KEY (patchfamilyIdx)")
dbListFields(con, "spatial_data_point")

## Other SQL command examples
# to delete
dbSendStatement(con, "DROP TABLE cube_data_point")

# send queries
res <- RMariaDB::dbSendQuery(con, "SELECT * FROM cube_data_point limit 10;")
dbFetch(res)
dbClearResult(res)

# after finished, be sure to close 
dbDisconnect(con)

