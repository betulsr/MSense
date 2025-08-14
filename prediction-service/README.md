# MSense Prediction Service

Python Flask API server with ML models for real-time fatigue prediction.

## 🚀 Getting Started

### Prerequisites
- Python 3.9+
- pip package manager
- AWS Account with DynamoDB access

### Installation
```bash
# Install dependencies
pip3 install -r requirements.txt

# Configure environment
cp .env.template .env
# Edit .env with your AWS credentials

# Run the service
python3 prediction_service.py
```

## 🔧 Configuration

### Environment Variables (.env)
```bash
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-2
DYNAMODB_TABLE=processed_data
```

### AWS Setup
1. Create DynamoDB table named `processed_data`
2. Configure IAM user with DynamoDB permissions
3. Set up IoT sensors to populate the table

## 🏗️ Architecture

```
prediction_service.py         # Main Flask application
├── get_latest_data()        # DynamoDB data fetching
├── make_prediction()        # ML model inference
├── update_predictions()     # Background polling thread
└── /current-predictions     # REST API endpoint

models/
├── fatigue_model.pth        # Trained PyTorch LSTM model
├── feature_scaler.joblib    # Input feature scaler
└── target_scaler.joblib     # Output value scaler

verify_aws_credentials.py    # AWS connection testing
train_model.py              # Model training script
```

## 🤖 ML Model

### Architecture
- **Type**: LSTM (Long Short-Term Memory)
- **Framework**: PyTorch
- **Input Features**: 5 sensors (heart rate, HRV, temperature, steps, sleep)
- **Output**: 3 predictions (15min, 30min, 45min, 60min ahead)
- **Scale**: 0-9 fatigue rating

### Model Training
```python
# LSTM Architecture
class FatigueLSTM(torch.nn.Module):
    def __init__(self, input_dim=5, hidden_dim=32):
        super().__init__()
        self.lstm = torch.nn.LSTM(input_dim, hidden_dim, batch_first=True)
        self.linear = torch.nn.Linear(hidden_dim, 3)
```

## 📊 Data Pipeline

### Input Data Format (DynamoDB)
```json
{
  "hr_mean": 72.5,              # Heart rate (BPM)
  "HRV_RMSSD_mean": 45.2,       # Heart rate variability  
  "objectTemp_mean": 36.8,      # Body temperature (°C)
  "steps_sum": 8420,            # Daily step count
  "activity_mean": 0.65         # Activity level (0-1)
}
```

### Output Format (API Response)
```json
{
  "status": "success",
  "predictions": [6.2, 7.1, 7.8, 8.3],
  "next_minutes": [15, 30, 45, 60],
  "timestamp": "2025-08-13T22:30:00.123456",
  "source": "aws_data"
}
```

## 🌐 API Endpoints

### GET `/current-predictions`
Returns current fatigue predictions

**Response:**
```json
{
  "status": "success",
  "predictions": [6.2, 7.1, 7.8, 8.3],
  "next_minutes": [15, 30, 45, 60],
  "timestamp": "2025-08-13T22:30:00.123456"
}
```

### GET `/health`
Health check endpoint

**Response:**
```json
{
  "status": "healthy"
}
```

### GET `/`
Welcome message

## 🔄 Background Processing

The service runs a background thread that:
1. **Polls DynamoDB** every 5 minutes
2. **Fetches latest sensor data** from the `processed_data` table
3. **Runs ML inference** using the trained LSTM model
4. **Caches predictions** in memory for API serving
5. **Handles errors gracefully** with fallback to test data

## 🧪 Testing

### Test AWS Connection
```bash
python3 verify_aws_credentials.py
```

### Test API Endpoints
```bash
# Health check
curl http://localhost:5001/health

# Get predictions
curl http://localhost:5001/current-predictions
```

### Mock Data Mode
If no real data is available, the service automatically serves test data:
```json
{
  "predictions": [6.2, 7.1, 7.8, 8.3],
  "source": "test_data"
}
```

## 🚀 Deployment

### Local Development
```bash
python3 prediction_service.py
# Server runs on http://localhost:5001
```

### Production (AWS EC2)
```bash
# Install dependencies
pip3 install -r requirements.txt

# Set environment variables
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_REGION=us-east-2
export DYNAMODB_TABLE=processed_data

# Run with gunicorn (production WSGI server)
pip3 install gunicorn
gunicorn -w 4 -b 0.0.0.0:5001 prediction_service:app
```

### Docker Deployment
```dockerfile
FROM python:3.9-slim
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5001
CMD ["python3", "prediction_service.py"]
```

## 📦 Dependencies

- **flask**: Web framework for API serving
- **boto3**: AWS SDK for DynamoDB access
- **torch**: PyTorch for ML model inference
- **scikit-learn**: Data preprocessing and scaling
- **pandas/numpy**: Data manipulation
- **python-dotenv**: Environment variable management
- **flask-cors**: Cross-origin resource sharing

## 🔒 Security

- **Environment Variables**: Sensitive credentials stored in .env
- **CORS Configuration**: Proper cross-origin headers
- **Input Validation**: Data sanitization and error handling
- **AWS IAM**: Minimal required permissions for DynamoDB

## 📈 Monitoring

- **Health Endpoint**: `/health` for uptime monitoring
- **Logging**: Comprehensive logging for debugging
- **Error Handling**: Graceful degradation with test data
- **Performance**: Background threading for non-blocking API
