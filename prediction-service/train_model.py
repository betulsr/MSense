import os
import torch
import numpy as np
import pandas as pd
from torch import nn
from sklearn.preprocessing import StandardScaler
from joblib import dump
from pathlib import Path

# Feature columns that match our DynamoDB data
FEATURE_COLUMNS = ['heart_rate', 'rmssd', 'temperature', 'steps', 'sleep_duration']

class FatigueLSTM(nn.Module):
    def __init__(self, input_dim=5, hidden_dim=32):
        super().__init__()
        self.lstm = nn.LSTM(input_dim, hidden_dim, batch_first=True)
        self.fc = nn.Linear(hidden_dim, 3)  # 3 outputs for 1, 2, 3 minutes ahead
        
    def forward(self, x):
        # Input shape: [batch_size, seq_len, input_dim]
        lstm_out, _ = self.lstm(x)
        return self.fc(lstm_out[:, -1, :])  # Take last timestep

def generate_synthetic_data(n_samples=1000):
    """Generate synthetic data for training."""
    np.random.seed(42)
    
    # Generate random features
    data = {
        'heart_rate': np.random.normal(70, 10, n_samples),  # Heart rate between 50-90
        'rmssd': np.random.normal(50, 20, n_samples),      # RMSSD between 10-90
        'temperature': np.random.normal(37, 0.5, n_samples), # Body temp between 36-38
        'steps': np.random.randint(0, 1000, n_samples),     # Steps between 0-1000
        'sleep_duration': np.random.normal(7, 2, n_samples) # Sleep hours between 3-11
    }
    
    # Create DataFrame
    df = pd.DataFrame(data)
    
    # Generate synthetic VAS scores (1-9) based on features
    vas_scores = []
    for _, row in df.iterrows():
        # Higher heart rate, lower RMSSD, and lower sleep -> higher fatigue
        base_score = 5.0
        hr_effect = (row['heart_rate'] - 70) * 0.05
        rmssd_effect = (50 - row['rmssd']) * 0.02
        sleep_effect = (7 - row['sleep_duration']) * 0.3
        
        # Combine effects and clip to VAS range
        vas = base_score + hr_effect + rmssd_effect + sleep_effect
        vas = np.clip(vas, 1, 9)
        vas_scores.append(vas)
    
    df['vas'] = vas_scores
    
    # Create future VAS scores (1, 2, 3 minutes ahead)
    for i in range(1, 4):
        df[f'vas_{i}min'] = df['vas'].shift(-i)
    
    # Drop rows with NaN (last 3 rows will have NaN future values)
    df = df.dropna()
    
    return df

def prepare_data(df):
    """Prepare data for training."""
    # Split features and targets
    X = df[FEATURE_COLUMNS].values
    y = df[['vas_1min', 'vas_2min', 'vas_3min']].values
    
    # Scale features
    feature_scaler = StandardScaler()
    X_scaled = feature_scaler.fit_transform(X)
    
    # Scale targets
    target_scaler = StandardScaler()
    y_scaled = target_scaler.fit_transform(y)
    
    return X_scaled, y_scaled, feature_scaler, target_scaler

def train_model(X, y, model, epochs=100, batch_size=32):
    """Train the model."""
    criterion = nn.MSELoss()
    optimizer = torch.optim.Adam(model.parameters())
    
    # Convert to PyTorch tensors
    X = torch.FloatTensor(X)
    y = torch.FloatTensor(y)
    
    # Add sequence dimension
    X = X.unsqueeze(1)  # Shape: [batch_size, seq_len=1, input_dim]
    
    # Training loop
    for epoch in range(epochs):
        model.train()
        
        # Forward pass
        outputs = model(X)
        loss = criterion(outputs, y)
        
        # Backward pass
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        
        if (epoch + 1) % 10 == 0:
            print(f'Epoch [{epoch+1}/{epochs}], Loss: {loss.item():.4f}')

def main():
    print("Generating synthetic training data...")
    df = generate_synthetic_data()
    print(f"Generated {len(df)} samples")
    
    print("\nPreparing data...")
    X, y, feature_scaler, target_scaler = prepare_data(df)
    print(f"Feature shape: {X.shape}")
    print(f"Target shape: {y.shape}")
    
    print("\nInitializing model...")
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    model = FatigueLSTM(input_dim=len(FEATURE_COLUMNS)).to(device)
    print(f"Model architecture:\n{model}")
    
    print("\nTraining model...")
    train_model(X, y, model)
    
    print("\nSaving model and scalers...")
    # Create models directory if it doesn't exist
    models_dir = Path("models")
    models_dir.mkdir(exist_ok=True)
    
    # Save model
    torch.save(model.state_dict(), models_dir / "fatigue_model.pth")
    print("✓ Saved model weights")
    
    # Save scalers
    dump(feature_scaler, models_dir / "feature_scaler.joblib")
    dump(target_scaler, models_dir / "target_scaler.joblib")
    print("✓ Saved scalers")
    
    print("\nDone! Model and scalers saved to ./models/")

if __name__ == "__main__":
    main()
