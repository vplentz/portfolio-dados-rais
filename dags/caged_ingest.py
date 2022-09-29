from airflow import models
from airflow.decorators import task
from datetime import datetime
from airflow.models import Variable
from airflow.providers.google.cloud.operators.kubernetes_engine import (
    GKECreateClusterOperator,
    GKEDeleteClusterOperator,
    GKEStartPodOperator,
)
from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import KubernetesPodOperator

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


    extract_task = GKEStartPodOperator(
        task_id="extract_task",
        cluster_name=CLUSTER_NAME,
        image="us-east1-docker.pkg.dev/caged-rais-vplentz/caged-rais-docker-repo/extractor_gsutil:tag1",
        name="extract_pod",
        random_name_suffix=True,
        cmds=["./extract.sh -f pdet/microdados/CAGED/CAGEDEST_layout_Atualizado.xls -b vplentz-dl-dev"],
        location=GCP_LOCATION,
        project_id=GCP_PROJECT_ID,
        gcp_conn_id=GCP_CONN_ID,    
        regional=True,
    )
    k = KubernetesPodOperator(
        task_id="extract_task_k8",
        name="extract_task_k8",
        image="us-east1-docker.pkg.dev/caged-rais-vplentz/caged-rais-docker-repo/extractor_gsutil:tag1",
        cmds=["./extract.sh -f pdet/microdados/CAGED/CAGEDEST_layout_Atualizado.xls -b vplentz-dl-dev"],
        config_file="extractor/kubeconfig.yaml"
    )
    delete_cluster_task = GKEDeleteClusterOperator(
        task_id="delete_cluster",
        name=CLUSTER_NAME,
        project_id=GCP_PROJECT_ID,
        location=GCP_LOCATION,
        gcp_conn_id=GCP_CONN_ID
    )
    create_cluster_task >> extract_task >> delete_cluster_task