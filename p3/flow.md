# 🧠 PART 3 — THE FULL PICTURE (REBUILT PROPERLY)

## 🎯 Goal of Part 3 (in one sentence)

> **Use Argo CD to automatically deploy and update an application in Kubernetes when the application definition in Git changes.**

That’s it.

---

# 🧩 The Actors (TOOLS) — Definitions FIRST

I’ll define each tool **the moment it appears in the flow**.

---

## 1️⃣ Docker (container runtime)

**Definition**
Docker packages an application **with everything it needs** (code + runtime + config) into an **image**.

You **do not write code** in Part 3.
You **consume existing images**.

Example:

```text
wil42/playground:v1
wil42/playground:v2
```

These images already contain:

* A small web server
* An HTTP endpoint `/`
* A response that changes between versions

👉 You are **not building images**, only **deploying them**.

---

## 2️⃣ Kubernetes (orchestration platform)

**Definition**
Kubernetes runs containers and keeps them alive according to a **desired state**.

You never say:

> “run this container”

You say:

> “I want 1 replica of this image, always”

Kubernetes enforces it.

---

## 3️⃣ Deployment (Kubernetes object)

**Definition**
A `Deployment` tells Kubernetes:

* Which **image** to run
* How many **replicas**
* How to **update** it

Example (from your config):

```yaml
image: wil42/playground:v1
```

This is the **heart of v1 → v2**.

---

## 4️⃣ Service (Kubernetes object)

**Definition**
A `Service` exposes Pods **inside the cluster**.

Your Service:

```yaml
port: 80
targetPort: 8888
```

Meaning:

```
client → service:80 → container:8888
```

---

## 5️⃣ Argo CD (GitOps controller)

**Definition**
Argo CD is a **controller** that:

* Watches a **Git repository**
* Compares Git with the cluster
* Forces the cluster to match Git

> Git becomes the **source of truth**

---

## 6️⃣ Application (Argo CD object)

**Definition**
An `Application` tells Argo CD:

* **Where** the Git repo is
* **Which folder** to read
* **Which namespace** to deploy into

Without this → Argo CD does nothing.

---

# 🔄 THE COMPLETE PART 3 FLOW (IMPORTANT)

Read this **slowly**, this is the key.

---

## 🟢 STEP 1 — install.sh (infrastructure)

What happens:

1. Docker installed
2. k3d creates Kubernetes
3. Argo CD installed in `argocd` namespace

❗ **No application is deployed yet**

At this point:

```bash
kubectl get pods -n dev
# empty
```

This is NORMAL.

---

## 🟢 STEP 2 — Application is applied

When you added:

```bash
kubectl apply -f p3/confs/config.yaml
```

You created this object:

```yaml
kind: Application
```

Now Argo CD wakes up and says:

> “Oh, I must sync Git with the cluster.”

---

## 🟢 STEP 3 — Argo CD reads Git

Argo CD:

1. Clones your GitHub repo
2. Goes to:

   ```
   p3/confs/
   ```
3. Reads `config.yaml`

Inside it:

* Deployment
* Service

---

## 🟢 STEP 4 — Kubernetes creates the app

From Git:

```yaml
image: wil42/playground:v1
```

Kubernetes now:

* Pulls the image
* Runs the container
* Exposes it via Service

Now:

```bash
kubectl get pods -n dev
# running
```

---

# 🔁 WHERE v1 → v2 REALLY HAPPENS (THIS IS IT)

You do **NOT** change code.
You do **NOT** rebuild images.

You change **ONE LINE IN GIT**:

```yaml
image: wil42/playground:v2
```

That’s it.

Then:

```bash
git commit
git push
```

Argo CD detects:

```
Git != cluster
```

And performs:

* Rolling update
* Pod restart
* Zero manual commands

THIS is GitOps.

---

# 🧪 Why you got `404 page not found`

Now let’s fix your concrete issue.

### Root cause

You forwarded:

```bash
kubectl port-forward svc/moouaamm -n dev 8888:80
```

But the container **listens on `/` on port 8888**,
and `wil42/playground` **does NOT serve arbitrary paths**.

Some versions respond on `/health` or `/`.

### Test correctly:

```bash
curl http://localhost:8888/
```

If still 404, inspect the pod logs:

```bash
kubectl logs -n dev -l app=moouaamm
```

You should see something like:

```
Listening on :8888
```

---

# ✅ Correct verification sequence (FINAL)

```bash
kubectl get applications -n argocd
kubectl get deploy -n dev
kubectl get pods -n dev
kubectl port-forward svc/moouaamm -n dev 8888:80
curl http://localhost:8888/
```

Expected (v1):

```json
{"status":"ok","message":"v1"}
```

Then update image → v2 → push → re-curl.

---

# 🧠 FINAL MENTAL MODEL (KEEP THIS)

```
Git ──► Argo CD ──► Kubernetes ──► Container
 ↑                                 ↓
 └──────────── Desired State ──────┘
```

You **never touch Kubernetes directly** after setup.
You **only touch Git**.

---


You’re very close — now it’s just **clarity**, not complexity.
