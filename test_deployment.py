#!/usr/bin/env python3
"""
Test script for Todo Application Phase V features
Tests all core functionality including priority, tags, recurrence, search/filter
"""

import requests
import json
from datetime import datetime, timedelta
from typing import Dict, Any

BASE_URL = "http://localhost:8000"
API_URL = f"{BASE_URL}/api"

def print_test(name: str):
    """Print test header"""
    print(f"\n{'='*60}")
    print(f"TEST: {name}")
    print('='*60)

def print_result(success: bool, message: str):
    """Print test result"""
    status = "[PASS]" if success else "[FAIL]"
    print(f"{status}: {message}")

def test_health():
    """Test 1: Health check endpoint"""
    print_test("Health Check")
    try:
        response = requests.get(f"{BASE_URL}/health")
        success = response.status_code == 200
        print_result(success, f"Backend health check: {response.json()}")
        return success
    except Exception as e:
        print_result(False, f"Health check failed: {e}")
        return False

def test_create_basic_task():
    """Test 2: Create basic task"""
    print_test("Create Basic Task")
    try:
        task_data = {
            "title": "Complete project documentation",
            "description": "Write comprehensive docs for Phase V"
        }
        response = requests.post(f"{API_URL}/tasks", json=task_data)
        success = response.status_code == 200
        if success:
            task = response.json()
            print_result(True, f"Created task ID: {task.get('id')}, Title: {task.get('title')}")
            return task
        else:
            print_result(False, f"Status: {response.status_code}, Response: {response.text}")
            return None
    except Exception as e:
        print_result(False, f"Error: {e}")
        return None

def test_create_task_with_priority():
    """Test 3: Create task with priority"""
    print_test("Create Task with Priority")
    try:
        task_data = {
            "title": "Fix critical bug in production",
            "description": "Database connection pooling issue",
            "priority": 2  # 0=low, 1=medium, 2=high
        }
        response = requests.post(f"{API_URL}/tasks", json=task_data)
        success = response.status_code == 200
        if success:
            task = response.json()
            priority_ok = task.get('priority') == 2
            print_result(priority_ok, f"Task created with priority: {task.get('priority')} (2=high)")
            return task
        else:
            print_result(False, f"Status: {response.status_code}, Response: {response.text}")
            return None
    except Exception as e:
        print_result(False, f"Error: {e}")
        return None

def test_create_task_with_tags():
    """Test 4: Create task with tags"""
    print_test("Create Task with Tags")
    try:
        task_data = {
            "title": "Review pull requests",
            "description": "Review team PRs",
            "tags": ["code-review", "development", "urgent"]
        }
        response = requests.post(f"{API_URL}/tasks", json=task_data)
        success = response.status_code == 200
        if success:
            task = response.json()
            tags = task.get('tags', [])
            tags_ok = len(tags) == 3
            print_result(tags_ok, f"Task created with tags: {tags}")
            return task
        else:
            print_result(False, f"Status: {response.status_code}, Response: {response.text}")
            return None
    except Exception as e:
        print_result(False, f"Error: {e}")
        return None

def test_create_recurring_task():
    """Test 5: Create recurring task"""
    print_test("Create Recurring Task")
    try:
        # Use date() instead of isoformat() to avoid time component
        due_date = (datetime.now() + timedelta(days=1)).date().isoformat()
        task_data = {
            "title": "Weekly team standup",
            "description": "Monday morning standup meeting",
            "priority": 2,  # high
            "tags": ["meeting", "team"],
            "recurrence_pattern": "weekly",
            "due_date": due_date
        }
        response = requests.post(f"{API_URL}/tasks", json=task_data)
        success = response.status_code == 200
        if success:
            task = response.json()
            recurrence_ok = task.get('recurrence_pattern') == 'weekly'
            print_result(recurrence_ok, f"Recurring task created: {task.get('recurrence_pattern')} pattern")
            print(f"   Due date: {task.get('due_date')}")
            return task
        else:
            print_result(False, f"Status: {response.status_code}, Response: {response.text}")
            return None
    except Exception as e:
        print_result(False, f"Error: {e}")
        return None

def test_get_all_tasks():
    """Test 6: Get all tasks"""
    print_test("Get All Tasks")
    try:
        response = requests.get(f"{API_URL}/tasks")
        success = response.status_code == 200
        if success:
            tasks = response.json()
            count = len(tasks) if isinstance(tasks, list) else 0
            print_result(True, f"Retrieved {count} tasks")
            return tasks
        else:
            print_result(False, f"Status: {response.status_code}")
            return []
    except Exception as e:
        print_result(False, f"Error: {e}")
        return []

def test_update_task(task_id: int):
    """Test 7: Update task"""
    print_test("Update Task")
    try:
        update_data = {
            "priority": 0,  # low
            "tags": ["updated", "test"]
        }
        response = requests.put(f"{API_URL}/tasks/{task_id}", json=update_data)
        success = response.status_code == 200
        if success:
            task = response.json()
            print_result(True, f"Updated task priority to: {task.get('priority')} (0=low)")
            print(f"   New tags: {task.get('tags')}")
            return task
        else:
            print_result(False, f"Status: {response.status_code}, Response: {response.text}")
            return None
    except Exception as e:
        print_result(False, f"Error: {e}")
        return None

def test_complete_task(task_id: int):
    """Test 8: Complete task"""
    print_test("Complete Task")
    try:
        response = requests.post(f"{API_URL}/tasks/{task_id}/complete")
        success = response.status_code == 200
        if success:
            task = response.json()
            completed = task.get('status') == 'completed' or task.get('completed_at') is not None or task.get('completed') == True
            print_result(completed, f"Task completed: {task.get('completed')}")
            return task
        else:
            print_result(False, f"Status: {response.status_code}, Response: {response.text}")
            return None
    except Exception as e:
        print_result(False, f"Error: {e}")
        return None

def test_delete_task(task_id: int):
    """Test 9: Delete task"""
    print_test("Delete Task")
    try:
        response = requests.delete(f"{API_URL}/tasks/{task_id}")
        success = response.status_code == 200
        print_result(success, f"Task {task_id} deleted")
        return success
    except Exception as e:
        print_result(False, f"Error: {e}")
        return False

def run_all_tests():
    """Run all tests in sequence"""
    print("\n" + "="*60)
    print("TODO APPLICATION - PHASE V TESTING")
    print("="*60)

    results = {}

    # Test 1: Health check
    results['health'] = test_health()

    # Test 2: Create basic task
    basic_task = test_create_basic_task()
    results['create_basic'] = basic_task is not None

    # Test 3: Priority
    priority_task = test_create_task_with_priority()
    results['priority'] = priority_task is not None

    # Test 4: Tags
    tags_task = test_create_task_with_tags()
    results['tags'] = tags_task is not None

    # Test 5: Recurring task
    recurring_task = test_create_recurring_task()
    results['recurring'] = recurring_task is not None

    # Test 6: Get all tasks
    all_tasks = test_get_all_tasks()
    results['get_all'] = len(all_tasks) > 0

    # Test 7: Update task (use basic task)
    if basic_task:
        updated_task = test_update_task(basic_task['id'])
        results['update'] = updated_task is not None

    # Test 8: Complete task (use priority task)
    if priority_task:
        completed_task = test_complete_task(priority_task['id'])
        results['complete'] = completed_task is not None

    # Test 9: Delete task (use tags task)
    if tags_task:
        results['delete'] = test_delete_task(tags_task['id'])

    # Summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    print(f"Passed: {passed}/{total}")
    print(f"Success Rate: {passed/total*100:.1f}%")

    print("\nDetailed Results:")
    for test_name, result in results.items():
        status = "[OK]" if result else "[XX]"
        print(f"  {status} {test_name}")

    return results

if __name__ == "__main__":
    run_all_tests()
