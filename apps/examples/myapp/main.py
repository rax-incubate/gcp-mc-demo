import os
import psycopg2
from flask import Flask

app = Flask(__name__)


@app.route("/run")

def hello_world():

    # All these variables are read from the Kubernetes secrets set on the same namespace as the app
    db_host = os.environ.get("DB_HOST", "127.0.0.1")
    db_host_port = os.environ.get("DB_HOST_PORT", "5432")
    db_name = os.environ.get("DB_NAME", "imdb")
    db_table = os.environ.get("DB_TABLE", "title_basics")
    db_user = os.environ.get("DB_USER", "imdb")
    db_pwd = os.environ.get("DB_PWD", "imdb")

    try:
        conn = psycopg2.connect(
            database=db_name, user=db_user, password=db_pwd, host=db_host, port= db_host_port
            )
    except OperationalError as err:
        print(err)

    try:
        cursor = conn.cursor()
        cursor.execute("SELECT * from " + db_table  + " LIMIT 100")
    except Exception as err:
        print(err)
    rows = cursor.fetchall()
    conn.commit()
    conn.close()
    
    env = os.environ.get("ENV", "default")
    html = env + "<br>\n"
    
    for row in rows:
        html = html + ','.join(map(str, row))
        html = html + "<br>\n"
    
    return(html)

if __name__ == "__main__":
    listen_port = os.environ.get("CONTAINER_PORT", "8080")
    app.run(debug=True, host="0.0.0.0", port=listen_port)

