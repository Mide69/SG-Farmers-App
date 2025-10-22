const { Pool } = require('pg');
const { Client } = require('@elastic/elasticsearch');

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

// Elasticsearch connection
const esClient = new Client({
  node: process.env.ELASTICSEARCH_URL || 'http://localhost:9200'
});

// Sync farmers data to Elasticsearch
async function syncFarmersToElasticsearch() {
  try {
    console.log('Starting farmers sync to Elasticsearch...');
    
    // Get all farmers from database
    const result = await pool.query('SELECT * FROM farmers');
    const farmers = result.rows;
    
    console.log(`Found ${farmers.length} farmers to sync`);
    
    // Prepare bulk operations
    const body = [];
    
    for (const farmer of farmers) {
      // Index operation
      body.push({
        index: {
          _index: 'farmers',
          _id: farmer.id
        }
      });
      
      // Document data with autocomplete suggestions
      const suggestions = [
        farmer.name,
        farmer.farm_location,
        ...(farmer.crop_types || [])
      ].filter(Boolean);
      
      body.push({
        id: farmer.id,
        name: farmer.name,
        email: farmer.email,
        farm_location: farmer.farm_location,
        farm_size: farmer.farm_size,
        crop_types: farmer.crop_types,
        created_at: farmer.created_at,
        suggest: {
          input: suggestions,
          weight: 1
        }
      });
    }
    
    if (body.length > 0) {
      // Bulk index to Elasticsearch
      const bulkResponse = await esClient.bulk({ body });
      
      if (bulkResponse.body.errors) {
        console.error('Bulk indexing errors:', bulkResponse.body.items.filter(item => item.index.error));
      } else {
        console.log(`Successfully synced ${farmers.length} farmers to Elasticsearch`);
      }
    }
    
  } catch (error) {
    console.error('Sync error:', error);
  }
}

// Run sync if called directly
if (require.main === module) {
  syncFarmersToElasticsearch()
    .then(() => {
      console.log('Sync completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Sync failed:', error);
      process.exit(1);
    });
}

module.exports = { syncFarmersToElasticsearch };