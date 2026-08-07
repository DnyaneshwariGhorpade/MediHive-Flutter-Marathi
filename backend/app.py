import os
from flask import Flask
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from config import SECRET_KEY, JWT_SECRET_KEY, JWT_ACCESS_TOKEN_EXPIRES
from services.log_service import get_logger

from routes.auth import auth_bp
from routes.patients import patients_bp
from routes.opd import opd_bp
from routes.appointments import appointments_bp
from routes.sync import sync_bp
from routes.cloud import cloud_bp
from routes.settings import settings_bp
from routes.fcm import fcm_bp
from routes.whatsapp import whatsapp_bp

logger = get_logger(__name__)


def create_app():
    app = Flask(__name__)
    CORS(app)

    app.config['SECRET_KEY'] = SECRET_KEY
    app.config['JWT_SECRET_KEY'] = JWT_SECRET_KEY
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = JWT_ACCESS_TOKEN_EXPIRES

    JWTManager(app)

    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(patients_bp, url_prefix='/api/patients')
    app.register_blueprint(opd_bp, url_prefix='/api/opd')
    app.register_blueprint(appointments_bp, url_prefix='/api/appointments')
    app.register_blueprint(sync_bp, url_prefix='/api/sync')
    app.register_blueprint(cloud_bp, url_prefix='/api/cloud')
    app.register_blueprint(settings_bp, url_prefix='/api/settings')
    app.register_blueprint(fcm_bp, url_prefix='/api/fcm')
    app.register_blueprint(whatsapp_bp, url_prefix='/api/whatsapp')

    @app.route('/api/health', methods=['GET'])
    def health():
        return {'status': 'ok', 'version': '1.0.0'}

    @app.route('/', methods=['GET'])
    def root():
        return {
            'message': 'MediHive Backend Running',
            'health': '/api/health'
        }

    return app


app = create_app()

# ── Startup: load (and seed defaults for) settings ──────────────
# Use a First-Request hook so that importing the module does not
# require a live database connection.  The settings are loaded
# lazily on the very first HTTP request.
_initialised = False

@app.before_request
def _init_settings_on_first_request():
    global _initialised
    if not _initialised:
        from services.settings_manager import settings_manager
        settings_manager.load()
        logger.info("Settings initialised at startup (lazy)")
        
        from services.sync_worker import start_worker
        start_worker()
        
        _initialised = True


if __name__ == '__main__':
    port = int(os.environ.get("PORT", 8080))
    app.run(
        host='0.0.0.0',
        port=port,
        debug=False
    )
