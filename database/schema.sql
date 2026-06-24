-- BonVoyage MySQL Schema
-- Database: bonvoyage

CREATE DATABASE IF NOT EXISTS bonvoyage;
USE bonvoyage;

-- Users (customers, agents, admins)
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  member_id VARCHAR(20) UNIQUE,
  username VARCHAR(50) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  email VARCHAR(100) NOT NULL,
  role ENUM('user', 'agent', 'admin') NOT NULL DEFAULT 'user',
  full_name VARCHAR(100),
  ic_passport VARCHAR(50),
  phone VARCHAR(30),
  status ENUM('active', 'suspended', 'deleted') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Agent company profiles (linked to users with role=agent)
CREATE TABLE IF NOT EXISTS agent_profiles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  agent_id VARCHAR(20) NOT NULL UNIQUE,
  user_id INT NOT NULL UNIQUE,
  company_name VARCHAR(150) NOT NULL,
  phone VARCHAR(30),
  location VARCHAR(200),
  logo_path VARCHAR(500),
  social_facebook VARCHAR(200),
  social_instagram VARCHAR(200),
  social_website VARCHAR(200),
  rating DECIMAL(3,2) DEFAULT 0.00,
  chat_response_rate INT DEFAULT 100,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Travel packages (uploaded by agents)
CREATE TABLE IF NOT EXISTS travel_packages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  agent_id INT NOT NULL,
  destination VARCHAR(150) NOT NULL,
  description TEXT NOT NULL,
  attractions TEXT,
  trip_type ENUM('solo', 'group') NOT NULL DEFAULT 'group',
  max_people INT NOT NULL DEFAULT 10,
  travel_date DATE NOT NULL,
  price_per_person DECIMAL(10,2) NOT NULL,
  promo_price DECIMAL(10,2),
  promo_end DATE,
  schedule_file_path VARCHAR(500),
  status ENUM('active', 'inactive', 'deleted') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (agent_id) REFERENCES agent_profiles(id) ON DELETE CASCADE
);

-- Package images
CREATE TABLE IF NOT EXISTS package_images (
  id INT AUTO_INCREMENT PRIMARY KEY,
  package_id INT NOT NULL,
  image_path VARCHAR(500) NOT NULL,
  image_type ENUM('hotel', 'food', 'attraction', 'other') DEFAULT 'other',
  FOREIGN KEY (package_id) REFERENCES travel_packages(id) ON DELETE CASCADE
);

-- Bookings
CREATE TABLE IF NOT EXISTS bookings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  package_id INT NOT NULL,
  agent_id INT NOT NULL,
  guest_name VARCHAR(100) NOT NULL,
  ic_passport VARCHAR(50) NOT NULL,
  num_people INT NOT NULL DEFAULT 1,
  special_requirements TEXT,
  voucher_code VARCHAR(50),
  discount_amount DECIMAL(10,2) DEFAULT 0,
  total_price DECIMAL(10,2) NOT NULL,
  payment_status ENUM('pending', 'paid', 'refunded') DEFAULT 'pending',
  status ENUM('pending', 'confirmed', 'cancelled', 'completed') DEFAULT 'pending',
  travel_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (package_id) REFERENCES travel_packages(id),
  FOREIGN KEY (agent_id) REFERENCES agent_profiles(id)
);

-- Reviews (only after trip completion)
CREATE TABLE IF NOT EXISTS reviews (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  package_id INT NOT NULL,
  agent_id INT NOT NULL,
  booking_id INT NOT NULL,
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT NOT NULL,
  status ENUM('active', 'reported', 'removed') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (package_id) REFERENCES travel_packages(id),
  FOREIGN KEY (agent_id) REFERENCES agent_profiles(id),
  FOREIGN KEY (booking_id) REFERENCES bookings(id)
);

-- Vouchers
CREATE TABLE IF NOT EXISTS vouchers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,
  discount_type ENUM('percent', 'fixed') NOT NULL DEFAULT 'percent',
  discount_value DECIMAL(10,2) NOT NULL,
  min_purchase DECIMAL(10,2) DEFAULT 0,
  max_uses INT DEFAULT 100,
  used_count INT DEFAULT 0,
  valid_from DATE,
  valid_until DATE,
  status ENUM('active', 'inactive') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Platform promotions
CREATE TABLE IF NOT EXISTS promotions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  description TEXT NOT NULL,
  discount_percent DECIMAL(5,2),
  package_id INT,
  valid_from DATE,
  valid_until DATE,
  status ENUM('active', 'inactive') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (package_id) REFERENCES travel_packages(id) ON DELETE SET NULL
);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  agent_id INT,
  target_role ENUM('user', 'agent', 'all') DEFAULT 'user',
  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  is_read TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (agent_id) REFERENCES agent_profiles(id) ON DELETE CASCADE
);

-- Chat messages
CREATE TABLE IF NOT EXISTS chat_messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sender_id INT NOT NULL,
  receiver_id INT NOT NULL,
  message TEXT NOT NULL,
  is_read TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (sender_id) REFERENCES users(id),
  FOREIGN KEY (receiver_id) REFERENCES users(id)
);

-- Review reports / complaints
CREATE TABLE IF NOT EXISTS review_reports (
  id INT AUTO_INCREMENT PRIMARY KEY,
  review_id INT NOT NULL,
  reporter_id INT NOT NULL,
  reason TEXT NOT NULL,
  status ENUM('pending', 'resolved', 'dismissed') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (review_id) REFERENCES reviews(id),
  FOREIGN KEY (reporter_id) REFERENCES users(id)
);

-- System settings
CREATE TABLE IF NOT EXISTS system_settings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  setting_key VARCHAR(100) NOT NULL UNIQUE,
  setting_value TEXT NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
