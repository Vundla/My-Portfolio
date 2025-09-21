import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.preprocessing import StandardScaler
import joblib
import json
from datetime import datetime

class MineralInvestmentPredictor:
    def __init__(self):
        self.model = None
        self.scaler = StandardScaler()
        self.feature_names = [
            'reserve_tonnes', 'price_trend', 'logistics_score', 
            'governance_score', 'extraction_cost', 'transport_cost',
            'political_risk', 'environmental_score', 'proximity_to_ports',
            'energy_cost_index', 'local_refining_capacity'
        ]
    
    def create_synthetic_dataset(self, n_samples=100):
        """Create synthetic dataset for mineral investment scoring"""
        np.random.seed(42)
        
        # Generate synthetic data for African mineral sites
        data = {
            'country_index': np.random.randint(0, 54, n_samples),  # 54 African countries
            'reserve_tonnes': np.random.lognormal(8, 1.5, n_samples),  # Log-normal distribution
            'price_trend': np.random.normal(0.02, 0.05, n_samples),  # Price trend %
            'logistics_score': np.random.beta(2, 2, n_samples),  # Beta distribution 0-1
            'governance_score': np.random.beta(2, 3, n_samples),  # Slightly skewed lower
            'extraction_cost': np.random.gamma(2, 50, n_samples),  # Cost per tonne
            'transport_cost': np.random.gamma(1.5, 30, n_samples),  # Transport cost
            'political_risk': np.random.beta(3, 2, n_samples),  # Higher risk skew
            'environmental_score': np.random.beta(2.5, 2.5, n_samples),  # Environmental compliance
            'proximity_to_ports': np.random.exponential(200, n_samples),  # Distance in km
            'energy_cost_index': np.random.gamma(2, 0.8, n_samples),  # Energy cost multiplier
            'local_refining_capacity': np.random.beta(1.5, 3, n_samples)  # Local processing capability
        }
        
        df = pd.DataFrame(data)
        
        # Create target variable (investment_score) based on features
        # Higher reserves, better governance, lower costs = higher score
        investment_score = (
            0.2 * np.log(df['reserve_tonnes'] + 1) / 10 +
            0.15 * df['price_trend'] * 10 +
            0.2 * df['logistics_score'] +
            0.25 * df['governance_score'] +
            0.1 * (1 - df['political_risk']) +
            0.1 * df['environmental_score'] -
            0.05 * np.log(df['extraction_cost'] + 1) / 5 -
            0.03 * np.log(df['transport_cost'] + 1) / 5 +
            0.08 * df['local_refining_capacity'] -
            0.02 * np.log(df['proximity_to_ports'] + 1) / 10
        )
        
        # Normalize to 0-1 range and add some noise
        investment_score = (investment_score - investment_score.min()) / (investment_score.max() - investment_score.min())
        investment_score += np.random.normal(0, 0.05, n_samples)
        investment_score = np.clip(investment_score, 0, 1)
        
        df['investment_score'] = investment_score
        return df
    
    def train_model(self, df):
        """Train the mineral investment prediction model"""
        # Prepare features and target
        X = df[self.feature_names]
        y = df['investment_score']
        
        # Split the data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )
        
        # Scale features
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        # Train model
        self.model = RandomForestRegressor(
            n_estimators=100,
            max_depth=10,
            min_samples_split=5,
            random_state=42
        )
        self.model.fit(X_train_scaled, y_train)
        
        # Evaluate model
        train_predictions = self.model.predict(X_train_scaled)
        test_predictions = self.model.predict(X_test_scaled)
        
        train_mse = mean_squared_error(y_train, train_predictions)
        test_mse = mean_squared_error(y_test, test_predictions)
        train_r2 = r2_score(y_train, train_predictions)
        test_r2 = r2_score(y_test, test_predictions)
        
        print(f"Training MSE: {train_mse:.4f}")
        print(f"Test MSE: {test_mse:.4f}")
        print(f"Training R²: {train_r2:.4f}")
        print(f"Test R²: {test_r2:.4f}")
        
        # Feature importance
        feature_importance = pd.DataFrame({
            'feature': self.feature_names,
            'importance': self.model.feature_importances_
        }).sort_values('importance', ascending=False)
        
        print("\nFeature Importance:")
        print(feature_importance)
        
        return {
            'train_mse': train_mse,
            'test_mse': test_mse,
            'train_r2': train_r2,
            'test_r2': test_r2,
            'feature_importance': feature_importance.to_dict('records')
        }
    
    def predict_investment_score(self, features):
        """Predict investment score for new mineral site"""
        if self.model is None:
            raise ValueError("Model not trained. Call train_model() first.")
        
        # Ensure features are in correct order
        feature_values = [features.get(name, 0) for name in self.feature_names]
        feature_array = np.array(feature_values).reshape(1, -1)
        
        # Scale features and predict
        feature_scaled = self.scaler.transform(feature_array)
        score = self.model.predict(feature_scaled)[0]
        
        return max(0, min(1, score))  # Ensure score is between 0 and 1
    
    def save_model(self, filepath):
        """Save trained model and scaler"""
        if self.model is None:
            raise ValueError("No model to save. Train model first.")
        
        model_data = {
            'model': self.model,
            'scaler': self.scaler,
            'feature_names': self.feature_names,
            'timestamp': datetime.now().isoformat()
        }
        
        joblib.dump(model_data, filepath)
        print(f"Model saved to {filepath}")
    
    def load_model(self, filepath):
        """Load trained model and scaler"""
        model_data = joblib.load(filepath)
        self.model = model_data['model']
        self.scaler = model_data['scaler']
        self.feature_names = model_data['feature_names']
        print(f"Model loaded from {filepath}")

# Example usage
if __name__ == "__main__":
    # Create and train model
    predictor = MineralInvestmentPredictor()
    
    # Generate synthetic dataset
    print("Generating synthetic mineral investment dataset...")
    df = predictor.create_synthetic_dataset(200)
    
    # Train model
    print("\nTraining mineral investment prediction model...")
    metrics = predictor.train_model(df)
    
    # Save model
    predictor.save_model("minerals_invest_model.joblib")
    
    # Example prediction
    example_site = {
        'reserve_tonnes': 5000,
        'price_trend': 0.08,
        'logistics_score': 0.7,
        'governance_score': 0.6,
        'extraction_cost': 80,
        'transport_cost': 45,
        'political_risk': 0.3,
        'environmental_score': 0.8,
        'proximity_to_ports': 150,
        'energy_cost_index': 1.2,
        'local_refining_capacity': 0.4
    }
    
    score = predictor.predict_investment_score(example_site)
    print(f"\nExample investment score: {score:.3f}")
    
    print("\nReal-world data integration suggestions:")
    print("- World Bank governance indicators")
    print("- USGS mineral reserves database")
    print("- IMF commodity price data")
    print("- Transport and logistics performance indices")
    print("- Environmental and social governance (ESG) ratings")
    print("- Political risk assessment from rating agencies")