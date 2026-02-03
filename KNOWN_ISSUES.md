# Known Issues - Observability Homepage

This document records known issues and design decisions for the consolidated Pigsty Observability Homepage.

## 1. Dashboard Merging & Grid Positioning
- **Status**: Fixed
- **Issue**: Merging multiple source dashboards (`pigsty.json`, `node.json`, `k8s.json`) into one `homepage.json` originally caused panels to stack vertically regardless of their horizontal layout.
- **Resolution**: `merge_dashboards.py` was updated to preserve the relative vertical and horizontal positioning within each newly created section (Infra Overview, Node, K8S Cluster).

## 2. Variable Name Unification
- **Status**: Fixed (Workaround)
- **Issue**: The consolidated dashboard uses a unified variable set (`$hostname`, `$node`, etc.), but source queries in the Node dashboard expected `$name` and `$instance`.
- **Resolution**: `merge_dashboards.py` performs a global regex replacement on the Node dashboard's JSON content before merging to align variable names.

## 3. External Links in Dashlists
- **Status**: Manual Override
- **Issue**: Grafana `dashlist` panels only show internal dashboards with specific tags. They do not support external URL links (like the Insight Workbench).
- **Resolution**: The "Apps" dashlist panel was replaced with a `text` panel using HTML to provide a direct link to `https://observability.svc.plus/insight/`.

## 4. Root Path Redirection
- **Status**: Fixed
- **Issue**: Users visiting `observability.svc.plus/` were previously directed elsewhere (defaults in Caddyfile).
- **Resolution**: Updated `Caddyfile` templates to redirect `/` (root) and `/zh` directly to `/grafana/`.

## 5. Panel UID Scaling
- **Status**: Potential Issue
- **Issue**: Panel IDs are re-assigned sequentially (1, 2, 3...) during merging. This might break internal dashboard persistence if panels are re-added or deleted frequently.
- **Recommendation**: Avoid frequent re-merging if persistent panel links are required.
