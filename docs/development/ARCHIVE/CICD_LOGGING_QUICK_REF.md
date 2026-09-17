# Quick Reference: CI/CD & Logging

## 🚀 CI/CD Pipeline

### **Trigger Pipeline**

#### **Run Tests (on PR or push)**
```bash
git push origin feature-branch
# or create pull request
```

#### **Build Docker Image (on main push)**
```bash
git push origin main
```

#### **Create Release (on version tag)**
```bash
git tag v1.4.0
git push origin v1.4.0
```

---

### **View Pipeline Status**

**GitHub Actions**: https://github.com/{org}/Tiannara-MindCache-Prosthetic/actions

**Docker Images**: https://github.com/{org}/Tiannara-MindCache-Prosthetic/pkgs

---

### **Pipeline Stages**

1. **Test** - Run pytest on Python 3.10, 3.11, 3.12
2. **Lint** - Code quality checks (flake8, black, isort)
3. **Build** - Create Docker image with tags
4. **Deploy** - Push to staging environment
5. **Release** - Create GitHub release (on tags only)

---

### **Docker Image Tags**

| Git Event | Tag Format | Example |
|-----------|------------|---------|
| Push to main | `latest`, `main` | `ghcr.io/org/repo:latest` |
| Commit SHA | `{branch}-{sha}` | `main-a1b2c3d` |
| Tag v1.2.3 | `1.2.3`, `1.2`, `latest` | `ghcr.io/org/repo:1.2.3` |

---

### **Pull Docker Image**

```bash
docker pull ghcr.io/{org}/tiannara-mindcache-prosthetic:latest
docker run -p 8000:8000 ghcr.io/{org}/tiannara-mindcache-prosthetic:latest
```

---

## 📝 Structured Logging

### **Log Format**

All logs are JSON:

```json
{
  "timestamp": "2026-04-30T12:34:56.789Z",
  "level": "INFO",
  "logger": "tiannara.api",
  "message": "Request completed: GET /health",
  "correlation_id": "a1b2c3d4-e5f6-...",
  "request": {"method": "GET", "path": "/health"},
  "duration_ms": 12.45
}
```

---

### **Configure Logging**

**Environment Variables**:
```bash
LOG_LEVEL=DEBUG        # DEBUG, INFO, WARNING, ERROR, CRITICAL
LOG_FILE=logs/app.log  # Path to log file
```

**In Code**:
```python
from tiannara_api.logging_config import setup_logging, get_logger

# Setup logging
logger = setup_logging(level="INFO", log_file="logs/tiannara.log")

# Get logger with correlation ID
correlation_id = "abc123"
logger = get_logger("my_module", correlation_id=correlation_id)

# Log messages
logger.info("User logged in")
logger.error("Database connection failed", exc_info=True)
```

---

### **Correlation IDs**

**Automatic** (via middleware):
- Every HTTP request gets a unique UUID
- Added to response header: `X-Correlation-ID`
- Included in all log entries for that request

**Manual**:
```python
from tiannara_api.logging_config import get_correlation_id

correlation_id = get_correlation_id()  # Generate new UUID
logger = get_logger("my_module", correlation_id)
```

---

### **Search Logs**

#### **Find all logs for a request**
```bash
grep "a1b2c3d4-e5f6-..." logs/tiannara.log
```

#### **Find errors**
```bash
grep '"level": "ERROR"' logs/tiannara.log
```

#### **Find slow requests (>100ms)**
```bash
cat logs/tiannara.log | jq 'select(.duration_ms > 100)'
```

---

### **Log Aggregation Tools**

Compatible with:
- ✅ ELK Stack (Elasticsearch, Logstash, Kibana)
- ✅ Datadog
- ✅ Splunk
- ✅ Grafana Loki
- ✅ AWS CloudWatch Logs
- ✅ Google Cloud Logging

---

## 🔍 Troubleshooting

### **CI/CD Issues**

#### **Tests Failing**
```bash
# Run tests locally
pytest tests/ -v

# Check coverage
pytest --cov=tiannara_api --cov-report=term-missing
```

#### **Docker Build Failing**
```bash
# Build locally
docker build -f Dockerfile.production -t tiannara:test .

# Check for errors
docker build --no-cache -f Dockerfile.production -t tiannara:test .
```

#### **Deployment Failing**
Check GitHub Actions logs for error messages.
Verify staging server is accessible.
Check environment secrets are configured.

---

### **Logging Issues**

#### **No Logs Appearing**
```bash
# Check log level
echo $LOG_LEVEL  # Should be INFO or lower

# Check file permissions
ls -la logs/
chmod 755 logs/
```

#### **Logs Not JSON Formatted**
Ensure `LoggingMiddleware` is added to FastAPI app:
```python
from tiannara_api.logging_config import LoggingMiddleware
app.add_middleware(LoggingMiddleware)
```

#### **Missing Correlation IDs**
Check middleware is running:
```python
# In main.py
app.add_middleware(LoggingMiddleware)  # Must be before other middleware
```

---

## 💡 Pro Tips

### **CI/CD**

1. **Speed up builds**: Use Docker layer caching (already configured)
2. **Parallel tests**: Matrix strategy runs tests concurrently
3. **Skip unnecessary jobs**: Use `if` conditions
4. **Cache dependencies**: pip cache saves ~2 minutes per run

### **Logging**

1. **Use appropriate levels**: Don't log everything as INFO
2. **Include context**: Add relevant data to `extra` dict
3. **Rotate logs**: Prevents disk exhaustion
4. **Search by correlation ID**: Trace full request flow
5. **Monitor log volume**: High traffic = high costs with aggregation services

---

## 📚 Resources

- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Docker Best Practices**: https://docs.docker.com/develop/dev-best-practices/
- **Python Logging**: https://docs.python.org/3/library/logging.html
- **Structured Logging**: https://www.datadoghq.com/blog/python-logging/

---

**Happy Deploying & Debugging!** 🚀📊
