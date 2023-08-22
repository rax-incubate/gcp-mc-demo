import os
import json
from flask import Flask, render_template
from google.cloud import bigquery


app = Flask(__name__, template_folder="static/templates")

@app.route("/run")

def hello_world():

    env = os.environ.get("ENV", "default")
    bq_dataset_id = os.environ.get("BQ_DATASET_ID", "5432")
    bq_table_id = os.environ.get("BQ_TABLE_ID", "imdb")

    my_env = "Environment:" + env

    client = bigquery.Client()
    query = f"SELECT continent, country.name as country_name, cb.array_element as city_name FROM {bq_dataset_id}.{bq_table_id}, UNNEST(country.city.bag) cb"
    query_job = client.query(query)
    query_rows = query_job.result()

    gen_html = ""
    for row in query_rows:
        gen_html = gen_html + "<tr><td>" + row["continent"] + "</td><td>" + row["country_name"] + "</td><td>" + row["city_name"] + "</td></tr>" + "\n"

    return render_template("list.html", env=my_env, content=gen_html)

if __name__ == "__main__":
    listen_port = os.environ.get("CONTAINER_PORT", "8080")
    app.run(debug=True, host="0.0.0.0", port=listen_port)


