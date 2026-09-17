# Quick Start: Monitoring Stack (Prometheus + Grafana)

## 🚀 One-Command Setup

### **Start Everything**

```powershell
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic
docker-compose up -d
```

This starts:
- ✅ Tiannara API (port 8000)
- ✅ PostgreSQL Database (port 5432)
- ✅ Redis Cache (port 6379)
- ✅ **Prometheus** (port 9090) ← NEW!
- ✅ **Grafana** (port 3001) ← NEW!

---

## 📊 Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3001 | admin / admin |
| **Prometheus** | http://localhost:9090 | No auth |
| **Tiannara API** | http://localhost:8000 | N/A |
| **API Metrics** | http://localhost:8000/metrics | N/A |

---

## 🎯 First Steps in Grafana

### **1. Login**
- Go to: http://localhost:3001
- Username: `admin`
- Password: `admin`
- Change password when prompted

### **2. View Dashboards**
Dashboards are auto-loaded! Look for folder: **"Tiannara Monitoring"**

Three dashboards available:
1. **System Overview** - CPU, memory, disk, users
2. **API Performance** - Requests, latency, errors
3. **Business Metrics** - Predictions, engines, quotas

### **3. Explore Data**
- Click on any panel to see full-screen view
- Adjust time range (top right): Last 1h, 6h, 24h, etc.
- Refresh rate: Auto-refreshes every 10s

---

## 🔍 Checking Prometheus

### **View Targets**
Go to: http://localhost:9090/targets

You should see:
- ✅ `tiannara-api` - Status: UP
- ✅ `prometheus` - Status: UP

### **Run Queries**
Go to: http://localhost:9090/graph

Try these queries:

#### Current CPU Usage
```promql
system_cpu_usage_percent
```

#### Request Rate (last 5 minutes)
```promql
sum(rate(http_requests_total[5m]))
```

#### Error Rate Percentage
```promql
(sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) * 100
```

#### Active Users
```promql
active_users
```

---

## 🧪 Generate Some Traffic

To see metrics in action, make some API requests:

### **Health Check**
```powershell
curl http://localhost:8000/health
```

### **Login**
```powershell
curl -X POST http://localhost:8000/api/v1/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"admin@tiannara.com\",\"password\":\"admin123\"}"
```

### **View Metrics**
```powershell
curl http://localhost:8000/metrics
```

---

## 📈 Dashboard Walkthrough

### **System Overview Dashboard**

**What it shows**:
- Real-time CPU usage (gauge)
- Memory usage over time (graph)
- Disk space percentage
- Process uptime
- Active user count
- Running domain engines

**Use when**: Monitoring server health and resource utilization

---

### **API Performance Dashboard**

**What it shows**:
- Total request count
- Requests per second (RPS)
- Error rate with color coding
- Average and p95 latency
- Breakdown by endpoint
- HTTP status code distribution
- Authentication success/failure rates

**Use when**: Debugging API performance issues or tracking usage

---

### **Business Metrics Dashboard**

**What it shows**:
- Total predictions made
- Prediction success rate
- Average confidence scores
- Predictions by domain (algorithm, logic, causal, etc.)
- Confidence distribution heatmap
- API calls by user tier
- Cache hit/miss ratios
- User quota utilization

**Use when**: Tracking ML model performance and business KPIs

---

## ⚠️ Troubleshooting

### **Issue: Grafana shows "No data"**

**Cause**: Prometheus hasn't scraped metrics yet or API isn't running

**Solution**:
1. Check API is running: `docker-compose ps`
2. Check Prometheus targets: http://localhost:9090/targets
3. Wait 30 seconds for first scrape
4. Make some API requests to generate data

---

### **Issue: Can't connect to Grafana**

**Check**:
```powershell
docker-compose ps grafana
```

Should show: `Up` status

If not:
```powershell
docker-compose logs grafana
docker-compose restart grafana
```

---

### **Issue: Prometheus target is DOWN**

**Check API metrics endpoint**:
```powershell
curl http://localhost:8000/metrics
```

Should return metric data. If not:
1. Check API container logs: `docker-compose logs api`
2. Verify port mapping: API should be on port 8000
3. Update `prometheus.yml` target if using different port

---

### **Issue: Dashboards not loading**

**Check provisioning**:
```powershell
docker-compose exec grafana ls /var/lib/grafana/dashboards
```

Should show 3 JSON files. If empty:
1. Check volume mounts in docker-compose.yml
2. Restart Grafana: `docker-compose restart grafana`
3. Check logs: `docker-compose logs grafana`

---

## 🛑 Stopping the Stack

### **Stop All Services**
```powershell
docker-compose down
```

### **Stop Only Monitoring**
```powershell
docker-compose stop prometheus grafana
```

### **Remove Everything (including data)**
```powershell
docker-compose down -v
```
⚠️ **Warning**: This deletes all metrics and dashboard data!

---

## 💡 Pro Tips

### **Customize Refresh Rate**
In Grafana dashboard:
1. Click gear icon (settings)
2. Go to "Settings" → "General"
3. Change "Auto-refresh" interval

### **Export Dashboard**
1. Click share icon (top right)
2. Select "Export" tab
3. Download as JSON

### **Create Custom Alert**
1. Go to Alerting → Contact Points
2. Add notification channel (email, Slack, etc.)
3. Create alert rule from any panel

### **Query Builder**
In Prometheus UI:
1. Use autocomplete (Ctrl+Space)
2. Click "Add Graph" to visualize
3. Save useful queries

---

## 📚 Useful Resources

- **Prometheus Docs**: https://prometheus.io/docs/
- **Grafana Docs**: https://grafana.com/docs/
- **PromQL Tutorial**: https://prometheus.io/docs/prometheus/latest/querying/basics/
- **Grafana Dashboards**: https://grafana.com/grafana/dashboards

---

## 🎯 Next Steps

Now that monitoring is set up:

1. ✅ **Explore dashboards** - Familiarize yourself with the data
2. ✅ **Set up alerts** - Configure notifications for critical issues
3. ✅ **Customize views** - Modify panels to show what matters to you
4. ✅ **Monitor production** - Deploy and track real usage

---

**Happy Monitoring!** 🚀📊
