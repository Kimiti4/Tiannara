# Quick Start: Testing Prometheus Metrics

## 🚀 Test the New Metrics System

### **Step 1: Start Backend**

```powershell
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic
python -m uvicorn tiannara_api.main:app --reload --port 8004
```

You should see:
```
✅ Prometheus metrics initialized
✅ Metrics collection enabled at /metrics
✅ Admin user created in database: admin@tiannara.com / admin123
INFO:     Uvicorn running on http://127.0.0.1:8004
```

---

### **Step 2: Make Some Requests**

Open a new terminal and run:

```powershell
# Health check
curl http://localhost:8004/health

# Login (creates auth metrics)
curl -X POST http://localhost:8004/api/v1/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"admin@tiannara.com\",\"password\":\"admin123\"}"

# Get user profile (creates API usage metrics)
curl http://localhost:8004/api/v1/auth/me ^
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

### **Step 3: View Metrics**

#### **Option A: Browser**
Open: `http://localhost:8004/metrics`

You'll see raw Prometheus metrics in text format.

#### **Option B: Command Line**
```powershell
curl http://localhost:8004/metrics
```

#### **Option C: PowerShell with Formatting**
```powershell
$response = Invoke-WebRequest -Uri "http://localhost:8004/metrics"
$response.Content | Select-String "http_requests_total"
```

---

### **Step 4: Verify Specific Metrics**

#### **HTTP Request Counts**
```powershell
curl http://localhost:8004/metrics | Select-String "http_requests_total"
```

Expected output:
```prometheus
http_requests_total{method="GET",endpoint="/health",status="200"} 5.0
http_requests_total{method="POST",endpoint="/api/v1/auth/login",status="200"} 1.0
```

#### **System CPU Usage**
```powershell
curl http://localhost:8004/metrics | Select-String "system_cpu_usage"
```

Expected output:
```prometheus
system_cpu_usage_percent 12.5
```

#### **Memory Usage**
```powershell
curl http://localhost:8004/metrics | Select-String "system_memory_usage"
```

Expected output:
```prometheus
system_memory_usage_bytes{type="used"} 8589934592.0
system_memory_usage_bytes{type="available"} 7516192768.0
system_memory_usage_bytes{type="total"} 16106127360.0
```

---

### **Step 5: Run Automated Tests**

```powershell
pytest tests/test_prometheus_metrics.py -v
```

Expected output:
```
tests/test_prometheus_metrics.py::test_metrics_endpoint_exists PASSED
tests/test_prometheus_metrics.py::test_health_endpoint PASSED
tests/test_prometheus_metrics.py::test_metrics_collect_request_data PASSED
tests/test_prometheus_metrics.py::test_system_metrics_present PASSED

========================= 4 passed in 0.5s =========================
```

---

## 📊 Understanding the Metrics Output

### **Metric Format**

Prometheus metrics follow this format:

```prometheus
# HELP metric_name Description of what this metric measures
# TYPE metric_name counter|gauge|histogram
metric_name{label1="value1",label2="value2"} 123.456
```

### **Example Breakdown**

```prometheus
# HELP http_requests_total Total HTTP requests received
# TYPE http_requests_total counter
http_requests_total{method="GET",endpoint="/health",status="200"} 5.0
```

- **Name**: `http_requests_total`
- **Type**: Counter (always increases)
- **Labels**: 
  - `method="GET"` - HTTP method
  - `endpoint="/health"` - API path
  - `status="200"` - Response status code
- **Value**: `5.0` - Number of requests matching these labels

---

## 🔍 Common Queries

### **Count all requests by endpoint**
```prometheus
sum by (endpoint) (http_requests_total)
```

### **Average request latency**
```prometheus
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])
```

### **Error rate percentage**
```prometheus
(sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) * 100
```

### **Active users right now**
```prometheus
active_users
```

---

## 🎯 What to Look For

### **✅ Good Signs**
- Metrics endpoint returns data (not 404)
- Request counts increase as you make requests
- System metrics show reasonable values
- No errors in backend logs

### **❌ Problems**
- `/metrics` returns 404 → Check middleware is added
- Empty response → Check prometheus-client is installed
- Stale values → Refresh the page (metrics update on scrape)
- High latency → Check histogram buckets are appropriate

---

## 🛠️ Troubleshooting

### **Issue: ModuleNotFoundError: No module named 'prometheus_client'**

**Solution**:
```powershell
pip install prometheus-client
```

Or reinstall from requirements:
```powershell
pip install -r requirements-production.txt
```

---

### **Issue: Metrics not updating**

**Cause**: Metrics only update when scraped or when events occur.

**Solution**:
1. Make more requests to generate data
2. Refresh `/metrics` page
3. Check backend logs for errors

---

### **Issue: Too many metrics lines**

**Cause**: Many endpoints + many label combinations = lots of metrics.

**Solution**: This is normal! Use grep/filter to find specific metrics:
```powershell
curl http://localhost:8004/metrics | Select-String "cpu"
```

---

## 📈 Next Steps

Now that metrics are working, tomorrow we'll:

1. **Install Prometheus Server** - Persistent storage and querying
2. **Set Up Grafana** - Beautiful dashboards
3. **Configure Alerts** - Get notified of issues
4. **Add to Docker Compose** - One-command monitoring stack

---

## 💡 Pro Tips

1. **Bookmark** `http://localhost:8004/metrics` for quick checks
2. **Use browser extensions** like "Prometheus Query" for better visualization
3. **Save common queries** in a text file for reuse
4. **Monitor memory usage** - too many metrics can consume RAM
5. **Check cardinality** - avoid high-cardinality labels (user IDs, timestamps)

---

**Ready for Day 2!** 🚀
