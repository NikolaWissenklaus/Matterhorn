"""Backend de coleta do Matterhorn.

Recebe os eventos enviados pelo tracker (tracker/matterhorn.js), converte os
parâmetros para o formato do export do GA4 e grava cada evento como uma linha
no BigQuery.
"""

import json
import os

from flask import Flask, request
from flask_cors import CORS
from google.cloud import bigquery

app = Flask(__name__)

# Os eventos chegam de qualquer site com o tracker instalado, então o CORS
# fica aberto para todas as origens.
CORS(app)

bq_client = bigquery.Client()

# No Cloud Run essas variáveis são definidas pelo Terraform
# (infra/cloud_run.tf). Sem PROJECT_ID, vale o projeto das credenciais.
PROJECT_ID = os.environ.get("PROJECT_ID") or bq_client.project
DATASET_ID = os.environ.get("DATASET_ID", "matterhorn_dataset")
TABLE_ID = os.environ.get("TABLE_ID", "events_raw")
TABLE_REF = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"


def estruturar_params(params):
    """Converte {"chave": valor} na lista tipada do export do GA4.

    Cada valor ocupa uma única coluna, conforme o tipo:

        int          value.int_value
        float        value.double_value
        bool         value.string_value, como "true" ou "false" (igual ao GA4)
        dict, list   value.string_value, serializado em JSON
        None         nenhuma (as três colunas ficam nulas)
        outros       value.string_value

    Se params não for um dicionário, o evento segue sem parâmetros.
    """
    if not isinstance(params, dict):
        return []

    estruturados = []
    for chave, valor in params.items():
        coluna = {"string_value": None, "int_value": None, "double_value": None}

        # bool precisa ser testado antes de int: em Python, True é um int.
        if isinstance(valor, bool):
            coluna["string_value"] = str(valor).lower()
        elif isinstance(valor, int):
            coluna["int_value"] = valor
        elif isinstance(valor, float):
            coluna["double_value"] = valor
        elif isinstance(valor, (dict, list)):
            coluna["string_value"] = json.dumps(valor, ensure_ascii=False)
        elif valor is not None:
            coluna["string_value"] = str(valor)

        estruturados.append({"key": str(chave), "value": coluna})

    return estruturados


@app.route("/mhc", methods=["POST", "OPTIONS"])
def mhc():
    """Recebe um evento em JSON e grava no BigQuery."""
    # Preflight do navegador. Os cabeçalhos de CORS entram pelo flask-cors.
    if request.method == "OPTIONS":
        return "ok", 200

    # force=True lê o corpo como JSON mesmo sem Content-Type de JSON, o que
    # permite enviar com navigator.sendBeacon (que usa text/plain).
    evento = request.get_json(silent=True, force=True)
    if not isinstance(evento, dict) or not evento:
        return "bad request", 400

    evento["event_params"] = estruturar_params(evento.get("event_params"))

    # Streaming insert: a linha pode ser consultada segundos depois. Um campo
    # que não existe no esquema faz o BigQuery recusar o evento inteiro.
    errors = bq_client.insert_rows_json(TABLE_REF, [evento])
    if errors:
        print(f"Erro ao inserir no BigQuery: {errors}", flush=True)
        return "erro interno", 500

    print(f"Evento {evento.get('event_name')} salvo com sucesso!", flush=True)
    return "ok", 200


# Só para rodar localmente (python app.py). No Cloud Run quem sobe o app é o
# gunicorn, pelo CMD do Dockerfile.
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
