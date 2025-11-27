import pytest
import json
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health_check(client):
    """Test health check endpoint"""
    response = client.get('/health')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert data['status'] == 'healthy'
    assert 'timestamp' in data
    assert 'version' in data

def test_index_page(client):
    """Test main index page"""
    response = client.get('/')
    assert response.status_code == 200
    assert b'DevOps Task Manager' in response.data

def test_get_tasks_api(client):
    """Test get tasks API endpoint"""
    response = client.get('/api/tasks')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert isinstance(data, list)
    assert len(data) > 0

def test_create_task_api(client):
    """Test create task API endpoint"""
    new_task = {'title': 'Test Task'}
    response = client.post('/api/tasks', 
                          data=json.dumps(new_task),
                          content_type='application/json')
    
    assert response.status_code == 201
    
    data = json.loads(response.data)
    assert data['title'] == 'Test Task'
    assert data['status'] == 'pending'
    assert 'id' in data

def test_update_task_api(client):
    """Test update task API endpoint"""
    # First create a task
    new_task = {'title': 'Test Task for Update'}
    create_response = client.post('/api/tasks',
                                 data=json.dumps(new_task),
                                 content_type='application/json')
    
    created_task = json.loads(create_response.data)
    task_id = created_task['id']
    
    # Update the task
    update_data = {'status': 'completed'}
    response = client.put(f'/api/tasks/{task_id}',
                         data=json.dumps(update_data),
                         content_type='application/json')
    
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert data['status'] == 'completed'

def test_update_nonexistent_task(client):
    """Test updating a task that doesn't exist"""
    update_data = {'status': 'completed'}
    response = client.put('/api/tasks/999',
                         data=json.dumps(update_data),
                         content_type='application/json')
    
    assert response.status_code == 404

def test_metrics_endpoint(client):
    """Test Prometheus metrics endpoint"""
    response = client.get('/metrics')
    assert response.status_code == 200
    
    # Check if metrics are in Prometheus format
    assert b'flask_app_info' in response.data
    assert b'flask_app_tasks_total' in response.data
    assert b'flask_app_tasks_by_status' in response.data