# 🚀 Quick Start Guide - PostgreSQL Integration

## What Just Happened?

Your Tiannara SaaS platform has been **successfully migrated** from temporary in-memory storage to **persistent PostgreSQL database**! 

### Key Benefits:
- ✅ Users now **persist across backend restarts**
- ✅ Production-ready database infrastructure
- ✅ 6 users already created (1 admin + 5 sample users)
- ✅ All authentication routes updated to use database

---

## 🎯 Next Steps (Do This Now!)

### **Step 1: Restart Backend** ⚡

Open PowerShell and run:

```powershell
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic
python -m uvicorn tiannara_api.main:app --reload --port 8004
```

You should see:
```
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8004
```

---

### **Step 2: Login as Admin** 🔐

1. Open browser: `http://localhost:3000/login`
2. Enter credentials:
   - **Email:** `admin@tiannara.com`
   - **Password:** `admin123`
3. Click "Login"

✅ You should be redirected to the dashboard!

---

### **Step 3: Check Admin Panel** 👥

1. Navigate to: **Admin Dashboard → Users**
2. You should see **6 users** listed:
   - 1 Admin (you)
   - 5 Sample users

Try these features:
- 🔍 Search by email or name
- 📊 Filter by tier (starter/professional/enterprise)
- 📄 Pagination controls

---

### **Step 4: Test Persistence** 💾

**This is the important part!**

1. **Stop the backend** (Ctrl+C in terminal)
2. **Restart it again:**
   ```powershell
   python -m uvicorn tiannara_api.main:app --reload --port 8004
   ```
3. **Login again** with admin credentials
4. **Check users** - They should still be there! 🎉

**Before migration:** Users would disappear after restart ❌  
**After migration:** Users persist permanently ✅

---

## 📋 User Credentials Reference

### **Admin Account**
- Email: `admin@tiannara.com`
- Password: `admin123`
- Tier: Enterprise
- ⚠️ **Change password immediately!**

---

### **Sample Users** (all use `password123`)

| Email | Name | Tier |
|-------|------|------|
| sarah.johnson@techcorp.com | Sarah Johnson | Enterprise |
| emily.rodriguez@startup.co | Emily Rodriguez | Professional |
| alex.martinez@freelance.com | Alex Martinez | Starter |
| michael.chen@innovate.io | Michael Chen | Professional |
| jessica.williams@dataflow.com | Jessica Williams | Starter |

---

## 🔧 Troubleshooting

### **Backend Won't Start**

**Error:** `could not connect to server`

**Solution:**
1. Ensure PostgreSQL is running:
   ```powershell
   Get-Service postgresql*
   ```
   
2. If not running, start it:
   ```powershell
   net start postgresql-x64-15
   ```

3. Verify connection:
   ```powershell
   psql -U postgres -d tiannara -c "SELECT 1"
   ```

---

### **Login Fails with 401 Error**

**Possible causes:**
1. Backend not running on port 8004
2. Wrong credentials
3. Database not initialized

**Solution:**
1. Check backend is running: Look for "Uvicorn running on http://127.0.0.1:8004"
2. Verify credentials match exactly (case-sensitive email)
3. Re-run migration if needed:
   ```powershell
   python migrate_to_postgresql.py
   ```

---

### **No Users Showing in Admin Panel**

**Check database directly:**
```powershell
psql -U postgres -d tiannara -c "SELECT count(*) FROM users;"
```

Should return: `6`

If 0, re-run migration script.

---

## 🗄️ Database Access

### **Connect via psql**
```powershell
psql -U postgres -d tiannara
```

### **Useful Queries**

**List all users:**
```sql
SELECT id, email, name, tier, is_admin, created_at 
FROM users 
ORDER BY created_at DESC;
```

**Count users by tier:**
```sql
SELECT tier, count(*) 
FROM users 
GROUP BY tier;
```

**Find admin users:**
```sql
SELECT email, name 
FROM users 
WHERE is_admin = true;
```

---

## 🔒 Security Checklist

### **Immediate Actions**
- [ ] Change admin password from default `admin123`
- [ ] Update `.env` file with secure JWT_SECRET_KEY
- [ ] Review database credentials (change if using defaults)

### **Production Recommendations**
- [ ] Use bcrypt instead of SHA-256 for password hashing
- [ ] Enable SSL/TLS for database connections
- [ ] Implement rate limiting on auth endpoints
- [ ] Add JWT token refresh mechanism
- [ ] Set up automated database backups
- [ ] Configure firewall rules for PostgreSQL

---

## 📊 Monitoring

### **Check Database Size**
```sql
SELECT pg_size_pretty(pg_database_size('tiannara'));
```

### **View Active Connections**
```sql
SELECT count(*) FROM pg_stat_activity WHERE datname = 'tiannara';
```

### **Monitor Query Performance**
```sql
SELECT query, mean_exec_time, calls 
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;
```

---

## 🎓 Learning Resources

### **PostgreSQL Documentation**
- Official Docs: https://www.postgresql.org/docs/
- SQL Tutorial: https://www.postgresqltutorial.com/

### **SQLAlchemy ORM**
- Docs: https://docs.sqlalchemy.org/
- Tutorial: https://docs.sqlalchemy.org/en/20/tutorial/

### **FastAPI Database Integration**
- Docs: https://fastapi.tiangolo.com/tutorial/sql-databases/

---

## ✅ Verification Checklist

Complete these to confirm everything works:

- [ ] Backend starts without errors on port 8004
- [ ] Can login as admin (`admin@tiannara.com` / `admin123`)
- [ ] Admin panel shows 6 users
- [ ] Can search/filter users in admin panel
- [ ] Users persist after backend restart
- [ ] Can register new user via signup page
- [ ] New user appears in database after verification
- [ ] Can login with newly registered user

---

## 🚨 Important Notes

### **Database Location**
- Host: `localhost`
- Port: `5432`
- Database: `tiannara`
- Username: `postgres`
- Password: `eYJPc922pkA2DFT` (from your setup)

### **Configuration File**
Database URL is configured in: `tiannara_api/database/__init__.py`

To customize, create `.env` file:
```env
DATABASE_URL=postgresql://your_user:your_password@localhost:5432/your_db
```

---

## 🎉 Success Indicators

You'll know everything is working when:

1. ✅ Backend logs show successful startup
2. ✅ Login succeeds without 401/500 errors
3. ✅ Admin panel displays user list
4. ✅ Users survive backend restarts
5. ✅ New registrations save to database

---

**Migration Date:** April 30, 2026  
**Status:** ✅ COMPLETE  
**Next:** Test all features and change admin password!
