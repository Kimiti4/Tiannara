# Week 24 Quick Reference Card

**Phase**: Monitoring & DevOps  
**Duration**: 5 Days (April 30, 2026)  
**Status**: ✅ **COMPLETE**

---

## 🚀 One-Command Start

```bash
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic
docker-compose up -d
```

---

## 📊 Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| **Grafana** | http://localhost:3001 | Dashboards & alerts |
| **Prometheus** | http://localhost:9090 | Metrics query |
| **Tiannara API** | http://localhost:8000 | Main API |
| **API Metrics** | http://localhost:8000/metrics | Raw metrics |

**Grafana Login**: admin / admin

---

## 🎯 Key Features

### **Monitoring**
- ✅ 24 Prometheus metrics
- ✅ 3 Grafana dashboards
- ✅ 12 alert rules
- ✅ Real-time visualization

### **CI/CD**
- ✅ 5-stage pipeline
- ✅ Multi-version testing
- ✅ Docker builds
- ✅ Auto releases

### **Logging**
- ✅ JSON format
- ✅ Correlation IDs
- ✅ Performance timing
- ✅ Log rotation

### **Security**
- ✅ 9 security headers
- ✅ Input validation
- ✅ Rate limiting
- ✅ Auto banning

---

## 🔍 Common Queries

### **Check System Health**
```bash
curl http://localhost:8000/health
```

### **View Metrics**
```bash
curl http://localhost:8000/metrics
```

### **Test Rate Limiting**
```bash
for i in {1..7}; do
  curl -s -o /dev/null -w "%{http_code}" \
    http://localhost:8000/api/v1/auth/login \
    -d '{"email":"test@test.com","password":"wrong"}'
done
```

### **Check Security Headers**
```bash
curl -I http://localhost:8000/health
```

---

## 📁 Important Files

### **Monitoring**
- `monitoring/prometheus.yml` - Prometheus config
- `monitoring/alerts.yml` - Alert rules
- `monitoring/grafana/dashboards/*.json` - Dashboards

### **CI/CD**
- `.github/workflows/ci-cd.yml` - Pipeline definition

### **Security**
- `tiannara_api/middleware/security_headers.py`
- `tiannara_api/middleware/input_validation.py`
- `tiannara_api/middleware/enhanced_rate_limiter.py`

### **Logging**
- `tiannara_api/logging_config.py`

---

## 🛠️ Troubleshooting

### **Grafana Not Loading Dashboards?**
```bash
# Check provisioning logs
docker logs tiannara-grafana

# Restart Grafana
docker-compose restart grafana
```

### **Prometheus Not Scraping?**
```bash
# Check targets
curl http://localhost:9090/api/v1/targets

# Verify API is running
curl http://localhost:8000/metrics
```

### **Rate Limiter Blocking Legitimate Requests?**
```python
# Check client status
from tiannara_api.middleware.enhanced_rate_limiter import EnhancedRateLimiter
limiter.get_client_status("user:token_here")
```

---

## 📈 Metrics Cheat Sheet

### **HTTP Metrics**
```promql
# Requests per second
sum(rate(http_requests_total[1m]))

# Error rate percentage
(sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) * 100

# 95th percentile latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### **System Metrics**
```promql
# CPU usage
system_cpu_usage_percent

# Memory usage (MB)
system_memory_usage_bytes / 1024 / 1024

# Active users
active_users_gauge
```

### **Business Metrics**
```promql
# Total predictions
sum(predictions_total)

# Prediction success rate
(sum(predictions_total{success="True"}) / sum(predictions_total)) * 100

# Engine utilization
engine_utilization_percent
```

---

## 🔐 Security Checklist

- [x] Security headers configured
- [x] Input validation active
- [x] Rate limiting enabled
- [x] CORS configured
- [ ] JWT token rotation (TODO)
- [ ] Database encryption (TODO)
- [ ] 2FA implementation (TODO)

---

## 📚 Documentation Links

- [Week 24 Summary](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/WEEK24_SUMMARY.md)
- [Security Audit](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/SECURITY_AUDIT_CHECKLIST.md)
- [Monitoring Guide](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/MONITORING_QUICK_START.md)
- [Metrics Guide](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/METRICS_QUICK_START.md)
- [CI/CD Reference](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/CICD_LOGGING_QUICK_REF.md)

---

## 🎯 Next Steps

Choose your next phase:

1. **Mobile App** (Week 25-26)
   - React Native development
   - Push notifications
   - Offline support

2. **Enterprise Features** (Week 27-28)
   - SSO integration
   - Team collaboration
   - Advanced analytics

3. **API Marketplace** (Week 29-30)
   - Developer portal
   - SDK generation
   - Usage billing

---

**Quick Stats**: 1,726 lines code • 12 files created • 11 docs written • 8.5/10 security score 🏆
