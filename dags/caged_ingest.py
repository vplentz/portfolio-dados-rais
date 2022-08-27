from airflow import models
from airflow.decorators import task
from datetime import datetime
from airflow.models import Variable
from airflow.providers.google.cloud.operators.kubernetes_engine import (
    GKECreateClusterOperator,
    GKEDeleteClusterOperator,
    GKEStartPodOperator,
)
from kubernetes.client import models as k8s

with models.DAG(
    "caged_ingest",
    schedule_interval="@monthly",
    start_date=datetime(2019, 1, 1),
    end_date=datetime(2019, 12, 1),
    max_active_runs=1,
    catchup=True,
) as dag:
   
    file_path = "/pdet/microdados/CAGED/{{ macros.ds_format(ds, '%Y-%m-%d', '%Y') }}/CAGEDEST_{{ macros.ds_format(ds, '%Y-%m-%d', '%m%Y') }}.7z"
    
    CLUSTER_NAME = "extract-cluster-{{ ts_nodash.lower() }}"

    CLUSTER = {"name": CLUSTER_NAME, "initial_node_count": 1}

    GCP_PROJECT_ID = Variable.get("GCP_PROJECT_ID")

    GCP_LOCATION = "us-east1"

    GCP_CONN_ID="GCP_IAM"

    create_cluster_task = GKECreateClusterOperator(
        task_id="create_cluster",
        project_id=GCP_PROJECT_ID,
        location=GCP_LOCATION,
        body=CLUSTER,
        gcp_conn_id=GCP_CONN_ID
    )


    # extract_task = GKEStartPodOperator(
    #     task_id="extract_task",
    #     cluster_name=CLUSTER_NAME,
    #     image="google/cloud-sdk",
    #     name="extract_pod",
    #     random_name_suffix=True,
    #     volumes=[k8s.V1Volume(
    #         secret=k8s.V1SecretVolumeSource(
    #             secret_name="volume-prod",
    #             items=[
    #                 k8s.V1KeyToPath(key="config", path="config.json"),
    #             ],
    #         )
    #     )], 
    #     cmds=["/extract.sh -f pdet/microdados/CAGED/CAGEDEST_layout_Atualizado.xls -b vplentz-dl-dev"],
    #     location=GCP_LOCATIONM
    #     project_id=GCP_PROJECT_ID,
    #     gcp_conn_id=GCP_CONN_ID,
    #     regional=True,

    )

    delete_cluster_task = GKEDeleteClusterOperator(
        task_id="delete_cluster",
        name=CLUSTER_NAME,
        project_id=GCP_PROJECT_ID,
        location=GCP_LOCATION,
        gcp_conn_id=GCP_CONN_ID
    )
    create_cluster_task >> delete_cluster_task