import base64

from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
import ollama
from werkzeug.security import generate_password_hash, check_password_hash


app = Flask(__name__)
CORS(app)

# SQLite Database Configuration
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///database.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

MODEL_NAME = "deepseek-r1:1.5b"
MODEL_NAME_FOR_PICTURES=("llava")


# User Health Profile Model
class UserProfile(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    age = db.Column(db.Integer, nullable=True)
    gender = db.Column(db.String(10), nullable=True)
    height = db.Column(db.Float, nullable=True)
    weight = db.Column(db.Float, nullable=True)
    bmi = db.Column(db.Float, nullable=True)
    body_fat = db.Column(db.Float, nullable=True)
    existing_conditions = db.Column(db.String(200), nullable=True)
    allergies = db.Column(db.String(200), nullable=True)
    medications = db.Column(db.String(200), nullable=True)
    diet_type = db.Column(db.String(50), nullable=True)
    meal_pattern = db.Column(db.String(50), nullable=True)
    water_intake = db.Column(db.Float, nullable=True)
    sugar_salt_intake = db.Column(db.String(50), nullable=True)
    activity_level = db.Column(db.String(50), nullable=True)
    preferred_exercises = db.Column(db.String(200), nullable=True)
    workout_duration = db.Column(db.Integer, nullable=True)
    primary_goal = db.Column(db.String(50), nullable=True)
    target_weight = db.Column(db.Float, nullable=True)
    timeframe = db.Column(db.String(50), nullable=True)
    sleep_duration = db.Column(db.Float, nullable=True)
    stress_level = db.Column(db.String(50), nullable=True)
    smoking_alcohol = db.Column(db.String(50), nullable=True)


# Create tables (if they don't exist)
with app.app_context():
    db.create_all()


def calculate_bmi(height, weight):
    """Calculate BMI based on height (in centimeters) and weight (in kg)."""
    return round(weight / (height / 100) ** 2, 2) if height and weight else None


def ask_ollama(context, question):
    """Send a question with context to the Ollama model."""
    response = ollama.chat(model=MODEL_NAME, messages=[{'role': 'user', 'content': question + context}])
    return response['message']['content']


@app.route('/')
def index():
    return "Health & Nutrition AI API Running!"


# ======================== Authentication Endpoints ========================

@app.route('/api/register', methods=['POST'])
def register():
    """Register a new user with email and password."""
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    if not email or not password:
        return jsonify({'error': 'Email and password are required'}), 400

    # Check if email already exists
    if UserProfile.query.filter_by(email=email).first():
        return jsonify({'error': 'Email already registered'}), 400

    # Hash the password
    password_hash = generate_password_hash(password)

    # Create new user with additional health data if provided
    height = data.get('height')
    weight = data.get('weight')
    bmi = calculate_bmi(height, weight) if height and weight else None

    new_user = UserProfile(
        email=email,
        password_hash=password_hash,
        age=data.get('age'),
        gender=data.get('gender'),
        height=height,
        weight=weight,
        bmi=bmi,
        body_fat=data.get('body_fat'),
        existing_conditions=data.get('existing_conditions'),
        allergies=data.get('allergies'),
        medications=data.get('medications'),
        diet_type=data.get('diet_type'),
        meal_pattern=data.get('meal_pattern'),
        water_intake=data.get('water_intake'),
        sugar_salt_intake=data.get('sugar_salt_intake'),
        activity_level=data.get('activity_level'),
        preferred_exercises=data.get('preferred_exercises'),
        workout_duration=data.get('workout_duration'),
        primary_goal=data.get('primary_goal'),
        target_weight=data.get('target_weight'),
        timeframe=data.get('timeframe'),
        sleep_duration=data.get('sleep_duration'),
        stress_level=data.get('stress_level'),
        smoking_alcohol=data.get('smoking_alcohol')
    )

    db.session.add(new_user)
    db.session.commit()

    return jsonify({"message": "User registered successfully!", "user_id": new_user.id}), 201


@app.route('/api/login', methods=['POST'])
def login():
    """Login using email and password."""
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({'error': 'Email and password are required'}), 400

    user = UserProfile.query.filter_by(email=email).first()
    if user and check_password_hash(user.password_hash, password):
        return jsonify({"message": "Login successful!", "user_id": user.id}), 200
    else:
        return jsonify({"error": "Invalid credentials"}), 401


# ======================== CRUD Operations ========================

@app.route('/api/user/<int:user_id>', methods=['GET'])
def get_user(user_id):
    """Retrieve user details by ID."""
    user = UserProfile.query.get_or_404(user_id)
    return jsonify({
        "id": user.id,
        "email": user.email,
        "age": user.age,
        "gender": user.gender,
        "height": user.height,
        "weight": user.weight,
        "bmi": user.bmi,
        "existing_conditions": user.existing_conditions,
        "allergies": user.allergies,
        "diet_type": user.diet_type,
        "activity_level": user.activity_level,
        "primary_goal": user.primary_goal,
        "stress_level": user.stress_level
    })


@app.route('/api/user/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    """Update user details."""
    user = UserProfile.query.get_or_404(user_id)
    data = request.get_json()

    user.age = data.get('age', user.age)
    user.height = data.get('height', user.height)
    user.weight = data.get('weight', user.weight)
    user.bmi = calculate_bmi(user.height, user.weight)
    user.primary_goal = data.get('primary_goal', user.primary_goal)

    db.session.commit()
    return jsonify({"message": "User profile updated successfully!"})


@app.route('/api/user/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    """Delete user by ID."""
    user = UserProfile.query.get_or_404(user_id)
    db.session.delete(user)
    db.session.commit()
    return jsonify({"message": "User deleted successfully!"})


# ======================== AI-Generated Responses ========================

@app.route('/api/ask/<int:user_id>', methods=['POST'])
def ask_ai(user_id):
    """Generate AI response based on stored user data."""
    print("ask_ai")
    user = UserProfile.query.get_or_404(user_id)
    data = request.get_json()
    question = data.get('question')

    if not question:
        return jsonify({'error': 'No question provided'}), 400

    # Build context from stored user details
    context = f"""
    User Details:
    Age: {user.age}, Gender: {user.gender}, Height: {user.height} cm, Weight: {user.weight} kg, BMI: {user.bmi}
    Health Conditions: {user.existing_conditions}, Allergies: {user.allergies}, Diet Type: {user.diet_type}
    Activity Level: {user.activity_level}, Primary Goal: {user.primary_goal}, Stress Level: {user.stress_level}
    """

    answer = ask_ollama(context, question)
    return jsonify({'question': question, 'answer': answer})

@app.route('/api/ask_with_picture/<int:user_id>', methods=['POST'])
def ask_ai_with_picture(user_id):
    print("ask_ai_with_picture")
    data = request.get_json()
    if 'image_base64' not in data:
        return jsonify({'error': 'No base64 image provided'}), 400

    user = UserProfile.query.get_or_404(user_id)
    question = data.get('question')
    concise="be concise and short as possible"
    if not question:
        return jsonify({'error': 'No question provided'}), 400

    decoded_data = base64.b64decode(data['image_base64'])
    temp_path = 'temp_image.png'
    with open(temp_path, 'wb') as f:
        f.write(decoded_data)

    context = f"""
    User Details:
    Age: {user.age}, Gender: {user.gender}, Height: {user.height} cm, Weight: {user.weight} kg, BMI: {user.bmi}
    Health Conditions: {user.existing_conditions}, Allergies: {user.allergies}, Diet Type: {user.diet_type}
    Activity Level: {user.activity_level}, Primary Goal: {user.primary_goal}, Stress Level: {user.stress_level}
    """

    response = ollama.chat(
        model=MODEL_NAME_FOR_PICTURES,
        messages=[
            {
                'role': 'user',
                'content': question+ concise + context,
                'images': [temp_path],
            }
        ],
    )

    return jsonify({'question': question, 'answer': response.message.content})



# ======================== Run Flask Server ========================
if __name__ == '__main__':
    app.run(debug=True)
