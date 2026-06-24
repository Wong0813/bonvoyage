const mysql = require('mysql2/promise');

const dbConfig = {
  host: 'localhost',
  port: 3306,
  user: 'root',
  password: '',
  database: 'bonvoyage'
};

async function main() {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [rows] = await connection.query('SELECT id, package_id, image_type, LENGTH(image_path) as len FROM package_images');
    console.log('Total images:', rows.length);
    for (const row of rows) {
      console.log(`Image ID: ${row.id}, Package ID: ${row.package_id}, Type: ${row.image_type}, Size: ${(row.len / 1024 / 1024).toFixed(2)} MB`);
    }
    await connection.end();
  } catch (err) {
    console.error('Error:', err);
  }
}

main();
