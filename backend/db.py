import mysql.connector
import os


def get_connection():
    try:
        print("Connecting to DB...")

        connection = mysql.connector.connect(
            host=os.getenv("DB_HOST"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            database=os.getenv("DB_NAME"),
            port=int(os.getenv("DB_PORT", 3306))
        )

        print("DB Connected ✅")
        return connection

    except Exception as e:
        print("DB ERROR ❌:", e)
        raise