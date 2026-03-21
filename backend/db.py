import mysql.connector


def get_connection():
    connection = mysql.connector.connect(
        host="localhost",
        user="root",
        password="SHYAM 007",
        database="campus_lost_found"
    )

    return connection