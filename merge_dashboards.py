import json
import re
import os

def merge_dashboards():
    # Paths to source dashboards
    pig_path = 'files/grafana/pigsty.json'
    node_path = 'files/grafana/node.json'
    k8s_path = 'files/grafana/k8s.json'
    output_path = 'files/grafana/homepage.json'

    # Read raw contents
    with open(pig_path, 'r') as f:
        pig_raw = f.read()
    with open(node_path, 'r') as f:
        node_raw = f.read()
    with open(k8s_path, 'r') as f:
        k8s_raw = f.read()

    # Perform fixed variable mapping for node.json
    # $name -> $hostname, $instance -> $node, $show_name -> $show_hostname
    node_raw = re.sub(r'\$name\b', '$hostname', node_raw)
    node_raw = re.sub(r'\$\{name\}', '${hostname}', node_raw)
    node_raw = re.sub(r'\$instance\b', '$node', node_raw)
    node_raw = re.sub(r'\$\{instance\}', '${node}', node_raw)
    node_raw = re.sub(r'\$show_name\b', '$show_hostname', node_raw)
    node_raw = re.sub(r'\$\{show_name\}', '${show_hostname}', node_raw)

    pig = json.loads(pig_raw)
    node = json.loads(node_raw)
    k8s = json.loads(k8s_raw)

    # Base dashboard
    homepage = {
        "annotations": pig.get("annotations", {"list": []}),
        "description": "Pigsty Consolidated Homepage",
        "editable": True,
        "graphTooltip": 0,
        "id": None,
        "links": pig.get("links", []),
        "panels": [],
        "schemaVersion": 39,
        "tags": ["HOME", "Pigsty"],
        "templating": {"list": []},
        "time": pig.get("time", {"from": "now-1h", "to": "now"}),
        "timepicker": pig.get("timepicker", {}),
        "timezone": "browser",
        "title": "Homepage",
        "uid": "home",
        "version": 1
    }

    # Unified Variables
    unified_vars = [
        {"name": "version", "type": "constant", "query": "v4.0.0", "hide": 2},
        {"name": "origin_prometheus", "label": "数据源", "type": "query", "datasource": {"uid": "ds-prometheus"}, "query": "label_values(kube_node_info,origin_prometheus)", "refresh": 1},
        {"name": "Node", "label": "节点", "type": "query", "datasource": {"uid": "ds-prometheus"}, "query": "label_values(kube_node_info{origin_prometheus=~\"$origin_prometheus\"},node)"},
        {"name": "NameSpace", "label": "命名空间", "type": "query", "datasource": {"uid": "ds-prometheus"}, "query": "label_values(kube_namespace_created{origin_prometheus=~\"$origin_prometheus\"},namespace)"},
        {"name": "Container", "label": "微服务(容器名)", "type": "query", "datasource": {"uid": "ds-prometheus"}, "query": "label_values(kube_pod_container_info{origin_prometheus=~\"$origin_prometheus\",namespace=~\"$NameSpace\"},container)"},
        {"name": "Pod", "label": "Pod", "type": "query", "datasource": {"uid": "ds-prometheus"}, "query": "label_values(kube_pod_container_info{origin_prometheus=~\"$origin_prometheus\",namespace=~\"$NameSpace\",container=~\"$Container\"},pod)"},
        {"name": "job", "label": "JOB", "type": "query", "datasource": {"uid": "ds-prometheus"}, "query": "label_values(node_uname_info{origin_prometheus=~\"$origin_prometheus\"},job)"},
        {"name": "hostname", "label": "名称", "type": "query", "datasource": {"uid": "ds-prometheus"}, "query": "label_values(node_uname_info{origin_prometheus=~\"$origin_prometheus\", job=~\"$job\"},nodename)"},
        {"name": "node", "label": "IP", "type": "query", "datasource": {"uid": "ds-prometheus"}, "query": "label_values(node_uname_info{origin_prometheus=~\"$origin_prometheus\", job=~\"$job\", nodename=~\"$hostname\"},instance)"},
        {"name": "device", "label": "网卡", "type": "query", "datasource": {"uid": "ds-prometheus"}, "query": "label_values(node_network_info{origin_prometheus=~\"$origin_prometheus\", job=~\"$job\", instance=~\"$node\", device!~\"'tap.*|veth.*|br.*|docker.*|virbr.*|lo.*|cni.*'\"},device)"},
        {"name": "interval", "label": "间隔", "type": "interval", "query": "3m,5m,10m,30m,1h,6h,12h,1d"},
        {"name": "maxmount", "hide": 2, "type": "query", "datasource": {"uid": "ds-prometheus"}, "query": "query_result(topk(1,sort_desc(max(node_filesystem_size_bytes{origin_prometheus=~\"$origin_prometheus\",instance=~\"$node\",fstype=~\"ext.?|xfs\",mountpoint!~\".*pods.*\"}) by (mountpoint))))"},
        {"name": "show_hostname", "hide": 2, "type": "query", "datasource": {"uid": "ds-prometheus"}, "query": "label_values(node_uname_info{origin_prometheus=~\"$origin_prometheus\", job=~\"$job\", nodename=~\"$hostname\", instance=~\"$node\"},nodename)"},
        {"name": "total", "hide": 2, "type": "query", "datasource": {"uid": "ds-prometheus"}, "query": "query_result(count(node_uname_info{origin_prometheus=~\"$origin_prometheus\",job=~\"$job\"}))"}
    ]
    homepage["templating"]["list"] = unified_vars

    current_y = 0
    # 1. Infra
    homepage["panels"].append({"collapsed": False, "gridPos": {"h": 1, "w": 24, "x": 0, "y": current_y}, "title": "Infra Overview", "type": "row", "panels": []})
    current_y += 1
    
    infra_max_y = current_y
    for p in pig.get("panels", []):
        if p.get("type") == "row": continue
        
        # Replace "Apps" panel with "insight Overview" link
        if p.get("title") == "Apps":
            p["title"] = "insight Overview"
            p["type"] = "text"
            p["options"] = {
                "content": "<div style='text-align: center; padding-top: 10px;'><a href='/insight/' style='font-size: 18px; color: #58a6ff; font-weight: bold;'>insight Overview</a></div>",
                "mode": "html"
            }
        
        p["gridPos"]["y"] += current_y
        homepage["panels"].append(p)
        infra_max_y = max(infra_max_y, p["gridPos"]["y"] + p["gridPos"]["h"])
    current_y = infra_max_y

    # 2. Node
    homepage["panels"].append({"collapsed": False, "gridPos": {"h": 1, "w": 24, "x": 0, "y": current_y}, "title": "Node", "type": "row", "panels": []})
    current_y += 1
    node_max_y = current_y
    for p in node.get("panels", []):
        p["gridPos"]["y"] += current_y
        homepage["panels"].append(p)
        node_max_y = max(node_max_y, p["gridPos"]["y"] + p["gridPos"]["h"])
    current_y = node_max_y

    # 3. K8S
    homepage["panels"].append({"collapsed": False, "gridPos": {"h": 1, "w": 24, "x": 0, "y": current_y}, "title": "K8S Cluster", "type": "row", "panels": []})
    current_y += 1
    k8s_max_y = current_y
    for p in k8s.get("panels", []):
        p["gridPos"]["y"] += current_y
        homepage["panels"].append(p)
        k8s_max_y = max(k8s_max_y, p["gridPos"]["y"] + p["gridPos"]["h"])
    current_y = k8s_max_y

    for i, p in enumerate(homepage["panels"]):
        p["id"] = i + 1

    with open(output_path, 'w') as f:
        json.dump(homepage, f, indent=2)

if __name__ == "__main__":
    merge_dashboards()
