from flask import Flask, jsonify
from datetime import datetime
import numpy as np
import pandas as pd
import boto3
import os
import torch
import threading
import time
from flask_cors import CORS
from dotenv import load_dotenv
import joblib
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Validate required environment variables
required_env_vars = ['AWS_REGION', 'DYNAMODB_TABLE']
missing_vars = [var for var in required_env_vars if not os.getenv(var)]
if missing_vars:
    raise ValueError(f"Missing required environment variables: {', '.join(missing_vars)}")

app = Flask(__name__)
CORS(app, resources={
    r"/*": {
        "origins": "*",
        "methods": ["GET", "POST", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "Accept"]
    }
})

# Model configuration
class FatigueLSTM(torch.nn.Module):
    def __init__(self, input_dim=5, hidden_dim=32):
        super().__init__()
        self.lstm = torch.nn.LSTM(input_dim, hidden_dim, batch_first=True)
        self.linear = torch.nn.Linear(hidden_dim, 3)
        
    def forward(self, x):
        lstm_out, _ = self.lstm(x)
        out = self.linear(lstm_out[:, -1, :])
        return out

# Global variables
latest_predictions = {
    'status': 'error',
    'error': 'No predictions available yet'
}
prediction_lock = threading.Lock()

def get_latest_data():
    """Get latest data from DynamoDB."""
    try:
        logger.info("Connecting to DynamoDB...")
        # Initialize DynamoDB client using environment variables
        region = os.getenv('AWS_REGION')
        logger.info(f"Using AWS region: {region}")
        session = boto3.Session(region_name=region)
        dynamodb = session.resource('dynamodb', region_name=region)
        
        # Get table
        logger.info("Getting table...")
        table = dynamodb.Table(os.getenv('DYNAMODB_TABLE'))
        
        # Get latest item
        logger.info("Scanning table...")
        response = table.scan(
            Limit=1
        )
        
        if not response['Items']:
            logger.warning("No data found in DynamoDB")
            return None
            
        logger.info("Found data in DynamoDB")
            
        # Convert to DataFrame with consistent feature order
        features = ['heart_rate', 'rmssd', 'temperature', 'steps', 'sleep_duration']
        data = {}
        item = response['Items'][0]
        
        # Map DynamoDB fields to feature names
        field_mapping = {
            'heart_rate': 'hr_mean',
            'rmssd': 'HRV_RMSSD_mean',
            'temperature': 'objectTemp_mean',
            'steps': 'steps_sum',
            'sleep_duration': 'activity_mean'
        }
        
        # Create DataFrame with consistent feature order
        for feature in features:
            dynamo_field = field_mapping[feature]
            data[feature] = [float(item.get(dynamo_field, 0))]
            
        df = pd.DataFrame(data)
        logger.info(f"DataFrame shape: {df.shape}")
        logger.info(f"DataFrame columns: {df.columns.tolist()}")
        return df
        
    except Exception as e:
        logger.error(f"Error fetching data: {str(e)}")
        return None

def make_prediction(data):
    """Make predictions using the model."""
    try:
        # Load model and scaler if not loaded
        if not hasattr(make_prediction, 'model') or not hasattr(make_prediction, 'scaler'):
            model_dir = os.path.join(os.path.dirname(__file__), 'models')
            model_path = os.path.join(model_dir, 'fatigue_model.pth')
            scaler_path = os.path.join(model_dir, 'feature_scaler.joblib')
            
            if not os.path.exists(model_path) or not os.path.exists(scaler_path):
                logger.error("Model or scaler file not found")
                return None
                
            logger.info("Loading model and scaler...")
            # Load and inspect model state
            state_dict = torch.load(model_path, map_location=torch.device('cpu'))
            logger.info(f"State dict keys: {state_dict.keys()}")
            
            # Initialize model with same dimensions
            input_dim = state_dict['lstm.weight_ih_l0'].shape[1]
            hidden_dim = state_dict['lstm.weight_ih_l0'].shape[0] // 4
            logger.info(f"Detected dimensions: input_dim={input_dim}, hidden_dim={hidden_dim}")
            
            # Create model with correct dimensions
            model = FatigueLSTM(input_dim=input_dim, hidden_dim=hidden_dim)
            
            # Try to load state dict
            try:
                # Rename state dict keys to match our model
                fixed_state_dict = {}
                for k, v in state_dict.items():
                    if k == 'fc.weight':
                        fixed_state_dict['linear.weight'] = v
                    elif k == 'fc.bias':
                        fixed_state_dict['linear.bias'] = v
                    else:
                        fixed_state_dict[k] = v
                        
                model.load_state_dict(fixed_state_dict)
                logger.info("Model loaded successfully with fixed state dict")
            except Exception as e:
                logger.error(f"Error loading state dict: {e}")
                return None
            
            model.eval()
            make_prediction.model = model
            
            # Load scaler
            make_prediction.scaler = joblib.load(scaler_path)
            logger.info("Model and scaler loaded successfully")
        
        # Scale input data
        scaled_data = make_prediction.scaler.transform(data)
        logger.info(f"Scaled data shape: {scaled_data.shape}")
        
        # Convert to tensor
        data_tensor = torch.FloatTensor(scaled_data).unsqueeze(0)  # Add batch dimension
        logger.info(f"Input tensor shape: {data_tensor.shape}")
        
        # Make prediction
        with torch.no_grad():
            predictions = make_prediction.model(data_tensor)
            
        # Convert to 0-9 range
        predictions = torch.sigmoid(predictions).numpy() * 9
        predictions = np.clip(predictions, 0, 9)  # Ensure values are between 0-9
        predictions = np.round(predictions, 1)  # Round to 1 decimal place
        logger.info(f"Final predictions: {predictions[0]}")
        return predictions[0]  # Return first batch
        
    except Exception as e:
        logger.error(f"Error making predictions: {str(e)}")
        logger.error(f"Error details: {str(e.__class__.__name__)}")
        import traceback
        logger.error(traceback.format_exc())
        return None

def update_predictions():
    """Update predictions in a loop."""
    global latest_predictions
    logger.info("Starting prediction updates...")
    
    while True:
        try:
            # Get latest data
            logger.info("Fetching latest data...")
            data = get_latest_data()
            if data is None:
                logger.warning("No data available, retrying in 60s")
                time.sleep(60)
                continue
                
            # Make predictions
            logger.info("Making predictions...")
            predictions = make_prediction(data)
            if predictions is None:
                logger.error("Failed to make predictions, retrying in 60s")
                time.sleep(60)
                continue
            
            # Update cache
            logger.info("Updating predictions cache...")
            with prediction_lock:
                latest_predictions.clear()
                latest_predictions.update({
                    'status': 'success',
                    'predictions': predictions.tolist(),
                    'timestamp': datetime.now().isoformat(),
                    'next_minutes': [1, 2, 3]
                })
            logger.info("Cache updated successfully")
            
            # Wait 5 minutes before next update
            logger.info("Waiting 5 minutes before next update...")
            time.sleep(300)
            
        except Exception as e:
            logger.error(f"Error in update loop: {str(e)}")
            time.sleep(60)

@app.route('/current-predictions')
def get_current_predictions():
    """Get the current predictions."""
    try:
        with prediction_lock:
            # If no real predictions available, provide test data
            if latest_predictions.get('status') == 'error' or 'predictions' not in latest_predictions:
                logger.info("No real predictions available, serving test data")
                test_predictions = {
                    'status': 'success',
                    'predictions': [6.2, 7.1, 7.8, 8.3],  # Sample fatigue predictions
                    'timestamp': datetime.now().isoformat(),
                    'next_minutes': [15, 30, 45, 60],
                    'source': 'test_data'  # Indicate this is test data
                }
                response = jsonify(test_predictions)
            else:
                logger.info("Serving real predictions from AWS")
                response = jsonify(latest_predictions)
            
            # Add CORS headers
            response.headers.add('Access-Control-Allow-Origin', '*')
            response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
            return response
            
    except Exception as e:
        logger.error(f"Error serving predictions: {str(e)}")
        return jsonify({
            'status': 'error',
            'error': 'Internal server error'
        }), 500

@app.route('/')
def index():
    """Serve the dashboard."""
    return "Welcome to the fatigue prediction service"

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy'
    })

if __name__ == '__main__':
    # Start prediction update thread
    update_thread = threading.Thread(target=update_predictions, daemon=True)
    update_thread.start()
    logger.info("Started prediction update thread")
    
    # Start Flask server
    logger.info("Starting Flask server...")
    app.run(host='0.0.0.0', port=5001, threaded=True)
