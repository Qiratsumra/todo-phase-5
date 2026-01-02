#!/usr/bin/env python3
"""
Search, Filter, and Sort testing for Todo Application Phase V
"""

import requests
import json

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

def setup_test_tasks():
    """Create sample tasks for testing search/filter/sort"""
    print_test("Setup: Creating Test Tasks")

    test_tasks = [
        {
            "title": "Backend API development",
            "description": "Build REST API endpoints",
            "priority": 2,  # high
            "tags": ["backend", "development"]
        },
        {
            "title": "Frontend UI design",
            "description": "Design user interface",
            "priority": 1,  # medium
            "tags": ["frontend", "design", "ui"]
        },
        {
            "title": "Database migration",
            "description": "Update schema",
            "priority": 2,  # high
            "tags": ["backend", "database"]
        },
        {
            "title": "Write documentation",
            "description": "API documentation",
            "priority": 0,  # low
            "tags": ["documentation"]
        }
    ]

    created_ids = []
    for task_data in test_tasks:
        response = requests.post(f"{API_URL}/tasks", json=task_data)
        if response.status_code == 200:
            task = response.json()
            created_ids.append(task['id'])
            print(f"Created task {task['id']}: {task['title']}")

    print_result(len(created_ids) == len(test_tasks), f"Created {len(created_ids)}/{ len(test_tasks)} test tasks")
    return created_ids

def test_filter_by_priority():
    """Test filtering by priority"""
    print_test("Filter by Priority (high)")
    try:
        response = requests.get(f"{API_URL}/tasks", params={"priority": "high"})
        success = response.status_code == 200
        if success:
            data = response.json()
            # Handle both list and dict response formats
            if isinstance(data, list):
                tasks = data
            else:
                tasks = data.get('tasks', [])

            # Check if all returned tasks have high priority (2)
            print(f"Total tasks returned: {len(tasks)}")
            priorities = [t.get('priority') for t in tasks]
            print(f"Priority distribution: {set(priorities)}")

            high_priority_tasks = [t for t in tasks if t.get('priority') == 2 or t.get('priority') == 'high']
            all_high = len(high_priority_tasks) == len(tasks) if tasks else True
            print_result(all_high, f"Found {len(high_priority_tasks)}/{len(tasks)} high-priority tasks")
            if tasks:
                for task in tasks[:3]:  # Show first 3
                    print(f"  - {task.get('title')} (priority: {task.get('priority')})")
            return all_high
        else:
            print_result(False, f"Status: {response.status_code}")
            return False
    except Exception as e:
        print_result(False, f"Error: {e}")
        return False

def test_filter_by_tag():
    """Test filtering by tag"""
    print_test("Filter by Tag (backend)")
    try:
        response = requests.get(f"{API_URL}/tasks", params={"tag": "backend"})
        success = response.status_code == 200
        if success:
            tasks = response.json()
            # Check if tasks have the backend tag
            backend_tasks = [t for t in tasks if t.get('tags') and 'backend' in t.get('tags')]
            has_tag = len(backend_tasks) > 0
            print_result(has_tag, f"Found {len(backend_tasks)} tasks with 'backend' tag")
            if backend_tasks:
                for task in backend_tasks[:3]:
                    print(f"  - {task.get('title')} tags: {task.get('tags')}")
            return has_tag
        else:
            print_result(False, f"Status: {response.status_code}")
            return False
    except Exception as e:
        print_result(False, f"Error: {e}")
        return False

def test_sort_by_priority():
    """Test sorting by priority"""
    print_test("Sort by Priority (descending)")
    try:
        response = requests.get(f"{API_URL}/tasks", params={"sort_by": "priority", "sort_order": "desc"})
        success = response.status_code == 200
        if success:
            tasks = response.json()
            if len(tasks) >= 2:
                # Check if sorted in descending order
                priorities = [t.get('priority', 0) for t in tasks]
                is_sorted = all(priorities[i] >= priorities[i+1] for i in range(len(priorities)-1))
                print_result(is_sorted, f"Tasks sorted by priority: {priorities[:5]}")
                return is_sorted
            else:
                print_result(True, "Not enough tasks to test sorting")
                return True
        else:
            print_result(False, f"Status: {response.status_code}")
            return False
    except Exception as e:
        print_result(False, f"Error: {e}")
        return False

def test_sort_by_title():
    """Test sorting by title"""
    print_test("Sort by Title (ascending)")
    try:
        response = requests.get(f"{API_URL}/tasks", params={"sort_by": "title"})
        success = response.status_code == 200
        if success:
            tasks = response.json()
            if len(tasks) >= 2:
                titles = [t.get('title', '') for t in tasks]
                is_sorted = all(titles[i].lower() <= titles[i+1].lower() for i in range(len(titles)-1))
                print_result(is_sorted, f"Tasks sorted alphabetically")
                print(f"  First 3 titles: {titles[:3]}")
                return is_sorted
            else:
                print_result(True, "Not enough tasks to test sorting")
                return True
        else:
            print_result(False, f"Status: {response.status_code}")
            return False
    except Exception as e:
        print_result(False, f"Error: {e}")
        return False

def test_combined_filter_and_sort():
    """Test combined filtering and sorting"""
    print_test("Combined: Filter by priority + Sort by title")
    try:
        response = requests.get(f"{API_URL}/tasks", params={
            "priority": "high",
            "sort_by": "title"
        })
        success = response.status_code == 200
        if success:
            tasks = response.json()
            # Check filtering
            all_high = all(t.get('priority') == 2 for t in tasks) if tasks else True
            # Check sorting
            if len(tasks) >= 2:
                titles = [t.get('title', '') for t in tasks]
                is_sorted = all(titles[i].lower() <= titles[i+1].lower() for i in range(len(titles)-1))
            else:
                is_sorted = True

            success = all_high and is_sorted
            print_result(success, f"Found {len(tasks)} high-priority tasks, sorted by title")
            if tasks:
                for task in tasks[:3]:
                    print(f"  - {task.get('title')} (priority: {task.get('priority')})")
            return success
        else:
            print_result(False, f"Status: {response.status_code}")
            return False
    except Exception as e:
        print_result(False, f"Error: {e}")
        return False

def cleanup_tasks(task_ids):
    """Clean up test tasks"""
    print_test("Cleanup: Deleting Test Tasks")
    deleted = 0
    for task_id in task_ids:
        try:
            response = requests.delete(f"{API_URL}/tasks/{task_id}")
            if response.status_code == 200:
                deleted += 1
        except:
            pass
    print_result(deleted == len(task_ids), f"Deleted {deleted}/{len(task_ids)} test tasks")

def run_search_filter_tests():
    """Run all search/filter/sort tests"""
    print("\n" + "="*60)
    print("SEARCH, FILTER, SORT TESTING - PHASE V")
    print("="*60)

    results = {}

    # Setup
    test_task_ids = setup_test_tasks()

    # Run tests
    results['filter_priority'] = test_filter_by_priority()
    results['filter_tag'] = test_filter_by_tag()
    results['sort_priority'] = test_sort_by_priority()
    results['sort_title'] = test_sort_by_title()
    results['combined'] = test_combined_filter_and_sort()

    # Cleanup
    cleanup_tasks(test_task_ids)

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
    run_search_filter_tests()
