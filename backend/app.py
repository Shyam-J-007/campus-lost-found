from groq import Groq
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import bcrypt
import os
import base64
from db import get_connection
from dotenv import load_dotenv


load_dotenv()

app = Flask(__name__)

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

def get_groq_client():
    return Groq(api_key=os.getenv("GROQ_API_KEY"))

@app.route("/")
def home():
    return jsonify({"message": "Lost & Found API running"})

@app.route("/uploads/<filename>")
def uploaded_file(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)

@app.route("/register", methods=["POST", "OPTIONS"])
def register():
    if request.method == "OPTIONS":
        return jsonify({}), 200
    db = None
    try:
        data = request.json
        hashed = bcrypt.hashpw(data["password"].encode(), bcrypt.gensalt())
        db = get_connection()
        cursor = db.cursor()
        cursor.execute("""
            INSERT INTO users (name, email, password, student_id)
            VALUES (%s, %s, %s, %s)
        """, (data["name"], data["email"], hashed, data["student_id"]))
        db.commit()
        return jsonify({"message": "User registered"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db: db.close()

@app.route("/login", methods=["POST", "OPTIONS"])
def login():
    if request.method == "OPTIONS":
        return jsonify({}), 200
    db = None
    try:
        data = request.json
        db = get_connection()
        cursor = db.cursor()
        cursor.execute("SELECT id, password, name FROM users WHERE email = %s", (data["email"],))
        user = cursor.fetchone()
        if user:
            user_id, hashed, name = user
            if isinstance(hashed, str):
                hashed = hashed.encode()
            if bcrypt.checkpw(data["password"].encode(), hashed):
                return jsonify({"message": "Login successful", "user_id": user_id, "name": name})
        return jsonify({"message": "Invalid login"}), 401
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db: db.close()

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
        file.save(os.path.join(UPLOAD_FOLDER, filename))
        return jsonify({"message": "Image uploaded", "filename": filename, "url": f"/uploads/{filename}"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/lost-item", methods=["POST", "OPTIONS"])
def lost_item():
    if request.method == "OPTIONS":
        return jsonify({}), 200
    db = None
    try:
        data = request.json
        db = get_connection()
        cursor = db.cursor()
        cursor.execute("""
            INSERT INTO lost_items (user_id, item_name, description, location_lost, date_lost, image_url)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (data["user_id"], data["item_name"], data["description"],
              data["location"], data["date"], data.get("image_url")))
        db.commit()
        return jsonify({"message": "Lost item reported"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db: db.close()

@app.route("/found-item", methods=["POST", "OPTIONS"])
def found_item():
    if request.method == "OPTIONS":
        return jsonify({}), 200
    db = None
    try:
        data = request.json
        db = get_connection()
        cursor = db.cursor()
        cursor.execute("""
            INSERT INTO found_items (user_id, item_name, description, location_found, date_found, image_url)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (data["user_id"], data["item_name"], data["description"],
              data["location"], data["date"], data.get("image_url")))
        db.commit()
        return jsonify({"message": "Found item reported"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db: db.close()

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
                FROM found_items f JOIN users u ON f.user_id = u.id
                WHERE f.item_name LIKE %s ORDER BY f.id DESC
            """
        else:
            sql = "SELECT *, 'lost' as item_type FROM lost_items WHERE item_name LIKE %s ORDER BY id DESC"
        cursor.execute(sql, ('%' + q + '%',))
        results = cursor.fetchall()
        for r in results:
            for k, v in r.items():
                if hasattr(v, 'isoformat'):
                    r[k] = str(v)
        return jsonify(results)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db: db.close()

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
                SELECT f.*, u.name as finder_name FROM found_items f
                JOIN users u ON f.user_id = u.id WHERE f.item_name LIKE %s
            """, ('%' + lost['item_name'] + '%',))
            for f in cursor.fetchall():
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
        if db: db.close()

@app.route("/conversations/<int:user_id>")
def conversations(user_id):
    db = None
    try:
        db = get_connection()
        cursor = db.cursor(dictionary=True)
        cursor.execute("""
            SELECT m.*, u1.name as sender_name, u2.name as receiver_name
            FROM messages m JOIN users u1 ON m.sender_id = u1.id
            JOIN users u2 ON m.receiver_id = u2.id
            WHERE m.sender_id = %s OR m.receiver_id = %s ORDER BY m.created_at DESC
        """, (user_id, user_id))
        results = cursor.fetchall()
        for r in results:
            if r.get('created_at'):
                r['created_at'] = str(r['created_at'])
        return jsonify(results)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db: db.close()

@app.route("/messages/<int:user_id>/<int:other_id>")
def get_messages(user_id, other_id):
    db = None
    try:
        db = get_connection()
        cursor = db.cursor(dictionary=True)
        cursor.execute("""
            SELECT m.*, u.name as sender_name FROM messages m
            JOIN users u ON m.sender_id = u.id
            WHERE (m.sender_id = %s AND m.receiver_id = %s)
               OR (m.sender_id = %s AND m.receiver_id = %s)
            ORDER BY m.created_at ASC
        """, (user_id, other_id, other_id, user_id))
        results = cursor.fetchall()
        for r in results:
            if r.get('created_at'):
                r['created_at'] = str(r['created_at'])
        cursor.execute("UPDATE messages SET is_read = TRUE WHERE sender_id = %s AND receiver_id = %s",
                       (other_id, user_id))
        db.commit()
        return jsonify(results)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db: db.close()

@app.route("/send-message", methods=["POST", "OPTIONS"])
def send_message():
    if request.method == "OPTIONS":
        return jsonify({}), 200
    db = None
    try:
        data = request.json
        db = get_connection()
        cursor = db.cursor()
        cursor.execute("""
            INSERT INTO messages (sender_id, receiver_id, message, match_item_name)
            VALUES (%s, %s, %s, %s)
        """, (data["sender_id"], data["receiver_id"], data["message"], data.get("match_item_name", "")))
        db.commit()
        return jsonify({"message": "Message sent", "notify_user": data["receiver_id"]})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db: db.close()

@app.route("/unread-count/<int:user_id>")
def unread_count(user_id):
    db = None
    try:
        db = get_connection()
        cursor = db.cursor()
        cursor.execute("SELECT COUNT(*) FROM messages WHERE receiver_id = %s AND is_read = FALSE", (user_id,))
        return jsonify({"count": cursor.fetchone()[0]})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db: db.close()

@app.route("/recover-item", methods=["POST", "OPTIONS"])
def recover_item():
    if request.method == "OPTIONS":
        return jsonify({}), 200
    db = None
    try:
        data = request.json
        db = get_connection()
        cursor = db.cursor()
        cursor.execute("DELETE FROM lost_items WHERE item_name = %s AND user_id = %s",
                       (data["item_name"], data["user_id"]))
        cursor.execute("DELETE FROM found_items WHERE item_name LIKE %s", ('%' + data["item_name"] + '%',))
        db.commit()
        return jsonify({"message": "Item recovered and removed"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db: db.close()

@app.route("/forgot-password", methods=["POST", "OPTIONS"])
def forgot_password():
    if request.method == "OPTIONS":
        return jsonify({}), 200
    db = None
    try:
        data = request.json
        db = get_connection()
        cursor = db.cursor(dictionary=True)
        cursor.execute("SELECT id, name FROM users WHERE email = %s AND student_id = %s",
                       (data["email"], data["student_id"]))
        user = cursor.fetchone()
        if not user:
            return jsonify({"error": "Account not found. Check your email and student ID."}), 404
        if data.get("new_password"):
            hashed = bcrypt.hashpw(data["new_password"].encode(), bcrypt.gensalt())
            cursor.execute("UPDATE users SET password = %s WHERE id = %s", (hashed, user['id']))
            db.commit()
            return jsonify({"message": "Password updated successfully"})
        return jsonify({"message": "Account verified", "name": user['name']})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if db: db.close()

# ── AI Feature 1: Smart Matching with Llama ───────────────────
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

Give a match score 0-100 for each found item. Only include items with score above 30.
Respond ONLY with valid JSON, no markdown, no explanation:
{{"matches": [{{"found_item_id": 1, "score": 85, "reason": "Same item type"}}]}}"""

        client = get_groq_client()
        response = client.chat.completions.create(
            model="meta-llama/llama-4-scout-17b-16e-instruct",  # ✅ Correct
            messages=[{"role": "user", "content": prompt}],
            temperature=0.1,
            max_tokens=1000,
        )

        import json
        text = response.choices[0].message.content.strip()
        text = text.replace("```json", "").replace("```", "").strip()
        result = json.loads(text)

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
        if db: db.close()

# ── AI Feature 2: Image Recognition with Llama Vision ─────────
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

        client = get_groq_client()
        response = client.chat.completions.create(
            model="llama-4-scout-17b-16e-instruct",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:{content_type};base64,{image_b64}"
                            }
                        },
                        {
                            "type": "text",
                            "text": """Identify this lost/found item from the image.
Respond ONLY with valid JSON, no markdown, no explanation:
{"item_name": "short name e.g. Wallet", "description": "color, brand, distinctive features", "category": "Electronics|Accessories|Documents|Clothing|Bags|Other"}"""
                        }
                    ]
                }
            ],
            temperature=0.1,
            max_tokens=500,
        )

        import json
        text = response.choices[0].message.content.strip()
        text = text.replace("```json", "").replace("```", "").strip()
        result = json.loads(text)
        return jsonify(result)

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host='0.0.0.0', port=port, debug=False)