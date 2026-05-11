//Google earth engine
//get sentinel-2
var image = s2.filterBounds(aoi)
  .filterDate('2024-01-01', '2024-12-31')
  .map(cloudMask)
  .median()
  .clip(aoi);
Map.centerObject(aoi, 10)
Map.addLayer(image, {bands: ['B4', 'B3', 'B2'], min: 0, max: 3000}, 'True color')
Map.addLayer(image, {bands: ['B8', 'B11', 'B12'], min: 0, max: 3000}, 'False Composite');

//cloud masking
function cloudMask(image){
  var scl = image.select('SCL');
  var mask = scl.eq(3).or(scl.gte(7).and(scl.lte(10)));
  return image.updateMask(mask.eq(0));
}

//classification
// 1. load trainingsample
var sampel = ee.FeatureCollection('projects/ee-talitha297/assets/TrainingDataFIX4');

// 2. choose band
var bands = ['B2', 'B3', 'B4', 'B8', 'B11', 'B12']; // Blue, Green, Red, NIR, SWIR1, SWIR2

// 3. sampling
var training = image.select(bands).sampleRegions({
  collection: sampel,
  properties: ['Kelas'], 
  scale: 10
});

// 4. train model
var classifier = ee.Classifier.smileRandomForest(1000).train({
  features: training,
  classProperty: 'Kelas',
  inputProperties: bands
});

// 5. classification
var klasifikasi = image.select(bands).classify(classifier);

// 6. display result
Map.addLayer(klasifikasi, 
  {min: 1, max: 5, palette: ['#006400', '#FFD700', '#808080', '#8B4513', '#EE9A1C']}, 
  'Hasil Klasifikasi');

//export
Export.image.toDrive({
 image: klasifikasi,
 description: 'hasil_klasifikasi_training4',
 scale: 30,
 region: aoi,
 fileFormat: 'GeoTIFF',
 });