import os
# Disable Metal/MPS for macOS compatibility (must be set before any ML imports)
os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")
os.environ.setdefault("CUDA_VISIBLE_DEVICES", "")

from flask import Flask,render_template,request,session,redirect,url_for
from flask_session import Session
from app.components.retriever import create_qa_chain
from app.common.logger import get_logger
from dotenv import load_dotenv

load_dotenv()
HF_TOKEN = os.environ.get("HF_TOKEN")

app = Flask(__name__)

# Use fixed secret key from environment - CRITICAL for sessions to work
# Generate a persistent key if not set (store it for production)
SECRET_KEY = os.environ.get("FLASK_SECRET_KEY")
if not SECRET_KEY:
    # For production, generate once and store in .env
    # For now, use a default (change this in production!)
    import secrets
    SECRET_KEY = secrets.token_hex(32)
app.secret_key = SECRET_KEY

# Configure Flask-Session for filesystem storage (works with Gunicorn workers)
# Use /tmp for sessions to avoid permission issues (or use absolute path in user's home)
SESSION_DIR = os.path.join(os.path.expanduser('~'), '.flask_sessions')
# Alternative: Use /tmp (but sessions won't persist across reboots)
# SESSION_DIR = '/tmp/flask_sessions'
os.makedirs(SESSION_DIR, exist_ok=True)
# Ensure the directory is writable
try:
    os.chmod(SESSION_DIR, 0o755)
except Exception as e:
    pass  # Will log warning after logger is initialized

app.config['SESSION_TYPE'] = 'filesystem'
app.config['SESSION_FILE_DIR'] = SESSION_DIR
app.config['SESSION_PERMANENT'] = False
app.config['SESSION_USE_SIGNER'] = True
app.config['SESSION_KEY_PREFIX'] = 'rag_chatbot:'

# Initialize Flask-Session
Session(app)

# Initialize logger after app is created
logger = get_logger(__name__)
logger.info(f"Session directory: {SESSION_DIR}")
# Check if session directory is writable
if not os.access(SESSION_DIR, os.W_OK):
    logger.warning(f"Session directory {SESSION_DIR} is not writable! This will cause session errors.")
    logger.warning("Fix with: chmod 755 " + SESSION_DIR + " or chown to current user")
if os.environ.get("FLASK_SECRET_KEY"):
    logger.info("Flask application initialized with filesystem session storage (secret key from environment)")
else:
    logger.warning("FLASK_SECRET_KEY not set. Sessions may not persist across restarts. Set FLASK_SECRET_KEY in .env for production.")
    logger.info("Flask application initialized with filesystem session storage (using generated key)")

from markupsafe import Markup
def nl2br(value):
    return Markup(value.replace("\n" , "<br>\n"))

app.jinja_env.filters['nl2br'] = nl2br

@app.route("/" , methods=["GET","POST"])
def index():
    # Initialize messages in session if not present
    if "messages" not in session:
        session["messages"] = []
        session.permanent = True

    if request.method=="POST":
        user_input = request.form.get("prompt")
        logger.info(f"POST request received. User input: {user_input[:100] if user_input else 'None'}")

        if user_input:
            try:
                # Get current messages from session
                messages = list(session.get("messages", []))
                logger.info(f"Current session has {len(messages)} messages")
                
                # Add user message
                messages.append({"role" : "user" , "content":user_input})
                session["messages"] = messages
                session.modified = True  # Explicitly mark session as modified
                logger.info(f"Added user message to session. Total messages: {len(messages)}")
                
                logger.info(f"Processing question: {user_input[:50]}...")
                
                # Create QA chain and get response
                logger.info("Creating QA chain...")
                qa_chain = create_qa_chain()
                if qa_chain is None:
                    raise Exception("QA chain could not be created (LLM or VectorStore issue)")
                
                logger.info(f"Invoking QA chain with query: '{user_input}'")
                # Ensure query is passed correctly
                if not user_input or not user_input.strip():
                    raise Exception("Query is empty")
                response = qa_chain.invoke({"query" : user_input.strip()})
                result = response.get("result" , "No response")
                if not result or result.strip() == "":
                    result = "No response generated"
                
                logger.info(f"Got response: {result[:100] if result else 'No response'}...")

                # Add assistant response
                messages.append({"role" : "assistant" , "content" : result})
                session["messages"] = messages
                session.modified = True  # Explicitly mark session as modified
                logger.info(f"Added assistant response. Total messages: {len(messages)}")
                
            except Exception as e:
                logger.error(f"ERROR processing question: {str(e)}", exc_info=True)
                import traceback
                logger.error(f"Full traceback: {traceback.format_exc()}")
                error_msg = f"Error: {str(e)}"
                # Preserve existing messages even on error
                messages = list(session.get("messages", []))
                logger.error(f"Returning error page with {len(messages)} messages")
                return render_template("index.html" , messages=messages , error = error_msg)
        else:
            logger.warning("POST request received but user_input is empty")
            
        logger.info("Redirecting to index...")
        return redirect(url_for("index"))
    
    # GET request - display messages
    messages = session.get("messages", [])
    logger.info(f"GET request - Displaying {len(messages)} messages in session")
    return render_template("index.html" , messages=messages)

@app.route("/clear")
def clear():
    session.pop("messages" , None)
    return redirect(url_for("index"))

if __name__=="__main__":
    app.run(host="0.0.0.0" , port=5000 , debug=False , use_reloader = False)



