import time

import yaml
from kubernetes import client, config, utils, watch


def apply_deployment(deployment: str):

    config.load_kube_config()
    k8s_client = client.ApiClient()
    yaml_objects = yaml.safe_load_all(deployment)
    return utils.create_from_yaml(k8s_client, yaml_objects=yaml_objects)


def wait_for_job_to_complete(name: str, namespace: str):
    config.load_kube_config()
    batchapi_client = client.BatchV1Api()
    w = watch.Watch()
    for event in w.stream(batchapi_client.list_namespaced_job, namespace=namespace):
        o: client.V1Job = event["object"]
        if (
            o.metadata.name == name
            and o.status.conditions
            and any(c.type == "Complete" for c in o.status.conditions)
        ):
            return


def wait_for_daemonset_to_be_available(
    name: str, namespace: str, tries: int = 18, sleep_time: float = 5.0
):
    config.load_kube_config()
    appsapi_client = client.AppsV1Api()
    while tries:
        d_status = appsapi_client.read_namespaced_daemon_set_status(name, namespace)
        if d_status.status.desired_number_scheduled == d_status.status.number_ready:
            return

        tries -= 1
        time.sleep(sleep_time)
    raise Exception("Daemonset Failed.")


def get_num_nodes() -> int:
    config.load_kube_config()
    core_api = client.CoreV1Api()
    return len(core_api.list_node().items)


def wait_for_cronjob_to_run(name: str, namespace: str):
    config.load_kube_config()
    batchapi_client = client.BatchV1beta1Api()
    w = watch.Watch()
    for event in w.stream(
        batchapi_client.list_namespaced_cron_job, namespace=namespace
    ):
        o: client.V1beta1CronJob = event["object"]
        if o.metadata.name == name and o.status.last_schedule_time is not None:
            return
