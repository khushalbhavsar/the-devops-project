from flask import Flask, render_template, request, jsonify
import os
import json
import datetime

app = Flask(__name__)

# Sample data for demonstration
tasks = [
    {"id": 1, "title": "Setup DevOps Pipeline", "status": "completed", "created_at": "2024-01-15"},
    {"id": 2, "title": "Deploy to Kubernetes", "status": "in-progress", "created_at": "2024-01-16"},
    {"id": 3, "title": "Setup Monitoring", "status": "pending", "created_at": "2024-01-17"}
]

@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('index.html', tasks=tasks)

@app.route('/health')
def health_check():
    """Health check endpoint for load balancer"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.datetime.now().isoformat(),
        'version': os.environ.get('APP_VERSION', '1.0.0')
    })

@app.route('/api/tasks')
def get_tasks():
    """API endpoint to get all tasks"""
    return jsonify(tasks)

@app.route('/api/tasks', methods=['POST'])
def create_task():
    """API endpoint to create a new task"""
    data = request.get_json()
    new_task = {
        'id': len(tasks) + 1,
        'title': data.get('title', ''),
        'status': 'pending',
        'created_at': datetime.datetime.now().strftime('%Y-%m-%d')
    }
    tasks.append(new_task)
    return jsonify(new_task), 201

@app.route('/api/tasks/<int:task_id>', methods=['PUT'])
def update_task(task_id):
    """API endpoint to update a task"""
    data = request.get_json()
    task = next((t for t in tasks if t['id'] == task_id), None)
    if task:
        task['status'] = data.get('status', task['status'])
        return jsonify(task)
    return jsonify({'error': 'Task not found'}), 404

@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint"""
    return f"""# HELP flask_app_info Application info
# TYPE flask_app_info gauge
flask_app_info{{version="{os.environ.get('APP_VERSION', '1.0.0')}"}} 1
# HELP flask_app_tasks_total Total number of tasks
# TYPE flask_app_tasks_total counter
flask_app_tasks_total {len(tasks)}
# HELP flask_app_tasks_by_status Tasks by status
# TYPE flask_app_tasks_by_status gauge
flask_app_tasks_by_status{{status="completed"}} {len([t for t in tasks if t['status'] == 'completed'])}
flask_app_tasks_by_status{{status="in-progress"}} {len([t for t in tasks if t['status'] == 'in-progress'])}
flask_app_tasks_by_status{{status="pending"}} {len([t for t in tasks if t['status'] == 'pending'])}
"""

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=os.environ.get('FLASK_DEBUG', 'False').lower() == 'true')