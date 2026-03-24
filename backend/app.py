from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import bcrypt
import os
import base64
from db import get_connection
from dotenv import load_dotenv
import google.generativeai as genai
load_dotenv()

app = Flask(__name__)

# ── FIXED CORS ────────────────────────────────────────────────
# Do NOT use supports_credentials=True with origins="*" — browsers reject it
CORS(app, origins="*", allow_headers=["Content-Type", "Authorization"],
     methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"])

@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
    return response

@app.before_request
def handle_options():
    if request.method == "OPTIONS":
        response = jsonify({})
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
        return response, 200

UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route("/")
def home():
    return jsonify({"message": "Lost & Found API running"})

# Serve uploaded images
@app.route("/uploads/<filename>")
def uploaded_file(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)

# Register user
@app.route("/register", methods=["POST", "OPTIONS"])
def register():
    if request.method == "OPTIONS":
        return jsonify({}), 200
    db = None
    try:
        data = request.json
        name = data["name"]
        email = data["email"]
        password = data["password"]
        student_id = data["student_id"]

        hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt())

        db = get_connection()
        cursor = db.cursor()
        query = """
        INSERT INTO users (name, email, password, student_id)
        VALUES (%s, %s, %s, %s)
        """
        cursor.execute(query, (name, email, hashed, student_id))
        db.commit()
        return jsonify({"message": "User registered"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db:
            db.close()

# Login
@app.route("/login", methods=["POST", "OPTIONS"])
def login():
    if request.method == "OPTIONS":
        return jsonify({}), 200
    db = None
    try:
        data = request.json
        email = data["email"]
        password = data["password"]

        db = get_connection()
        cursor = db.cursor()
        query = "SELECT id, password, name FROM users WHERE email = %s"
        cursor.execute(query, (email,))
        user = cursor.fetchone()

        if user:
            user_id, hashed, name = user
            if isinstance(hashed, str):
                hashed = hashed.encode()
            if bcrypt.checkpw(password.encode(), hashed):
                return jsonify({
                    "message": "Login successful",
                    "user_id": user_id,
                    "name": name
                })

        return jsonify({"message": "Invalid login"}), 401
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db:
            db.close()

# Upload image
@app.route("/upload-image", methods=["POST", "OPTIONS"])
def upload_image():
    if request.method == "OPTIONS":
        return jsonify({}), 200
    try:
        if 'image' not in request.files:
            return jsonify({"error": "No image provided"}), 400

        file = request.files['image']
        if file.filename == '':
            return jsonify({"error": "No file selected"}), 400

        import uuid
        ext = file.filename.rsplit('.', 1)[-1].lower()
        filename = f"{uuid.uuid4().hex}.{ext}"
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        file.save(filepath)

        return jsonify({
            "message": "Image uploaded",
            "filename": filename,
            "url": f"/uploads/{filename}"
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Report lost item
@app.route("/lost-item", methods=["POST", "OPTIONS"])
def lost_item():
    if request.method == "OPTIONS":
        return jsonify({}), 200
    db = None
    try:
        data = request.json
        user_id = data["user_id"]
        item_name = data["item_name"]
        description = data["description"]
        location = data["location"]
        date_lost = data["date"]
        image_url = data.get("image_url", None)

        db = get_connection()
        cursor = db.cursor()
        query = """
        INSERT INTO lost_items (user_id, item_name, description, location_lost, date_lost, image_url)
        VALUES (%s, %s, %s, %s, %s, %s)
        """
        cursor.execute(query, (user_id, item_name, description, location, date_lost, image_url))
        db.commit()
        return jsonify({"message": "Lost item reported"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db:
            db.close()

# Report found item
@app.route("/found-item", methods=["POST", "OPTIONS"])
def found_item():
    if request.method == "OPTIONS":
        return jsonify({}), 200
    db = None
    try:
        data = request.json
        user_id = data["user_id"]
        item_name = data["item_name"]
        description = data["description"]
        location = data["location"]
        date_found = data["date"]
        image_url = data.get("image_url", None)

        db = get_connection()
        cursor = db.cursor()
        query = """
        INSERT INTO found_items (user_id, item_name, description, location_found, date_found, image_url)
        VALUES (%s, %s, %s, %s, %s, %s)
        """
        cursor.execute(query, (user_id, item_name, description, location, date_found, image_url))
        db.commit()
        return jsonify({"message": "Found item reported"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db:
            db.close()

# Search both lost and found items
@app.route("/search")
def search():
    db = None
    try:
        q = request.args.get("q", "")
        type_filter = request.args.get("type", "lost")
        db = get_connection()
        cursor = db.cursor(dictionary=True)

        if type_filter == "found":
            sql = """
            SELECT f.*, u.name as finder_name, 'found' as item_type 
            FROM found_items f
            JOIN users u ON f.user_id = u.id
            WHERE f.item_name LIKE %s
            ORDER BY f.id DESC
            """
        else:
            sql = """
            SELECT *, 'lost' as item_type FROM lost_items
            WHERE item_name LIKE %s
            ORDER BY id DESC
            """

        cursor.execute(sql, ('%' + q + '%',))
        results = cursor.fetchall()
        return jsonify(results)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db:
            db.close()

# Check for matches between lost and found items
@app.route("/check-matches/<int:user_id>")
def check_matches(user_id):
    db = None
    try:
        db = get_connection()
        cursor = db.cursor(dictionary=True)
        cursor.execute("SELECT * FROM lost_items WHERE user_id = %s", (user_id,))
        lost_items = cursor.fetchall()

        matches = []
        for lost in lost_items:
            cursor.execute("""
                SELECT f.*, u.name as finder_name
                FROM found_items f
                JOIN users u ON f.user_id = u.id
                WHERE f.item_name LIKE %s
            """, ('%' + lost['item_name'] + '%',))
            found_list = cursor.fetchall()
            for f in found_list:
                matches.append({
                    'lost_item': lost['item_name'],
                    'lost_location': lost['location_lost'],
                    'found_location': f['location_found'],
                    'found_date': str(f['date_found']),
                    'finder_user_id': f['user_id'],
                    'finder_name': f['finder_name'],
                    'message': f"Your lost {lost['item_name']} may have been found at {f['location_found']} by {f['finder_name']}!"
                })

        return jsonify(matches)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db:
            db.close()

# Get all conversations for a user
@app.route("/conversations/<int:user_id>")
def conversations(user_id):
    db = None
    try:
        db = get_connection()
        cursor = db.cursor(dictionary=True)
        cursor.execute("""
            SELECT m.*, u1.name as sender_name, u2.name as receiver_name
            FROM messages m
            JOIN users u1 ON m.sender_id = u1.id
            JOIN users u2 ON m.receiver_id = u2.id
            WHERE m.sender_id = %s OR m.receiver_id = %s
            ORDER BY m.created_at DESC
        """, (user_id, user_id))
        results = cursor.fetchall()
        for r in results:
            if r.get('created_at'):
                r['created_at'] = str(r['created_at'])
        return jsonify(results)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db:
            db.close()

# Get messages between two users
@app.route("/messages/<int:user_id>/<int:other_id>")
def get_messages(user_id, other_id):
    db = None
    try:
        db = get_connection()
        cursor = db.cursor(dictionary=True)
        cursor.execute("""
            SELECT m.*, u.name as sender_name
            FROM messages m
            JOIN users u ON m.sender_id = u.id
            WHERE (m.sender_id = %s AND m.receiver_id = %s)
               OR (m.sender_id = %s AND m.receiver_id = %s)
            ORDER BY m.created_at ASC
        """, (user_id, other_id, other_id, user_id))
        results = cursor.fetchall()
        for r in results:
            if r.get('created_at'):
                r['created_at'] = str(r['created_at'])
        cursor.execute("""
            UPDATE messages SET is_read = TRUE
            WHERE sender_id = %s AND receiver_id = %s
        """, (other_id, user_id))
        db.commit()
        return jsonify(results)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db:
            db.close()

# Send a message
@app.route("/send-message", methods=["POST", "OPTIONS"])
def send_message():
    if request.method == "OPTIONS":
        return jsonify({}), 200
    db = None
    try:
        data = request.json
        sender_id = data["sender_id"]
        receiver_id = data["receiver_id"]
        message = data["message"]
        match_item_name = data.get("match_item_name", "")

        db = get_connection()
        cursor = db.cursor()
        cursor.execute("""
            INSERT INTO messages (sender_id, receiver_id, message, match_item_name)
            VALUES (%s, %s, %s, %s)
        """, (sender_id, receiver_id, message, match_item_name))
        db.commit()
        return jsonify({"message": "Message sent", "notify_user": receiver_id})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db:
            db.close()

# Get unread message count
@app.route("/unread-count/<int:user_id>")
def unread_count(user_id):
    db = None
    try:
        db = get_connection()
        cursor = db.cursor()
        cursor.execute("""
            SELECT COUNT(*) FROM messages
            WHERE receiver_id = %s AND is_read = FALSE
        """, (user_id,))
        count = cursor.fetchone()[0]
        return jsonify({"count": count})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db:
            db.close()

# Recover item
@app.route("/recover-item", methods=["POST", "OPTIONS"])
def recover_item():
    if request.method == "OPTIONS":
        return jsonify({}), 200
    db = None
    try:
        data = request.json
        item_name = data["item_name"]
        user_id = data["user_id"]

        db = get_connection()
        cursor = db.cursor()
        cursor.execute("""
            DELETE FROM lost_items WHERE item_name = %s AND user_id = %s
        """, (item_name, user_id))
        cursor.execute("""
            DELETE FROM found_items WHERE item_name LIKE %s
        """, ('%' + item_name + '%',))
        db.commit()
        return jsonify({"message": "Item recovered and removed"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db:
            db.close()

# Forgot password
@app.route("/forgot-password", methods=["POST", "OPTIONS"])
def forgot_password():
    if request.method == "OPTIONS":
        return jsonify({}), 200
    db = None
    try:
        data = request.json
        email = data["email"]
        student_id = data["student_id"]
        new_password = data.get("new_password", None)

        db = get_connection()
        cursor = db.cursor(dictionary=True)
        cursor.execute("""
            SELECT id, name FROM users WHERE email = %s AND student_id = %s
        """, (email, student_id))
        user = cursor.fetchone()

        if not user:
            return jsonify({"error": "Account not found. Check your email and student ID."}), 404

        if new_password:
            hashed = bcrypt.hashpw(new_password.encode(), bcrypt.gensalt())
            cursor.execute("UPDATE users SET password = %s WHERE id = %s", (hashed, user['id']))
            db.commit()
            return jsonify({"message": "Password updated successfully"})

        return jsonify({"message": "Account verified", "name": user['name']})

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db:
            db.close()

# ── Claude client ─────────────────────────────────────────────
def get_claude_client():
    return anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

# ── AI Feature 1: Smart Item Matching ────────────────────────
@app.route("/ai-match/<int:lost_item_id>", methods=["GET"])
def ai_match(lost_item_id):
    db = None
    try:
        db = get_connection()
        cursor = db.cursor(dictionary=True)

        cursor.execute("SELECT * FROM lost_items WHERE id = %s", (lost_item_id,))
        lost_item = cursor.fetchone()

        if not lost_item:
            return jsonify({"error": "Lost item not found"}), 404

        cursor.execute("SELECT * FROM found_items")
        found_items = cursor.fetchall()

        if not found_items:
            return jsonify({"matches": []})

        found_items_text = "\n".join([
            f"Found Item {i+1} (ID: {f['id']}): {f['item_name']} - {f['description']} - Found at {f['location_found']} on {f['date_found']}"
            for i, f in enumerate(found_items)
        ])

        prompt = f"""You are a lost and found matching assistant.

Lost Item:
- Name: {lost_item['item_name']}
- Description: {lost_item['description']}
- Lost at: {lost_item['location_lost']}
- Date lost: {lost_item['date_lost']}

Found Items:
{found_items_text}

For each found item, give a match score from 0-100 and a brief reason.
Only include items with score above 30.
Respond in JSON format like this:
{{
  "matches": [
    {{
      "found_item_id": 1,
      "score": 85,
      "reason": "Same item type, similar location and date"
    }}
  ]
}}
Only respond with valid JSON, nothing else."""

        client = get_claude_client()
        message = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=1000,
            messages=[{"role": "user", "content": prompt}]
        )

        import json
        result = json.loads(message.content[0].text)

        found_dict = {f['id']: f for f in found_items}
        for match in result.get('matches', []):
            fid = match['found_item_id']
            if fid in found_dict:
                match['item_name'] = found_dict[fid]['item_name']
                match['location_found'] = found_dict[fid]['location_found']
                match['date_found'] = str(found_dict[fid]['date_found'])
                match['finder_user_id'] = found_dict[fid]['user_id']

        return jsonify(result)

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db:
            db.close()

# ── AI Feature 2: Image Recognition ──────────────────────────
@app.route("/ai-identify-image", methods=["POST", "OPTIONS"])
def ai_identify_image():
    if request.method == "OPTIONS":
        return jsonify({}), 200
    try:
        data = request.json
        image_b64 = data.get("image_base64")
        content_type = data.get("content_type", "image/jpeg")

        if not image_b64:
            return jsonify({"error": "No image data provided"}), 400

        client = get_claude_client()
        message = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=500,
            messages=[{
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": content_type,
                            "data": image_b64,
                        },
                    },
                    {
                        "type": "text",
                        "text": """Identify this lost/found item from the image.
Respond in JSON format only:
{
  "item_name": "short item name (e.g. Wallet, Phone, Keys)",
  "description": "brief description including color, brand if visible, and distinctive features",
  "category": "one of: Electronics, Accessories, Documents, Clothing, Bags, Other"
}
Only respond with valid JSON, nothing else."""
                    }
                ],
            }],
        )

        import json
        result = json.loads(message.content[0].text)
        return jsonify(result)

    except Exception as e:
        return jsonify({"error": str(e)}), 500
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host='0.0.0.0', port=port, debug=False)