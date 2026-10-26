"""
Automated CI/CD Pipeline - Sample Python Flask Application
Designed for Keysight Technologies DevOps Intern Interview & Demonstration
"""

import os
import sys
from datetime import datetime, timezone
from flask import Flask, jsonify, make_response, request

# Initialize Flask application
app = Flask(__name__)

# Application Metadata
APP_NAME = "DevOps CI/CD Demo Application"
APP_VERSION = "1.0.0"
APP_ENVIRONMENT = os.getenv("APP_ENV", "production")
START_TIME = datetime.now(timezone.utc)


@app.route("/", methods=["GET"])
def home():
    """
    Root Endpoint (GET /)
    Returns project name, application status, and API directory.
    """
    response_data = {
        "project": APP_NAME,
        "status": "online",
        "message": "Welcome to the Automated CI/CD Pipeline with Jenkins, Python, and GitHub!",
        "endpoints": {
            "root": "/",
            "health": "/health",
            "version": "/version"
        }
    }
    return jsonify(response_data), 200


@app.route("/health", methods=["GET"])
def health():
    """
    Health Check Endpoint (GET /health)
    Used by Jenkins Smoke Test and monitoring tools to verify app readiness.
    """
    uptime_seconds = (datetime.now(timezone.utc) - START_TIME).total_seconds()
    response_data = {
        "status": "healthy",
        "service": "devops-cicd-app",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "uptime_seconds": round(uptime_seconds, 2)
    }
    return jsonify(response_data), 200


@app.route("/version", methods=["GET"])
def version():
    """
    Version Endpoint (GET /version)
    Returns current application version and environment.
    """
    response_data = {
        "version": APP_VERSION,
        "environment": APP_ENVIRONMENT,
        "python_version": sys.version.split()[0]
    }
    return jsonify(response_data), 200


# Error Handlers
@app.errorhandler(404)
def not_found(error):
    """Handles 404 Not Found errors with structured JSON response."""
    return jsonify({
        "error": "Not Found",
        "message": "The requested URL was not found on this server.",
        "status_code": 404
    }), 404


@app.errorhandler(405)
def method_not_allowed(error):
    """Handles 405 Method Not Allowed errors."""
    return jsonify({
        "error": "Method Not Allowed",
        "message": f"Method {request.method} is not allowed for this endpoint.",
        "status_code": 405
    }), 405


@app.errorhandler(500)
def internal_error(error):
    """Handles 500 Internal Server Error."""
    return jsonify({
        "error": "Internal Server Error",
        "message": "An unexpected error occurred on the server.",
        "status_code": 500
    }), 500


if __name__ == "__main__":
    # Get port from environment variable or default to 5000
    port = int(os.getenv("PORT", 5000))
    host = os.getenv("HOST", "0.0.0.0")
    print(f"Starting {APP_NAME} v{APP_VERSION} on http://{host}:{port}")
    app.run(host=host, port=port, debug=False)
