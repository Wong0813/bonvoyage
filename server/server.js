const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');

const app = express();
const port = 3000;

app.use(cors());

// Serve static files from 'uploads' folder
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}
app.use('/uploads', express.static(uploadsDir));

app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));

// Helper: save Base64 image to local disk and return relative URL path
function saveBase64Image(dataStr) {
  if (!dataStr || typeof dataStr !== 'string') {
    return dataStr;
  }
  const match = dataStr.match(/^data:(image\/[a-zA-Z0-9+.-]+);base64,(.+)$/);
  if (!match) {
    return dataStr;
  }

  const mimeType = match[1];
  const base64Data = match[2];
  const extension = mimeType.split('/')[1] || 'png';
  const cleanExtension = extension.split('+')[0];

  const filename = `img-${Date.now()}-${Math.round(Math.random() * 1E9)}.${cleanExtension}`;
  const filePath = path.join(uploadsDir, filename);

  try {
    fs.writeFileSync(filePath, Buffer.from(base64Data, 'base64'));
    return `/uploads/${filename}`;
  } catch (err) {
    console.error('Failed to save base64 image to disk:', err);
    return dataStr;
  }
}

// Database configuration
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'bonvoyage',
};

let pool;

async function initDb() {
  try {
    // Only attempt to auto-create database if we are running on localhost
    if (dbConfig.host === 'localhost') {
      const { database, ...connectConfig } = dbConfig;
      const connection = await mysql.createConnection(connectConfig);
      await connection.query(`CREATE DATABASE IF NOT EXISTS \`${database}\``);
      await connection.end();
    }

    // Create connection pool
    const poolConfig = {
      ...dbConfig,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0
    };

    // If using a cloud database, SSL might be required
    if (process.env.DB_SSL === 'true') {
      poolConfig.ssl = { rejectUnauthorized: false };
    }

    pool = mysql.createPool(poolConfig);

    console.log(`Connected to MySQL connection pool (${dbConfig.host}).`);
    await createTablesAndSeed();
  } catch (err) {
    console.error('Database initialization failed:', err);
    process.exit(1);
  }
}

async function createTablesAndSeed() {
  const connection = await pool.getConnection();
  try {
    // Start Transaction
    await connection.beginTransaction();

    // Create Tables
    await connection.query(`
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        member_id VARCHAR(20) UNIQUE,
        username VARCHAR(50) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        email VARCHAR(100) NOT NULL,
        role VARCHAR(20) NOT NULL DEFAULT 'user',
        full_name VARCHAR(100),
        ic_passport VARCHAR(50),
        phone VARCHAR(30),
        status VARCHAR(20) NOT NULL DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS agent_profiles (
        id INT AUTO_INCREMENT PRIMARY KEY,
        agent_id VARCHAR(20) NOT NULL UNIQUE,
        user_id INT NOT NULL UNIQUE,
        company_name VARCHAR(150) NOT NULL,
        phone VARCHAR(30),
        location VARCHAR(200),
        logo_path MEDIUMTEXT,
        social_facebook VARCHAR(200),
        social_instagram VARCHAR(200),
        social_website VARCHAR(200),
        rating DECIMAL(3,2) DEFAULT 0.00,
        chat_response_rate INT DEFAULT 100,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS travel_packages (
        id INT AUTO_INCREMENT PRIMARY KEY,
        agent_id INT NOT NULL,
        destination VARCHAR(150) NOT NULL,
        description TEXT NOT NULL,
        attractions TEXT,
        trip_type VARCHAR(20) NOT NULL DEFAULT 'group',
        max_people INT NOT NULL DEFAULT 10,
        travel_date DATE NOT NULL,
        price_per_person DECIMAL(10,2) NOT NULL,
        promo_price DECIMAL(10,2),
        promo_end DATE,
        schedule_file_path VARCHAR(500),
        status VARCHAR(20) NOT NULL DEFAULT 'active',
        category VARCHAR(50) NOT NULL DEFAULT 'Beach',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (agent_id) REFERENCES agent_profiles(id) ON DELETE CASCADE
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS package_images (
        id INT AUTO_INCREMENT PRIMARY KEY,
        package_id INT NOT NULL,
        image_path MEDIUMTEXT NOT NULL,
        image_type VARCHAR(20) DEFAULT 'other',
        FOREIGN KEY (package_id) REFERENCES travel_packages(id) ON DELETE CASCADE
      )
    `);

    await connection.query(`
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
        payment_status VARCHAR(20) DEFAULT 'pending',
        status VARCHAR(20) DEFAULT 'pending',
        travel_date DATE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (package_id) REFERENCES travel_packages(id),
        FOREIGN KEY (agent_id) REFERENCES agent_profiles(id)
      )
    `);

    try {
      const [categoryCols] = await connection.query(
        "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'travel_packages' AND COLUMN_NAME = 'category'",
        [dbName]
      );
      if (categoryCols.length === 0) {
        console.log("Adding 'category' column to 'travel_packages' table.");
        await connection.query("ALTER TABLE travel_packages ADD COLUMN category VARCHAR(50) DEFAULT 'Beach'");
      }
    } catch (err) {
      console.warn("Could not check/add 'category' column in travel_packages:", err);
    }

    try {
      const [cols] = await connection.query(
        "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'reviews' AND COLUMN_NAME = 'destination_id'",
        [dbName]
      );
      if (cols.length > 0) {
        console.log("Legacy reviews table detected. Dropping it to rebuild with correct package schema.");
        await connection.query("DROP TABLE IF EXISTS reviews");
      }
    } catch (e) {
      console.log("Error checking/dropping legacy reviews table:", e.message);
    }

    await connection.query(`
      CREATE TABLE IF NOT EXISTS reviews (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        package_id INT NOT NULL,
        agent_id INT NOT NULL,
        booking_id INT NOT NULL,
        rating INT NOT NULL,
        comment TEXT NOT NULL,
        status VARCHAR(20) DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (package_id) REFERENCES travel_packages(id),
        FOREIGN KEY (agent_id) REFERENCES agent_profiles(id),
        FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
      )
    `);

    try {
      await connection.query("ALTER TABLE reviews DROP COLUMN destination_id");
      console.log("Dropped legacy destination_id column from reviews table.");
    } catch (_) {}

    try {
      await connection.query("ALTER TABLE package_images MODIFY COLUMN image_path MEDIUMTEXT NOT NULL");
      console.log("Migrated package_images.image_path to MEDIUMTEXT.");
    } catch (e) {
      console.log("Error modifying package_images image_path column:", e.message);
    }

    try {
      await connection.query("ALTER TABLE agent_profiles MODIFY COLUMN logo_path MEDIUMTEXT");
      console.log("Migrated agent_profiles.logo_path to MEDIUMTEXT.");
    } catch (e) {
      console.log("Error modifying agent_profiles logo_path column:", e.message);
    }

    try {
      await connection.query("DELETE FROM package_images WHERE image_path LIKE 'data:%'");
      await connection.query("UPDATE agent_profiles SET logo_path = NULL WHERE logo_path LIKE 'data:%'");
      console.log("Cleaned up existing bloated base64 images from database.");
    } catch (e) {
      console.log("Error cleaning up base64 images:", e.message);
    }

    await connection.query(`
      CREATE TABLE IF NOT EXISTS vouchers (
        id INT AUTO_INCREMENT PRIMARY KEY,
        code VARCHAR(50) NOT NULL UNIQUE,
        discount_type VARCHAR(20) NOT NULL DEFAULT 'percent',
        discount_value DECIMAL(10,2) NOT NULL,
        min_purchase DECIMAL(10,2) DEFAULT 0,
        max_uses INT DEFAULT 100,
        used_count INT DEFAULT 0,
        valid_from DATE,
        valid_until DATE,
        status VARCHAR(20) DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS promotions (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(200) NOT NULL,
        description TEXT NOT NULL,
        discount_percent DECIMAL(5,2),
        package_id INT,
        valid_from DATE,
        valid_until DATE,
        status VARCHAR(20) DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT,
        agent_id INT,
        target_role VARCHAR(20) DEFAULT 'user',
        title VARCHAR(200) NOT NULL,
        message TEXT NOT NULL,
        is_read TINYINT(1) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS chat_messages (
        id INT AUTO_INCREMENT PRIMARY KEY,
        sender_id INT NOT NULL,
        receiver_id INT NOT NULL,
        message TEXT NOT NULL,
        is_read TINYINT(1) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS review_reports (
        id INT AUTO_INCREMENT PRIMARY KEY,
        review_id INT NOT NULL,
        reporter_id INT NOT NULL,
        reason TEXT NOT NULL,
        status VARCHAR(20) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS system_settings (
        id INT AUTO_INCREMENT PRIMARY KEY,
        setting_key VARCHAR(100) NOT NULL UNIQUE,
        setting_value TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS travel_news (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(200) NOT NULL,
        content TEXT NOT NULL,
        image_path VARCHAR(500),
        author VARCHAR(100) NOT NULL DEFAULT 'Admin',
        status VARCHAR(20) NOT NULL DEFAULT 'draft',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS wishlists (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        package_id INT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY unique_wishlist (user_id, package_id)
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS itinerary_items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        booking_id INT NOT NULL,
        day_number INT NOT NULL DEFAULT 1,
        time_slot VARCHAR(20) NOT NULL DEFAULT 'morning',
        activity VARCHAR(200) NOT NULL,
        location VARCHAR(200) NOT NULL,
        notes TEXT,
        FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
      )
    `);

    // Seed Data
    const [userCountRows] = await connection.query("SELECT COUNT(*) as cnt FROM users");
    const isDbEmpty = (userCountRows[0].cnt === 0);

    let customerUserId;
    let agentProfileId;

    if (isDbEmpty) {
      // Seed Admin
      await connection.query(
        "INSERT INTO users (member_id, username, password, email, role, full_name, status) " +
        "VALUES ('MEM000001', 'admin', 'admin123', 'admin@bonvoyage.com', 'admin', 'Administrator', 'active')"
      );

      // Seed Customer
      const [custInsertRes] = await connection.query(
        "INSERT INTO users (member_id, username, password, email, role, full_name, status) " +
        "VALUES ('MEM000002', 'customer', 'user123', 'customer@bonvoyage.com', 'user', 'John Customer', 'active')"
      );
      customerUserId = custInsertRes.insertId;

      // Seed Agent
      const [agentInsertRes] = await connection.query(
        "INSERT INTO users (member_id, username, password, email, role, full_name, phone, status) " +
        "VALUES ('MEM000003', 'agent', 'agent123', 'agent@bonvoyage.com', 'agent', 'Travel Agent', '0123456789', 'active')"
      );
      const agentUserId = agentInsertRes.insertId;

      // Seed Agent Profile
      const [profileRes] = await connection.query(
        "INSERT INTO agent_profiles (agent_id, user_id, company_name, phone, location, rating, chat_response_rate) " +
        "VALUES ('AGT000001', ?, 'Sunshine Travel Sdn Bhd', '0123456789', 'Kuala Lumpur, Malaysia', 4.50, 95)",
        [agentUserId]
      );
      agentProfileId = profileRes.insertId;
    } else {
      // Obtain customerUserId and agentProfileId if they exist in DB
      const [custRows] = await connection.query("SELECT id FROM users WHERE username = 'customer' LIMIT 1");
      if (custRows.length > 0) customerUserId = custRows[0].id;

      const [agentUserRows] = await connection.query("SELECT id FROM users WHERE username = 'agent' LIMIT 1");
      if (agentUserRows.length > 0) {
        const [profileRows] = await connection.query("SELECT id FROM agent_profiles WHERE user_id = ? LIMIT 1", [agentUserRows[0].id]);
        if (profileRows.length > 0) agentProfileId = profileRows[0].id;
      }
    }

    // Seed Travel Packages
    const defaultPackages = [
      {
        destination: 'Langkawi Island',
        description: 'Pristine beaches and duty-free shopping paradise.',
        attractions: 'Eagle Square\nPantai Cenang\nLangkawi Cable Car',
        trip_type: 'group',
        max_people: 20,
        travel_date: '2026-08-15',
        price_per_person: 850.00,
        promo_price: null,
        promo_end: null,
        category: 'Beach',
        images: ['https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80']
      },
      {
        destination: 'Penang Heritage',
        description: 'UNESCO heritage site with world-famous street food.',
        attractions: 'George Town\nPenang Hill\nKek Lok Si Temple',
        trip_type: 'solo',
        max_people: 1,
        travel_date: '2026-09-01',
        price_per_person: 450.00,
        promo_price: null,
        promo_end: null,
        category: 'Culture',
        images: ['https://images.unsplash.com/photo-1626014303757-6ec6a3855944?auto=format&fit=crop&w=800&q=80']
      },
      {
        destination: 'Kuala Lumpur City',
        description: 'Modern capital with iconic landmarks and culture.',
        attractions: 'Petronas Towers\nBatu Caves\nCentral Market',
        trip_type: 'group',
        max_people: 15,
        travel_date: '2026-07-20',
        price_per_person: 550.00,
        promo_price: null,
        promo_end: null,
        category: 'City',
        images: ['https://images.unsplash.com/photo-1595855759920-86582396756a?auto=format&fit=crop&w=800&q=80']
      },
      {
        destination: 'Santorini Getaway',
        description: 'White-washed villages perched on volcanic cliffs above the Aegean Sea.',
        attractions: 'Oia Sunset\nFira Caldera\nRed Beach',
        trip_type: 'group',
        max_people: 10,
        travel_date: '2026-09-10',
        price_per_person: 1299.00,
        promo_price: null,
        promo_end: null,
        category: 'Beach',
        images: ['https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?auto=format&fit=crop&w=800&q=80']
      },
      {
        destination: 'Bali Paradise Tour',
        description: 'Tropical paradise of lush rice terraces, ancient temples, and sandy beaches.',
        attractions: 'Ubud Monkey Forest\nTanah Lot Temple\nUluwatu Cliff',
        trip_type: 'group',
        max_people: 12,
        travel_date: '2026-08-25',
        price_per_person: 899.00,
        promo_price: null,
        promo_end: null,
        category: 'Beach',
        images: ['https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=800&q=80']
      },
      {
        destination: 'Tokyo Explorer',
        description: 'Neon-lit skyscrapers blending ultramodern technology with traditional temples.',
        attractions: 'Shibuya Crossing\nSenso-ji Temple\nMeiji Shrine',
        trip_type: 'group',
        max_people: 8,
        travel_date: '2026-10-05',
        price_per_person: 1599.00,
        promo_price: 1499.00,
        promo_end: '2026-09-15',
        category: 'City',
        images: ['https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=800&q=80']
      }
    ];

    let langkawiId = 0;
    let penangId = 0;
    let klId = 0;

    if (agentProfileId) {
      for (const pkg of defaultPackages) {
        const [existing] = await connection.query(
          "SELECT id FROM travel_packages WHERE destination = ? LIMIT 1",
          [pkg.destination]
        );
        let pkgId;
        if (existing.length === 0) {
          const [insertRes] = await connection.query(
            `INSERT INTO travel_packages (agent_id, destination, description, attractions, trip_type, max_people, travel_date, price_per_person, promo_price, promo_end, category, status)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')`,
            [agentProfileId, pkg.destination, pkg.description, pkg.attractions, pkg.trip_type, pkg.max_people, pkg.travel_date, pkg.price_per_person, pkg.promo_price, pkg.promo_end, pkg.category || 'Beach']
          );
          pkgId = insertRes.insertId;
        } else {
          pkgId = existing[0].id;
        }

        if (pkg.destination.includes('Langkawi')) langkawiId = pkgId;
        else if (pkg.destination.includes('Penang')) penangId = pkgId;
        else if (pkg.destination.includes('Kuala Lumpur')) klId = pkgId;

        const [imgCheck] = await connection.query("SELECT id FROM package_images WHERE package_id = ? LIMIT 1", [pkgId]);
        if (imgCheck.length === 0) {
          for (const imgUrl of pkg.images) {
            await connection.query(
              "INSERT INTO package_images (package_id, image_path, image_type) VALUES (?, ?, 'other')",
              [pkgId, imgUrl]
            );
          }
        }
      }
    }

    // Seed Bookings, Reviews, Chats, Notifications
    if (customerUserId && agentProfileId) {
      const [bookingCount] = await connection.query('SELECT COUNT(*) as cnt FROM bookings');
      if (bookingCount[0].cnt === 0) {
        const [b1Res] = await connection.query(
          `INSERT INTO bookings (user_id, package_id, agent_id, guest_name, ic_passport, num_people, special_requirements, total_price, payment_status, status, travel_date)
           VALUES (?, ?, ?, 'John Customer', 'IC12345678', 2, 'Vegetarian food preferred', 1360.00, 'paid', 'completed', '2026-05-10')`,
          [customerUserId, langkawiId, agentProfileId]
        );
        const b1Id = b1Res.insertId;

        await connection.query(
          `INSERT INTO bookings (user_id, package_id, agent_id, guest_name, ic_passport, num_people, special_requirements, total_price, payment_status, status, travel_date)
           VALUES (?, ?, ?, 'John Customer', 'IC12345678', 1, NULL, 550.00, 'paid', 'confirmed', '2026-07-20')`,
          [customerUserId, klId, agentProfileId]
        );

        await connection.query(
          `INSERT INTO bookings (user_id, package_id, agent_id, guest_name, ic_passport, num_people, special_requirements, total_price, payment_status, status, travel_date)
           VALUES (?, ?, ?, 'John Customer', 'IC12345678', 1, NULL, 450.00, 'pending', 'pending', '2026-09-01')`,
          [customerUserId, penangId, agentProfileId]
        );

        await connection.query(
          `INSERT INTO reviews (user_id, package_id, agent_id, booking_id, rating, comment, status)
           VALUES (?, ?, ?, ?, 5, 'Awesome trip! The mangrove tour was beautiful and the tour guide was friendly.', 'active')`,
          [customerUserId, langkawiId, agentProfileId, b1Id]
        );

        await connection.query('UPDATE agent_profiles SET rating = 5.00 WHERE id = ?', [agentProfileId]);

        await connection.query(`
          INSERT INTO itinerary_items (booking_id, day_number, time_slot, activity, location, notes) VALUES
          (?, 1, 'morning', 'Arrival & Check-in', 'Langkawi International Airport / Hotel', 'Meet agent guide at airport'),
          (?, 1, 'afternoon', 'Cable Car Ride', 'Langkawi Cable Car', 'Enjoy panoramic island view'),
          (?, 2, 'morning', 'Mangrove Tour', 'Kilim Karst Geoforest Park', 'Boat tour through mangrove and bat caves'),
          (?, 2, 'afternoon', 'Relax at Pantai Cenang', 'Pantai Cenang Beach', 'Free time on the beach'),
          (?, 2, 'evening', 'Seafood Dinner', 'Orkid Ria Restaurant', 'Indulge in fresh local seafood'),
          (?, 3, 'morning', 'Eagle Square Visit & Souvenirs', 'Dataran Lang (Eagle Square)', 'Take photos and buy souvenirs before departure')
        `, [b1Id, b1Id, b1Id, b1Id, b1Id, b1Id]);

        const [agentUser] = await connection.query("SELECT id FROM users WHERE username = 'agent'");
        const agentUserId = agentUser[0].id;

        await connection.query(`
          INSERT INTO chat_messages (sender_id, receiver_id, message, is_read) VALUES
          (?, ?, 'Hi there, is the Langkawi package still available for August?', 1),
          (?, ?, 'Yes, absolutely! We have slots open for August 15. You can book directly through the app.', 1),
          (?, ?, 'Great, thank you! I will proceed with the booking now.', 1)
        `, [customerUserId, agentUserId, agentUserId, customerUserId, customerUserId, agentUserId]);

        const [existingNotifs] = await connection.query('SELECT id FROM notifications WHERE user_id = ? AND title = ? LIMIT 1', [customerUserId, 'Welcome to BonVoyage!']);
        if (existingNotifs.length === 0) {
          await connection.query(`
            INSERT INTO notifications (user_id, agent_id, target_role, title, message, is_read) VALUES
            (?, NULL, 'user', 'Welcome to BonVoyage!', 'Explore our premium travel packages and plan your dream vacation today!', 0),
            (NULL, ?, 'agent', 'New Booking Received', 'You have received a new booking request for Langkawi Island from John Customer.', 0)
          `, [customerUserId, agentProfileId]);
        }
      }
    }

    // Seed Vouchers, Promotions, Settings, News
    const [voucherCount] = await connection.query('SELECT COUNT(*) as cnt FROM vouchers');
    if (voucherCount[0].cnt === 0) {
      await connection.query(`
        INSERT INTO vouchers (code, discount_type, discount_value, min_purchase, max_uses, valid_from, valid_until, status) VALUES
        ('WELCOME10', 'percent', 10.00, 100.00, 500, '2026-01-01', '2026-12-31', 'active'),
        ('SAVE50', 'fixed', 50.00, 300.00, 200, '2026-01-01', '2026-12-31', 'active')
      `);
    }

    const [promoCount] = await connection.query('SELECT COUNT(*) as cnt FROM promotions');
    if (promoCount[0].cnt === 0) {
      await connection.query(`
        INSERT INTO promotions (title, description, discount_percent, valid_from, valid_until, status) VALUES
        ('Summer Sale 2026', 'Get up to 20% off selected travel packages this summer!', 20.00, '2026-06-01', '2026-08-31', 'active'),
        ('Merdeka Special', 'Celebrate Merdeka with exclusive travel deals across Malaysia.', 15.00, '2026-06-01', '2026-09-30', 'active')
      `);
    }

    const [newsCount] = await connection.query('SELECT COUNT(*) as cnt FROM travel_news');
    if (newsCount[0].cnt === 0) {
      await connection.query(`
        INSERT INTO travel_news (title, content, author, status) VALUES
        ('New Tourist Attraction Opened in Penang', 'A stunning new cultural attraction has opened in George Town, offering visitors an immersive experience into Penang heritage and traditions.', 'Admin', 'published'),
        ('Malaysia Named Top 10 Travel Destination 2026', 'Malaysia has been named one of the top 10 travel destinations for 2026 by World Travel Awards.', 'Admin', 'published'),
        ('Langkawi Duty-Free Zone Expanded', 'The Langkawi duty-free shopping zone has been expanded with new retail outlets.', 'Admin', 'published')
      `);
    }

    const [settingsCount] = await connection.query('SELECT COUNT(*) as cnt FROM system_settings');
    if (settingsCount[0].cnt === 0) {
      await connection.query(`
        INSERT INTO system_settings (setting_key, setting_value) VALUES
        ('commission_rate', '10'),
        ('booking_cancel_days', '7'),
        ('payment_gateway', 'mock_stripe'),
        ('security_2fa', 'false')
      `);
    }

    await connection.commit();
    console.log('Database schemas created and seeded successfully.');
  } catch (err) {
    await connection.rollback();
    console.error('Error seeding database:', err);
  } finally {
    connection.release();
  }
}

// Helper to generate IDs
async function generateId(prefix, table, col) {
  const [rows] = await pool.query(`SELECT ${col} FROM ${table} WHERE ${col} LIKE ? ORDER BY ${col} DESC LIMIT 1`, [`${prefix}%`]);
  let next = 1;
  if (rows.length > 0) {
    const last = rows[0][col] || `${prefix}000000`;
    next = parseInt(last.replace(prefix, '')) + 1;
  }
  return `${prefix}${String(next).padStart(6, '0')}`;
}

// Helper: parse database rows to compatible string maps
function mapRow(row) {
  const map = {};
  for (const k in row) {
    if (row[k] instanceof Date) {
      map[k] = row[k].toISOString();
    } else if (row[k] !== null && row[k] !== undefined) {
      map[k] = String(row[k]);
    } else {
      map[k] = null;
    }
  }
  return map;
}

// ── API ROUTES ──────────────────────────────────────────────────────────────

// AUTH ENDPOINTS
app.post('/api/auth/login', async (req, res) => {
  const { username, password } = req.body;
  try {
    const [rows] = await pool.query('SELECT * FROM users WHERE username = ? AND password = ? LIMIT 1', [username, password]);
    if (rows.length === 0) return res.status(401).json({ error: 'Invalid credentials' });
    const user = mapRow(rows[0]);
    if (user.status === 'suspended') return res.status(403).json({ error: 'Account suspended. Contact administrator.' });
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/auth/register-customer', async (req, res) => {
  const { username, password, email, fullName } = req.body;
  try {
    const [check] = await pool.query('SELECT id FROM users WHERE username = ? OR email = ?', [username, email]);
    if (check.length > 0) return res.status(400).json({ error: 'Username or email already exists' });

    const memberId = await generateId('MEM', 'users', 'member_id');
    await pool.query(
      "INSERT INTO users (member_id, username, password, email, role, full_name, status) VALUES (?, ?, ?, ?, 'user', ?, 'active')",
      [memberId, username, password, email, fullName]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/auth/register-agent', async (req, res) => {
  const { username, password, email, companyName, phone, location } = req.body;
  try {
    const [check] = await pool.query('SELECT id FROM users WHERE username = ? OR email = ?', [username, email]);
    if (check.length > 0) return res.status(400).json({ error: 'Username or email already exists' });

    const memberId = await generateId('MEM', 'users', 'member_id');
    const [userRes] = await pool.query(
      "INSERT INTO users (member_id, username, password, email, role, full_name, phone, status) VALUES (?, ?, ?, ?, 'agent', ?, ?, 'active')",
      [memberId, username, password, email, companyName, phone]
    );
    const userId = userRes.insertId;

    const agentId = await generateId('AGT', 'agent_profiles', 'agent_id');
    await pool.query(
      'INSERT INTO agent_profiles (agent_id, user_id, company_name, phone, location) VALUES (?, ?, ?, ?, ?)',
      [agentId, userId, companyName, phone, location]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/auth/update-profile', async (req, res) => {
  const { userId, username, password, fullName, icPassport, phone, email } = req.body;
  try {
    const fields = [];
    const params = [];
    if (username) { fields.push('username = ?'); params.push(username); }
    if (password) { fields.push('password = ?'); params.push(password); }
    if (fullName) { fields.push('full_name = ?'); params.push(fullName); }
    if (icPassport) { fields.push('ic_passport = ?'); params.push(icPassport); }
    if (phone) { fields.push('phone = ?'); params.push(phone); }
    if (email) { fields.push('email = ?'); params.push(email); }

    if (fields.length > 0) {
      params.push(userId);
      await pool.query(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`, params);
    }
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/auth/reset-password', async (req, res) => {
  const { username, email, newPassword } = req.body;
  try {
    const [check] = await pool.query('SELECT id FROM users WHERE username = ? AND email = ?', [username, email]);
    if (check.length === 0) return res.status(404).json({ error: 'User not found' });
    await pool.query('UPDATE users SET password = ? WHERE username = ?', [newPassword, username]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/auth/user/:id', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM users WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ error: 'User not found' });
    res.json(mapRow(rows[0]));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Helper: dynamically apply active global promotions to a package row
async function applyActiveGlobalPromotion(row) {
  try {
    const [activePromos] = await pool.query(
      `SELECT * FROM promotions 
       WHERE (package_id = ? OR package_id IS NULL) 
       AND status = 'active' 
       AND (valid_from IS NULL OR valid_from <= CURRENT_DATE()) 
       AND (valid_until IS NULL OR valid_until >= CURRENT_DATE())
       ORDER BY package_id DESC, id DESC`,
      [row.id]
    );

    if (activePromos.length > 0) {
      const promo = activePromos[0];
      const discountPercent = parseFloat(promo.discount_percent);
      const globalPromoPrice = row.price_per_person * (1 - discountPercent / 100);

      // If there's no package-level promo price, or the global promotion is cheaper, apply it
      if (row.promo_price === null || row.promo_price === undefined || globalPromoPrice < parseFloat(row.promo_price)) {
        row.promo_price = globalPromoPrice;
        row.promo_end = promo.valid_until;
      }
    }
  } catch (err) {
    console.error('Error applying global promotion:', err);
  }
}

// TRAVEL PACKAGES ENDPOINTS
app.get('/api/packages', async (req, res) => {
  const { agentId, search, destination, tripType, minPrice, maxPrice, travelDate, allAdmin, category } = req.query;
  try {
    const conditions = [];
    const params = [];

    if (!allAdmin) {
      conditions.push("tp.status = 'active'");
    } else {
      conditions.push("tp.status != 'deleted'");
    }

    if (agentId) {
      conditions.push('tp.agent_id = ?');
      params.push(agentId);
    }
    if (category) {
      conditions.push('tp.category = ?');
      params.push(category);
    }
    if (search) {
      conditions.push('(tp.destination LIKE ? OR tp.description LIKE ? OR tp.attractions LIKE ? OR tp.category LIKE ?)');
      params.push(`%${search}%`, `%${search}%`, `%${search}%`, `%${search}%`);
    }
    if (destination) {
      conditions.push('tp.destination LIKE ?');
      params.push(`%${destination}%`);
    }
    if (tripType && tripType !== 'all') {
      conditions.push('tp.trip_type = ?');
      params.push(tripType);
    }
    if (minPrice) {
      conditions.push('tp.price_per_person >= ?');
      params.push(minPrice);
    }
    if (maxPrice) {
      conditions.push('tp.price_per_person <= ?');
      params.push(maxPrice);
    }
    if (travelDate) {
      conditions.push('tp.travel_date = ?');
      params.push(travelDate.split('T')[0]);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const [rows] = await pool.query(`
      SELECT tp.*, ap.company_name, ap.agent_id as agent_code, ap.rating as company_rating, ap.chat_response_rate
      FROM travel_packages tp
      JOIN agent_profiles ap ON tp.agent_id = ap.id
      ${whereClause}
      ORDER BY tp.id DESC
    `, params);

    const packages = [];
    for (const row of rows) {
      await applyActiveGlobalPromotion(row);
      const [images] = await pool.query('SELECT * FROM package_images WHERE package_id = ?', [row.id]);
      packages.push({
        ...mapRow(row),
        images: images.map(img => mapRow(img))
      });
    }
    res.json(packages);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/packages/:id', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT tp.*, ap.company_name, ap.agent_id as agent_code, ap.rating as company_rating, ap.chat_response_rate
      FROM travel_packages tp
      JOIN agent_profiles ap ON tp.agent_id = ap.id
      WHERE tp.id = ?
    `, [req.params.id]);

    if (rows.length === 0) return res.status(404).json({ error: 'Package not found' });
    const row = rows[0];
    await applyActiveGlobalPromotion(row);
    const [images] = await pool.query('SELECT * FROM package_images WHERE package_id = ?', [req.params.id]);
    res.json({
      ...mapRow(row),
      images: images.map(img => mapRow(img))
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/packages', async (req, res) => {
  const { agentProfileId, destination, description, attractions, tripType, maxPeople, travelDate, pricePerPerson, promoPrice, promoEnd, scheduleFilePath, images, category } = req.body;
  try {
    const [resInsert] = await pool.query(
      `INSERT INTO travel_packages (agent_id, destination, description, attractions, trip_type, max_people, travel_date, price_per_person, promo_price, promo_end, schedule_file_path, category)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [agentProfileId, destination, description, attractions, tripType, maxPeople, travelDate.split('T')[0], pricePerPerson, promoPrice, promoEnd ? promoEnd.split('T')[0] : null, scheduleFilePath, category || 'Beach']
    );
    const pkgId = resInsert.insertId;

    if (images && images.length > 0) {
      for (const img of images) {
        await pool.query(
          'INSERT INTO package_images (package_id, image_path, image_type) VALUES (?, ?, ?)',
          [pkgId, saveBase64Image(img.path), img.type || 'other']
        );
      }
    }
    res.json({ id: pkgId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/packages/:id', async (req, res) => {
  const { agentProfileId, destination, description, attractions, tripType, maxPeople, travelDate, pricePerPerson, promoPrice, promoEnd, scheduleFilePath, status, adminOverride, category } = req.body;
  try {
    const fields = [];
    const params = [];

    const add = (col, val) => {
      fields.push(`${col} = ?`);
      params.push(val);
    };

    if (destination !== undefined) add('destination', destination);
    if (description !== undefined) add('description', description);
    if (attractions !== undefined) add('attractions', attractions);
    if (tripType !== undefined) add('trip_type', tripType);
    if (maxPeople !== undefined) add('max_people', maxPeople);
    if (travelDate !== undefined) add('travel_date', travelDate ? travelDate.split('T')[0] : null);
    if (pricePerPerson !== undefined) add('price_per_person', pricePerPerson);
    
    // Support clearing promos
    if (promoPrice !== undefined) add('promo_price', promoPrice);
    if (promoEnd !== undefined) add('promo_end', promoEnd ? promoEnd.split('T')[0] : null);

    if (scheduleFilePath !== undefined) add('schedule_file_path', scheduleFilePath);
    if (status !== undefined) add('status', status);
    if (category !== undefined) add('category', category);
    if (adminOverride && agentProfileId !== undefined) add('agent_id', agentProfileId);

    if (fields.length === 0) return res.json({ success: true });

    params.push(req.params.id);
    let query = `UPDATE travel_packages SET ${fields.join(', ')} WHERE id = ?`;
    if (!adminOverride) {
      query += ' AND agent_id = ?';
      params.push(agentProfileId);
    }

    await pool.query(query, params);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/packages/:id', async (req, res) => {
  const { agentProfileId, adminOverride } = req.body;
  try {
    let query = "UPDATE travel_packages SET status = 'deleted' WHERE id = ?";
    const params = [req.params.id];
    if (!adminOverride) {
      query += ' AND agent_id = ?';
      params.push(agentProfileId);
    }
    await pool.query(query, params);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/packages/:id/images', async (req, res) => {
  const { images } = req.body;
  try {
    for (const img of images) {
      await pool.query(
        'INSERT INTO package_images (package_id, image_path, image_type) VALUES (?, ?, ?)',
        [req.params.id, saveBase64Image(img.path), img.type || 'other']
      );
    }
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/packages/images/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM package_images WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// AGENT PROFILES ENDPOINTS
app.get('/api/agents', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT ap.*, u.username, u.status as user_status
      FROM agent_profiles ap
      JOIN users u ON ap.user_id = u.id
      ORDER BY ap.id DESC
    `);
    res.json(rows.map(r => mapRow(r)));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/agents/user/:userId', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT ap.*, u.username FROM agent_profiles ap
      JOIN users u ON ap.user_id = u.id
      WHERE ap.user_id = ?
    `, [req.params.userId]);
    if (rows.length === 0) return res.status(404).json({ error: 'Profile not found' });
    res.json(mapRow(rows[0]));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/agents/:id', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT ap.*, u.username FROM agent_profiles ap
      JOIN users u ON ap.user_id = u.id
      WHERE ap.id = ?
    `, [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Profile not found' });
    res.json(mapRow(rows[0]));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/agents/:id', async (req, res) => {
  const { companyName, phone, location, logoPath, socialFacebook, socialInstagram, socialWebsite } = req.body;
  try {
    const fields = [];
    const params = [];
    const add = (col, val) => {
      fields.push(`${col} = ?`);
      params.push(val);
    };

    if (companyName !== undefined) add('company_name', companyName);
    if (phone !== undefined) add('phone', phone);
    if (location !== undefined) add('location', location);
    if (logoPath !== undefined) add('logo_path', saveBase64Image(logoPath));
    if (socialFacebook !== undefined) add('social_facebook', socialFacebook);
    if (socialInstagram !== undefined) add('social_instagram', socialInstagram);
    if (socialWebsite !== undefined) add('social_website', socialWebsite);

    if (fields.length === 0) return res.json({ success: true });

    params.push(req.params.id);
    await pool.query(`UPDATE agent_profiles SET ${fields.join(', ')} WHERE id = ?`, params);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// BOOKINGS ENDPOINTS
app.get('/api/bookings', async (req, res) => {
  const { userId, agentId } = req.query;
  try {
    let query = `
      SELECT b.*, u.username, tp.destination, ap.company_name,
             (SELECT COUNT(*) FROM reviews r WHERE r.booking_id = b.id AND r.status = 'active') as review_count
      FROM bookings b
      JOIN users u ON b.user_id = u.id
      JOIN travel_packages tp ON b.package_id = tp.id
      JOIN agent_profiles ap ON b.agent_id = ap.id
    `;
    const conditions = [];
    const params = [];

    if (userId) {
      conditions.push('b.user_id = ?');
      params.push(userId);
    }
    if (agentId) {
      conditions.push('b.agent_id = ?');
      params.push(agentId);
    }

    if (conditions.length > 0) {
      query += ` WHERE ${conditions.join(' AND ')}`;
    }
    query += ' ORDER BY b.id DESC';

    const [rows] = await pool.query(query, params);
    res.json(rows.map(r => mapRow(r)));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/bookings/stats', async (req, res) => {
  try {
    const getCount = async (q) => {
      const [rows] = await pool.query(q);
      return rows[0].cnt;
    };
    const total = await getCount('SELECT COUNT(*) as cnt FROM bookings');
    const confirmed = await getCount("SELECT COUNT(*) as cnt FROM bookings WHERE status = 'confirmed'");
    const pending = await getCount("SELECT COUNT(*) as cnt FROM bookings WHERE status = 'pending'");
    const completed = await getCount("SELECT COUNT(*) as cnt FROM bookings WHERE status = 'completed'");

    res.json({ total, confirmed, pending, completed });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/bookings/:id', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT b.*, u.username, tp.destination, ap.company_name,
             (SELECT COUNT(*) FROM reviews r WHERE r.booking_id = b.id AND r.status = 'active') as review_count
      FROM bookings b
      JOIN users u ON b.user_id = u.id
      JOIN travel_packages tp ON b.package_id = tp.id
      JOIN agent_profiles ap ON b.agent_id = ap.id
      WHERE b.id = ?
    `, [req.params.id]);

    if (rows.length === 0) return res.status(404).json({ error: 'Booking not found' });
    res.json(mapRow(rows[0]));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/bookings', async (req, res) => {
  const { userId, packageId, agentId, guestName, icPassport, numPeople, travelDate, unitPrice, specialRequirements, voucherCode } = req.body;
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    let discount = 0;
    const subtotal = unitPrice * numPeople;

    if (voucherCode) {
      const [vouchers] = await connection.query('SELECT * FROM vouchers WHERE code = ? LIMIT 1', [voucherCode.toUpperCase()]);
      if (vouchers.length > 0) {
        const voucher = vouchers[0];
        if (voucher.discount_type === 'percent') {
          discount = (subtotal * parseFloat(voucher.discount_value)) / 100;
        } else {
          discount = parseFloat(voucher.discount_value);
        }
        if (subtotal < parseFloat(voucher.min_purchase)) {
          discount = 0;
        }
        if (discount > 0) {
          await connection.query('UPDATE vouchers SET used_count = used_count + 1 WHERE id = ?', [voucher.id]);
        }
      }
    }

    const totalPrice = subtotal - discount;
    const [insertRes] = await connection.query(
      `INSERT INTO bookings (user_id, package_id, agent_id, guest_name, ic_passport, num_people, special_requirements, voucher_code, discount_amount, total_price, travel_date)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [userId, packageId, agentId, guestName, icPassport, numPeople, specialRequirements, voucherCode, discount, totalPrice, travelDate.split('T')[0]]
    );
    const bookingId = insertRes.insertId;

    // Create notification
    await connection.query(
      'INSERT INTO notifications (user_id, title, message) VALUES (?, "Booking Submitted", ?)',
      [userId, `Your booking #${bookingId} has been submitted. Please complete payment.`]
    );

    await connection.commit();
    res.json({ id: bookingId });
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ error: err.message });
  } finally {
    connection.release();
  }
});

app.post('/api/bookings/:id/pay', async (req, res) => {
  const { userId } = req.body;
  try {
    await pool.query(
      `UPDATE bookings SET payment_status = 'paid', status = 'confirmed' WHERE id = ? AND user_id = ?`,
      [req.params.id, userId]
    );
    await pool.query(
      'INSERT INTO notifications (user_id, title, message) VALUES (?, "Payment Confirmed", ?)',
      [userId, `Payment for booking #${req.params.id} confirmed. Your trip is booked!`]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/bookings/:id/status', async (req, res) => {
  const { status, agentId } = req.body;
  try {
    let query = 'UPDATE bookings SET status = ? WHERE id = ?';
    const params = [status, req.params.id];
    if (agentId !== undefined) {
      query += ' AND agent_id = ?';
      params.push(agentId);
    }
    await pool.query(query, params);

    // Get user id for notification
    const [rows] = await pool.query('SELECT user_id FROM bookings WHERE id = ?', [req.params.id]);
    if (rows.length > 0) {
      await pool.query(
        'INSERT INTO notifications (user_id, title, message) VALUES (?, "Booking Update", ?)',
        [rows[0].user_id, `Booking #${req.params.id} status changed to ${status}.`]
      );
    }
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// REVIEWS ENDPOINTS
app.get('/api/reviews/can-review', async (req, res) => {
  const { userId, bookingId } = req.query;
  try {
    const [bookingRes] = await pool.query(
      "SELECT id FROM bookings WHERE id = ? AND user_id = ? AND (status = 'completed' OR status = 'confirmed') LIMIT 1",
      [bookingId, userId]
    );
    if (bookingRes.length === 0) return res.json({ canReview: false });

    const [reviewRes] = await pool.query('SELECT id FROM reviews WHERE booking_id = ? LIMIT 1', [bookingId]);
    res.json({ canReview: reviewRes.length === 0 });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/reviews', async (req, res) => {
  const { packageId, agentId, userId } = req.query;
  try {
    const conditions = ["r.status != 'removed'"];
    const params = [];

    if (packageId) { conditions.push('r.package_id = ?'); params.push(packageId); }
    if (agentId) { conditions.push('r.agent_id = ?'); params.push(agentId); }
    if (userId) { conditions.push('r.user_id = ?'); params.push(userId); }

    const [rows] = await pool.query(`
      SELECT r.*, u.username, tp.destination, ap.company_name
      FROM reviews r
      JOIN users u ON r.user_id = u.id
      JOIN travel_packages tp ON r.package_id = tp.id
      JOIN agent_profiles ap ON r.agent_id = ap.id
      WHERE ${conditions.join(' AND ')}
      ORDER BY r.id DESC
    `, params);

    res.json(rows.map(r => mapRow(r)));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/reviews/avg/:packageId', async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT AVG(rating) as avg_r FROM reviews WHERE package_id = ? AND status = 'active'",
      [req.params.packageId]
    );
    res.json({ avgRating: parseFloat(rows[0].avg_r || 0) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/reviews', async (req, res) => {
  const { userId, packageId, agentId, bookingId, rating, comment } = req.body;
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    // Check duplicate/valid
    const [bookingRes] = await connection.query(
      "SELECT id FROM bookings WHERE id = ? AND user_id = ? AND (status = 'completed' OR status = 'confirmed') LIMIT 1",
      [bookingId, userId]
    );
    if (bookingRes.length === 0) throw new Error('Reviews only allowed after trip completion.');

    const [reviewRes] = await connection.query('SELECT id FROM reviews WHERE booking_id = ? LIMIT 1', [bookingId]);
    if (reviewRes.length > 0) throw new Error('Already reviewed.');

    await connection.query(
      'INSERT INTO reviews (user_id, package_id, agent_id, booking_id, rating, comment) VALUES (?, ?, ?, ?, ?, ?)',
      [userId, packageId, agentId, bookingId, rating, comment]
    );

    // Update agent average rating
    const [avgRes] = await connection.query("SELECT AVG(rating) as avg_r FROM reviews WHERE agent_id = ? AND status = 'active'", [agentId]);
    const avg = parseFloat(avgRes[0].avg_r || 0);
    await connection.query('UPDATE agent_profiles SET rating = ? WHERE id = ?', [avg, agentId]);

    await connection.commit();
    res.json({ success: true });
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ error: err.message });
  } finally {
    connection.release();
  }
});

app.post('/api/reviews/:id/report', async (req, res) => {
  const { reporterId, reason } = req.body;
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    await connection.query('INSERT INTO review_reports (review_id, reporter_id, reason) VALUES (?, ?, ?)', [req.params.id, reporterId, reason]);
    await connection.query("UPDATE reviews SET status = 'reported' WHERE id = ?", [req.params.id]);
    await connection.commit();
    res.json({ success: true });
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ error: err.message });
  } finally {
    connection.release();
  }
});

app.put('/api/reviews/:id/moderate', async (req, res) => {
  const { status } = req.body;
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    await connection.query('UPDATE reviews SET status = ? WHERE id = ?', [status, req.params.id]);
    
    if (status === 'removed') {
      const [rows] = await connection.query('SELECT agent_id FROM reviews WHERE id = ?', [req.params.id]);
      if (rows.length > 0) {
        const agentId = rows[0].agent_id;
        const [avgRes] = await connection.query("SELECT AVG(rating) as avg_r FROM reviews WHERE agent_id = ? AND status = 'active'", [agentId]);
        const avg = parseFloat(avgRes[0].avg_r || 0);
        await connection.query('UPDATE agent_profiles SET rating = ? WHERE id = ?', [avg, agentId]);
      }
    }
    await connection.commit();
    res.json({ success: true });
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ error: err.message });
  } finally {
    connection.release();
  }
});

app.get('/api/reviews/reports', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT rr.*, r.comment, r.rating, u.username as reporter_name
      FROM review_reports rr
      JOIN reviews r ON rr.review_id = r.id
      JOIN users u ON rr.reporter_id = u.id
      WHERE rr.status = 'pending'
      ORDER BY rr.id DESC
    `);
    res.json(rows.map(r => ({
      id: r.id,
      reviewId: r.review_id,
      reason: r.reason,
      comment: r.comment,
      rating: r.rating,
      reporter: r.reporter_name
    })));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// VOUCHERS ENDPOINTS
app.get('/api/vouchers', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM vouchers ORDER BY id DESC');
    res.json(rows.map(r => mapRow(r)));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/vouchers/:code', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM vouchers WHERE code = ? LIMIT 1', [req.params.code.toUpperCase()]);
    if (rows.length === 0) return res.status(404).json({ error: 'Voucher not found' });
    res.json(mapRow(rows[0]));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/vouchers', async (req, res) => {
  const { code, discountType, discountValue, minPurchase, maxUses, validFrom, validUntil } = req.body;
  try {
    await pool.query(
      `INSERT INTO vouchers (code, discount_type, discount_value, min_purchase, max_uses, valid_from, valid_until)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [code.toUpperCase(), discountType, discountValue, minPurchase || 0, maxUses || 100, validFrom ? validFrom.split('T')[0] : null, validUntil ? validUntil.split('T')[0] : null]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/vouchers/:id', async (req, res) => {
  const { code, discountType, discountValue, minPurchase, maxUses, validFrom, validUntil, status } = req.body;
  try {
    const fields = [];
    const params = [];
    const add = (col, val) => {
      fields.push(`${col} = ?`);
      params.push(val);
    };

    if (code !== undefined) add('code', code.toUpperCase());
    if (discountType !== undefined) add('discount_type', discountType);
    if (discountValue !== undefined) add('discount_value', discountValue);
    if (minPurchase !== undefined) add('min_purchase', minPurchase);
    if (maxUses !== undefined) add('max_uses', maxUses);
    if (validFrom !== undefined) add('valid_from', validFrom ? validFrom.split('T')[0] : null);
    if (validUntil !== undefined) add('valid_until', validUntil ? validUntil.split('T')[0] : null);
    if (status !== undefined) add('status', status);

    if (fields.length === 0) return res.json({ success: true });

    params.push(req.params.id);
    await pool.query(`UPDATE vouchers SET ${fields.join(', ')} WHERE id = ?`, params);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/vouchers/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM vouchers WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PROMOTIONS ENDPOINTS
app.get('/api/promotions', async (req, res) => {
  const { activeOnly } = req.query;
  try {
    let query = `
      SELECT p.*, tp.destination as package_destination
      FROM promotions p
      LEFT JOIN travel_packages tp ON p.package_id = tp.id
    `;
    if (activeOnly) {
      query += " WHERE p.status = 'active'";
    }
    query += ' ORDER BY p.id DESC';

    const [rows] = await pool.query(query);
    res.json(rows.map(r => mapRow(r)));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/promotions', async (req, res) => {
  const { title, description, discountPercent, packageId, validFrom, validUntil } = req.body;
  try {
    await pool.query(
      `INSERT INTO promotions (title, description, discount_percent, package_id, valid_from, valid_until)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [title, description, discountPercent, packageId || null, validFrom ? validFrom.split('T')[0] : null, validUntil ? validUntil.split('T')[0] : null]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/promotions/:id', async (req, res) => {
  const { title, description, discountPercent, packageId, validFrom, validUntil, status } = req.body;
  try {
    const fields = [];
    const params = [];
    const add = (col, val) => {
      fields.push(`${col} = ?`);
      params.push(val);
    };

    if (title !== undefined) add('title', title);
    if (description !== undefined) add('description', description);
    if (discountPercent !== undefined) add('discount_percent', discountPercent);
    if (packageId !== undefined) add('package_id', packageId);
    if (validFrom !== undefined) add('valid_from', validFrom ? validFrom.split('T')[0] : null);
    if (validUntil !== undefined) add('valid_until', validUntil ? validUntil.split('T')[0] : null);
    if (status !== undefined) add('status', status);

    if (fields.length === 0) return res.json({ success: true });

    params.push(req.params.id);
    await pool.query(`UPDATE promotions SET ${fields.join(', ')} WHERE id = ?`, params);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/promotions/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM promotions WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// NOTIFICATIONS ENDPOINTS
app.get('/api/notifications', async (req, res) => {
  const { userId, agentId } = req.query;
  try {
    let query = '';
    const params = [];
    if (userId) {
      query = `
        SELECT * FROM notifications
        WHERE user_id = ? OR target_role = 'all'
        ORDER BY id DESC LIMIT 50
      `;
      params.push(userId);
    } else if (agentId) {
      query = `
        SELECT * FROM notifications
        WHERE agent_id = ? OR target_role = 'all'
        ORDER BY id DESC LIMIT 50
      `;
      params.push(agentId);
    } else {
      query = 'SELECT * FROM notifications ORDER BY id DESC LIMIT 100';
    }

    const [rows] = await pool.query(query, params);
    res.json(rows.map(r => mapRow(r)));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/notifications/unread-count', async (req, res) => {
  const { userId } = req.query;
  try {
    const [rows] = await pool.query('SELECT COUNT(*) as cnt FROM notifications WHERE user_id = ? AND is_read = 0', [userId]);
    res.json({ count: rows[0].cnt });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/notifications', async (req, res) => {
  const { userId, agentId, targetRole, title, message } = req.body;
  try {
    await pool.query(
      'INSERT INTO notifications (user_id, agent_id, target_role, title, message) VALUES (?, ?, ?, ?, ?)',
      [userId || null, agentId || null, targetRole || 'user', title, message]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/notifications/broadcast', async (req, res) => {
  const { targetRole, title, message } = req.body;
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    if (targetRole === 'user' || targetRole === 'all') {
      const [users] = await connection.query("SELECT id FROM users WHERE role = 'user' AND status = 'active'");
      for (const u of users) {
        await connection.query(
          "INSERT INTO notifications (user_id, target_role, title, message) VALUES (?, 'user', ?, ?)",
          [u.id, title, message]
        );
      }
    }
    if (targetRole === 'agent' || targetRole === 'all') {
      const [agents] = await connection.query('SELECT id FROM agent_profiles');
      for (const a of agents) {
        await connection.query(
          "INSERT INTO notifications (agent_id, target_role, title, message) VALUES (?, 'agent', ?, ?)",
          [a.id, title, message]
        );
      }
    }

    await connection.commit();
    res.json({ success: true });
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ error: err.message });
  } finally {
    connection.release();
  }
});

app.put('/api/notifications/read-all', async (req, res) => {
  const { userId, agentId } = req.body;
  try {
    if (userId) {
      await pool.query('UPDATE notifications SET is_read = 1 WHERE user_id = ?', [userId]);
    } else if (agentId) {
      await pool.query('UPDATE notifications SET is_read = 1 WHERE agent_id = ?', [agentId]);
    } else {
      return res.status(400).json({ error: 'Missing userId or agentId' });
    }
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/notifications/:id/read', async (req, res) => {
  try {
    await pool.query('UPDATE notifications SET is_read = 1 WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// CHAT ENDPOINTS
app.post('/api/chats/message', async (req, res) => {
  const { senderId, receiverId, message } = req.body;
  try {
    await pool.query(
      'INSERT INTO chat_messages (sender_id, receiver_id, message) VALUES (?, ?, ?)',
      [senderId, receiverId, message]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/chats/conversation', async (req, res) => {
  const { user1, user2 } = req.query;
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [rows] = await connection.query(`
      SELECT cm.*, u.username as sender_name
      FROM chat_messages cm
      JOIN users u ON cm.sender_id = u.id
      WHERE (cm.sender_id = ? AND cm.receiver_id = ?)
         OR (cm.sender_id = ? AND cm.receiver_id = ?)
      ORDER BY cm.created_at ASC
    `, [user1, user2, user2, user1]);

    await connection.query(
      'UPDATE chat_messages SET is_read = 1 WHERE sender_id = ? AND receiver_id = ? AND is_read = 0',
      [user2, user1]
    );

    await connection.commit();
    res.json(rows.map(r => mapRow(r)));
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ error: err.message });
  } finally {
    connection.release();
  }
});

app.get('/api/chats/contacts/:userId', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT DISTINCT
        CASE WHEN cm.sender_id = ? THEN cm.receiver_id ELSE cm.sender_id END as contact_id,
        u.username, u.role,
        ap.company_name
      FROM chat_messages cm
      JOIN users u ON u.id = CASE WHEN cm.sender_id = ? THEN cm.receiver_id ELSE cm.sender_id END
      LEFT JOIN agent_profiles ap ON ap.user_id = u.id
      WHERE cm.sender_id = ? OR cm.receiver_id = ?
    `, [req.params.userId, req.params.userId, req.params.userId, req.params.userId]);

    res.json(rows.map(r => ({
      userId: r.contact_id,
      username: r.username,
      role: r.role,
      companyName: r.company_name || ''
    })));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ITINERARY ENDPOINTS
app.get('/api/itineraries', async (req, res) => {
  const { bookingId } = req.query;
  try {
    const [rows] = await pool.query(
      'SELECT * FROM itinerary_items WHERE booking_id = ? ORDER BY day_number, time_slot',
      [bookingId]
    );
    res.json(rows.map(r => mapRow(r)));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/itineraries', async (req, res) => {
  const { bookingId, dayNumber, timeSlot, activity, location, notes } = req.body;
  try {
    const [insertRes] = await pool.query(
      'INSERT INTO itinerary_items (booking_id, day_number, time_slot, activity, location, notes) VALUES (?, ?, ?, ?, ?, ?)',
      [bookingId, dayNumber, timeSlot, activity, location, notes || null]
    );
    res.json({ id: insertRes.insertId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/itineraries/:id', async (req, res) => {
  const { activity, location, notes, timeSlot } = req.body;
  try {
    const fields = [];
    const params = [];
    if (activity !== undefined) { fields.push('activity = ?'); params.push(activity); }
    if (location !== undefined) { fields.push('location = ?'); params.push(location); }
    if (notes !== undefined) { fields.push('notes = ?'); params.push(notes); }
    if (timeSlot !== undefined) { fields.push('time_slot = ?'); params.push(timeSlot); }

    if (fields.length === 0) return res.json({ success: true });

    params.push(req.params.id);
    await pool.query(`UPDATE itinerary_items SET ${fields.join(', ')} WHERE id = ?`, params);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/itineraries/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM itinerary_items WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// WISHLIST ENDPOINTS
app.get('/api/wishlist/:userId', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT package_id FROM wishlists WHERE user_id = ? ORDER BY created_at DESC', [req.params.userId]);
    res.json(rows.map(r => r.package_id));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/wishlist/:userId/:packageId', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id FROM wishlists WHERE user_id = ? AND package_id = ? LIMIT 1', [req.params.userId, req.params.packageId]);
    res.json({ isWishlisted: rows.length > 0 });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/wishlist/toggle', async (req, res) => {
  const { userId, packageId } = req.body;
  try {
    const [existing] = await pool.query('SELECT id FROM wishlists WHERE user_id = ? AND package_id = ? LIMIT 1', [userId, packageId]);
    if (existing.length > 0) {
      await pool.query('DELETE FROM wishlists WHERE user_id = ? AND package_id = ?', [userId, packageId]);
      res.json({ wishlisted: false });
    } else {
      await pool.query('INSERT INTO wishlists (user_id, package_id) VALUES (?, ?)', [userId, packageId]);
      res.json({ wishlisted: true });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// NEWS ENDPOINTS
app.get('/api/news', async (req, res) => {
  const { publishedOnly } = req.query;
  try {
    let query = 'SELECT * FROM travel_news';
    if (publishedOnly) {
      query += " WHERE status = 'published'";
    }
    query += ' ORDER BY created_at DESC';
    const [rows] = await pool.query(query);
    res.json(rows.map(r => mapRow(r)));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/news', async (req, res) => {
  const { title, content, imagePath, author, status } = req.body;
  try {
    const [insertRes] = await pool.query(
      'INSERT INTO travel_news (title, content, image_path, author, status) VALUES (?, ?, ?, ?, ?)',
      [title, content, imagePath || null, author || 'Admin', status || 'published']
    );
    res.json({ id: insertRes.insertId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/news/:id', async (req, res) => {
  const { title, content, imagePath, status } = req.body;
  try {
    const fields = [];
    const params = [];
    if (title !== undefined) { fields.push('title = ?'); params.push(title); }
    if (content !== undefined) { fields.push('content = ?'); params.push(content); }
    if (imagePath !== undefined) { fields.push('image_path = ?'); params.push(imagePath); }
    if (status !== undefined) { fields.push('status = ?'); params.push(status); }

    if (fields.length === 0) return res.json({ success: true });

    params.push(req.params.id);
    await pool.query(`UPDATE travel_news SET ${fields.join(', ')} WHERE id = ?`, params);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/news/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM travel_news WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// SYSTEM SETTINGS ENDPOINTS
app.get('/api/settings', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM system_settings');
    const settings = {};
    for (const r of rows) {
      settings[r.setting_key] = r.setting_value;
    }
    res.json(settings);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/settings', async (req, res) => {
  const { key, value } = req.body;
  try {
    await pool.query(
      'INSERT INTO system_settings (setting_key, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = ?',
      [key, value, value]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ADMIN ENDPOINTS
app.get('/api/admin/users', async (req, res) => {
  const { role } = req.query;
  try {
    let query = 'SELECT * FROM users';
    const params = [];
    if (role) {
      query += ' WHERE role = ?';
      params.push(role);
    }
    query += ' ORDER BY id DESC';
    const [rows] = await pool.query(query, params);
    res.json(rows.map(r => mapRow(r)));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/admin/users/:id/status', async (req, res) => {
  const { status } = req.body;
  try {
    await pool.query('UPDATE users SET status = ? WHERE id = ?', [status, req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/admin/users/:id', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const userId = req.params.id;

    // Clean up chats & notifications
    await connection.query('DELETE FROM chat_messages WHERE sender_id = ? OR receiver_id = ?', [userId, userId]);
    await connection.query('DELETE FROM notifications WHERE user_id = ?', [userId]);

    // Check agent profile
    const [agents] = await connection.query('SELECT id FROM agent_profiles WHERE user_id = ?', [userId]);
    if (agents.length > 0) {
      const agentProfileId = agents[0].id;
      await connection.query('DELETE FROM notifications WHERE agent_id = ?', [agentProfileId]);
      await connection.query('DELETE FROM reviews WHERE agent_id = ?', [agentProfileId]);
      await connection.query('DELETE FROM package_images WHERE package_id IN (SELECT id FROM travel_packages WHERE agent_id = ?)', [agentProfileId]);
      await connection.query('DELETE FROM bookings WHERE agent_id = ?', [agentProfileId]);
      await connection.query('DELETE FROM travel_packages WHERE agent_id = ?', [agentProfileId]);
      await connection.query('DELETE FROM agent_profiles WHERE id = ?', [agentProfileId]);
    }

    // Clean user bookings/reviews
    await connection.query('DELETE FROM reviews WHERE user_id = ?', [userId]);
    await connection.query('DELETE FROM bookings WHERE user_id = ?', [userId]);
    await connection.query('DELETE FROM users WHERE id = ?', [userId]);

    await connection.commit();
    res.json({ success: true });
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ error: err.message });
  } finally {
    connection.release();
  }
});

app.put('/api/admin/users/:id/password', async (req, res) => {
  const { password } = req.body;
  try {
    await pool.query('UPDATE users SET password = ? WHERE id = ?', [password, req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/admin/users', async (req, res) => {
  const { username, password, email, fullName, role, phone, icPassport, companyName, location } = req.body;
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [check] = await connection.query('SELECT id FROM users WHERE username = ? OR email = ?', [username, email]);
    if (check.length > 0) throw new Error('Username or email already exists');

    const memberId = await generateId('MEM', 'users', 'member_id');
    const [userRes] = await connection.query(
      `INSERT INTO users (member_id, username, password, email, role, full_name, phone, ic_passport, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'active')`,
      [memberId, username, password, email, role, fullName, phone || '', icPassport || '']
    );
    const userId = userRes.insertId;

    if (role === 'agent') {
      const agentId = await generateId('AGT', 'agent_profiles', 'agent_id');
      await connection.query(
        'INSERT INTO agent_profiles (agent_id, user_id, company_name, phone, location) VALUES (?, ?, ?, ?, ?)',
        [agentId, userId, companyName || fullName, phone || '', location || '']
      );
    }

    await connection.commit();
    res.json({ success: true });
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ error: err.message });
  } finally {
    connection.release();
  }
});

app.get('/api/admin/stats', async (req, res) => {
  try {
    const getCount = async (q) => {
      const [rows] = await pool.query(q);
      return rows[0].cnt;
    };
    const [revRes] = await pool.query("SELECT SUM(total_price) as rev FROM bookings WHERE payment_status = 'paid'");
    const revenue = parseFloat(revRes[0].rev || 0);

    const stats = {
      users: await getCount("SELECT COUNT(*) as cnt FROM users WHERE role = 'user'"),
      agents: await getCount("SELECT COUNT(*) as cnt FROM users WHERE role = 'agent'"),
      packages: await getCount("SELECT COUNT(*) as cnt FROM travel_packages WHERE status = 'active'"),
      bookings: await getCount('SELECT COUNT(*) as cnt FROM bookings'),
      reviews: await getCount("SELECT COUNT(*) as cnt FROM reviews WHERE status = 'active'"),
      reports: await getCount("SELECT COUNT(*) as cnt FROM review_reports WHERE status = 'pending'"),
      revenue: Math.floor(revenue)
    };
    res.json(stats);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Start server
initDb().then(() => {
  app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
  });
});
