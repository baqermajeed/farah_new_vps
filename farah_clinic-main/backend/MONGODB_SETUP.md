# إعداد MongoDB - دليل سريع

## المشكلة الحالية
```
pymongo.errors.OperationFailure: Command find requires authentication
```

هذا يعني أن MongoDB يتطلب مصادقة للوصول إلى قاعدة البيانات.

## الحلول

### الحل الأول: تشغيل MongoDB بدون مصادقة (للتطوير)

1. **إيقاف MongoDB الحالي**:
```bash
# Windows
net stop MongoDB

# أو إذا كان يعمل كخدمة
sc stop MongoDB
```

2. **تشغيل MongoDB بدون مصادقة**:
```bash
# انتقل إلى مجلد MongoDB
cd "C:\Program Files\MongoDB\Server\7.0\bin"

# تشغيل بدون مصادقة
mongod --dbpath "C:\data\db" --noauth
```

### الحل الثاني: إعداد مصادقة MongoDB

1. **تشغيل MongoDB**:
```bash
mongod --dbpath "C:\data\db"
```

2. **إنشاء مستخدم مدير**:
```bash
# في terminal جديد
mongo

# في MongoDB shell
use admin
db.createUser({
  user: "admin",
  pwd: "password",
  roles: ["userAdminAnyDatabase", "dbAdminAnyDatabase", "readWriteAnyDatabase"]
})
```

3. **تحديث متغير البيئة**:
```bash
set MONGODB_URL=mongodb://admin:password@localhost:27017
```

### الحل الثالث: استخدام MongoDB Atlas (السحابي)

1. **إنشاء حساب في MongoDB Atlas**
2. **إنشاء cluster جديد**
3. **الحصول على connection string**
4. **تحديث متغير البيئة**:
```bash
set MONGODB_URL=mongodb+srv://username:password@cluster.mongodb.net/
```

## اختبار الاتصال

بعد إعداد MongoDB، اختبر الاتصال:

```bash
cd backend
python setup_database.py
```

## تشغيل التطبيق

```bash
cd backend
python -m uvicorn main:app --reload
```

## استكشاف الأخطاء

### خطأ: "MongoDB service not found"
```bash
# تثبيت MongoDB كخدمة
mongod --install --serviceName "MongoDB" --dbpath "C:\data\db"
```

### خطأ: "Access denied"
- تأكد من تشغيل Command Prompt كمدير
- تحقق من صلاحيات المجلد `C:\data\db`

### خطأ: "Port 27017 already in use"
```bash
# العثور على العملية التي تستخدم المنفذ
netstat -ano | findstr :27017

# إنهاء العملية
taskkill /PID <PID_NUMBER> /F
```

## نصائح إضافية

1. **للتطوير**: استخدم MongoDB بدون مصادقة
2. **للإنتاج**: استخدم مصادقة قوية
3. **النسخ الاحتياطي**: قم بعمل نسخ احتياطية دورية
4. **المراقبة**: راقب أداء قاعدة البيانات

## الدعم

إذا استمرت المشكلة، تحقق من:
- إصدار MongoDB
- إعدادات الشبكة
- جدار الحماية
- سجلات MongoDB
