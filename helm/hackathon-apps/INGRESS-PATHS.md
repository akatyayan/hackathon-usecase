# How Ingress Paths Work (No Application Code Changes)

## Yes, paths are defined in the Ingress

The **Ingress** defines which URL path goes to which Kubernetes Service. You do **not** define these paths in the application.

In **`values.yaml`** the paths are defined here:

```yaml
ingress:
  hosts:
    - host: ""
      paths:
        - path: /application
          pathType: Prefix
          service: application-service
        - path: /patient
          pathType: Prefix
          service: patient-service
        - path: /order
          pathType: Prefix
          service: order-service
```

So:

- Requests to **`http://<IP>/application`** (and `/application/...`) → **application-service**
- Requests to **`http://<IP>/patient`** (and `/patient/...`) → **patient-service**
- Requests to **`http://<IP>/order`** (and `/order/...`) → **order-service**

The Ingress **routes by path** to the right Service. The application does not need to “define” the path; the Ingress does.

---

## What the backend receives

By default (GCE Ingress):

- Request: `GET http://<IP>/application/health`  
  → Ingress sends the **full path** `/application/health` to **application-service**.
- Your app only has a route for `/health`, so it would return 404 for `/application/health`.

So you have two options **without changing application code**:

1. **Use Nginx Ingress with path rewrite** (recommended)  
   - Set `ingress.useNginxRewrite: true` and `ingress.className: "nginx"`.  
   - Install the [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/deploy/) on your cluster.  
   - The Ingress will rewrite the path so the backend receives `/health`, `/patients`, `/orders`, etc. (no prefix).

2. **Keep GCE Ingress (default)**  
   - Backend receives the full path (`/application/health`, `/patient/patients`, etc.).  
   - Your apps would need to handle those paths (e.g. base path in app). You said you don’t want app changes, so use option 1.

---

## Summary

| Question | Answer |
|--------|--------|
| Do we need to define path in the Ingress? | **Yes.** Paths are defined in the Ingress (`values.yaml` under `ingress.hosts[].paths`). |
| Where are they defined? | In **`helm/hackathon-apps/values.yaml`** (path, pathType, service). |
| Does the application define the path? | No. The Ingress maps URL path → Service. The app only defines its own routes (e.g. `/health`, `/patients`). |
| How do I avoid changing app code? | Use Nginx Ingress and set `ingress.useNginxRewrite: true` so the backend receives paths without the prefix. |
