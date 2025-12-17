from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/add', methods=['POST'])
def add():
    try:
        data = request.json
        num1 = int(data.get('num1', 0))
        num2 = int(data.get('num2', 0))
        result = num1 + num2
        return jsonify({"result": result, "status": "success"})
    except Exception as e:
        return jsonify({"error": str(e), "status": "error"}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)