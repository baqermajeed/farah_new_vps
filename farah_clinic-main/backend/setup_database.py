#!/usr/bin/env python3
"""
سكريبت إعداد قاعدة البيانات
يساعد في إعداد MongoDB وإنشاء المستخدمين الافتراضيين
"""

import asyncio
import os
from motor.motor_asyncio import AsyncIOMotorClient
from services.auth_service import auth_service
from services.database import db_service


async def setup_database():
    """إعداد قاعدة البيانات"""
    print("🚀 بدء إعداد قاعدة البيانات...")
    
    try:
        # الاتصال بقاعدة البيانات
        await db_service.connect()
        
        # إنشاء المدير الافتراضي
        await auth_service.create_default_admin()
        
        print("✅ تم إعداد قاعدة البيانات بنجاح!")
        print("\n📋 بيانات تسجيل الدخول الافتراضية:")
        print("   اسم المستخدم: admin")
        print("   كلمة المرور: admin123")
        print("\n⚠️  تحذير: يجب تغيير كلمة المرور في الإنتاج!")
        
    except Exception as e:
        print(f"❌ خطأ في إعداد قاعدة البيانات: {e}")
        print("\n💡 حلول مقترحة:")
        print("1. تأكد من تشغيل MongoDB")
        print("2. تحقق من إعدادات المصادقة")
        print("3. جرب تشغيل MongoDB بدون مصادقة مؤقتاً")
        
    finally:
        await db_service.disconnect()


async def create_user_manually():
    """إنشاء مستخدم يدوياً"""
    print("\n👤 إنشاء مستخدم جديد:")
    
    try:
        await db_service.connect()
        
        username = input("اسم المستخدم: ")
        password = input("كلمة المرور: ")
        full_name = input("الاسم الكامل: ")
        email = input("البريد الإلكتروني (اختياري): ") or None
        is_admin = input("هل هو مدير؟ (y/n): ").lower() == 'y'
        
        user_data = {
            "username": username,
            "password": password,
            "full_name": full_name,
            "email": email,
            "is_admin": is_admin
        }
        
        from models.user import UserCreate
        user_create = UserCreate(**user_data)
        
        user = await auth_service.create_user(user_create)
        print(f"✅ تم إنشاء المستخدم '{username}' بنجاح!")
        
    except Exception as e:
        print(f"❌ خطأ في إنشاء المستخدم: {e}")
        
    finally:
        await db_service.disconnect()


def main():
    """الدالة الرئيسية"""
    print("🏥 إعداد نظام عيادة الدكتورة فرح الأسنان")
    print("=" * 50)
    
    while True:
        print("\nاختر عملية:")
        print("1. إعداد قاعدة البيانات")
        print("2. إنشاء مستخدم جديد")
        print("3. خروج")
        
        choice = input("\nاختيارك (1-3): ")
        
        if choice == "1":
            asyncio.run(setup_database())
        elif choice == "2":
            asyncio.run(create_user_manually())
        elif choice == "3":
            print("👋 وداعاً!")
            break
        else:
            print("❌ اختيار غير صحيح!")


if __name__ == "__main__":
    main()
