/**
 * A shared helper function used to obtain the full set of directions
 * information between two addresses. Uses the Apps Script Maps Service.
 *
 * @param {String} origin The starting address.
 * @param {String} destination The ending address.
 * @return {Object} The directions response object.
 */
function getDirections_(origin, destination) {
  const directionFinder = Maps.newDirectionFinder();
  directionFinder.setOrigin(origin);
  directionFinder.setDestination(destination);

  var sleepTime = Math.floor(Math.random() * (300 - 100 + 1)) + 100;
  Utilities.sleep(sleepTime);

  const directions = directionFinder.getDirections();

  return directions;
}

/**
 * A custom function that gets the driving distance between two addresses.
 *
 * @param {String} origin The starting address.
 * @param {String} destination The ending address.
 * @return {Number} The distance in miles rounded to 2 decimal points.
 */
function drivingDistanceOneWay(origin, destination) {
  const directions = getDirections_(origin, destination);
  const distance = directions.routes[0].legs[0].distance.value / 1000 * 0.621371;
  const total = Math.round(distance * 100) / 100;

  return total;
}

/**
 * A custom function that gets the driving distance between two addresses round trip.
 *
 * @param {String} origin The starting address.
 * @param {String} destination The ending address.
 * @return {Number} The distance in miles rounded to 2 decimal points.
 */
function drivingDistanceRoundTrip(origin, destination) {
  const directions1 = getDirections_(origin, destination);
  const distance1 = directions1.routes[0].legs[0].distance.value / 1000 * 0.621371;
  
  const directions2 = getDirections_(destination, origin);
  const distance2 = directions2.routes[0].legs[0].distance.value / 1000 * 0.621371;

  const total = Math.round((distance1 + distance2) * 100) / 100;

  return total;
}

/**
 * A custom function that gets the driving time between two addresses.
 *
 * @param {String} origin The starting address.
 * @param {String} destination The ending address.
 * @return {Number} The time in minutes rounded to the nearest 15 minutes.
 */
function drivingTimeOneWay(origin, destination) {
  const directions = getDirections_(origin, destination);
  const time = directions.routes[0].legs[0].duration.value / 60;
  const total = (Math.max(Math.round(time / 15) * 15, 15)) / 60;

  return total;
}

/**
 * A custom function that gets the driving time between two addresses round trip.
 *
 * @param {String} origin The starting address.
 * @param {String} destination The ending address.
 * @return {Number} The distance in meters.
 */
function drivingTimeRoundTrip(origin, destination) {
  const directions1 = getDirections_(origin, destination);
  const time1 = directions1.routes[0].legs[0].duration.value / 60;
  
  const directions2 = getDirections_(destination, origin);
  const time2 = directions2.routes[0].legs[0].duration.value / 60;

  const total = (Math.max(Math.round((time1 + time2) / 15) * 15, 15)) / 60;

  return total;
}

function calculateAllDriving() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName("CLIENT MILEAGE");

  const today = new Date();
  const formattedDate = Utilities.formatDate(today, "EST", "MMMM dd");
  sheet.getRange("G2").setNumberFormat("@").setValue(formattedDate);

  const lastRow = sheet.getLastRow();
  const origin = sheet.getRange('B1').getValue();

  for (let i = 4; i <= lastRow; i++) {
    const currentClient = sheet.getRange(i, 1).getValue();
    sheet.getRange("F1").setValue("Currently Updating:");
    sheet.getRange("G1").setValue(currentClient);

    let destination = sheet.getRange(i,2).getValue();   

    let mileageOneWay = drivingDistanceOneWay(origin, destination);
    let mileageRoundTrip = drivingDistanceRoundTrip(origin, destination);
    let timeRoundTrip = drivingTimeRoundTrip(origin, destination);

    sheet.getRange(i,3).setValue(mileageOneWay);    // Mileage One Way
    sheet.getRange(i,4).setValue(mileageRoundTrip); // Mileage Round Trip
    sheet.getRange(i,5).setValue(timeRoundTrip);    // Time Round Trip
  }
  sheet.getRange("F1").clearContent();
  sheet.getRange("G1").clearContent();
}

function updateClientMileage(e) {
  if (!e || !e.value) return;
  const row = e.range.getRow();
  const column = e.range.getColumn();
  const sheet = e.range.getSheet();

  if (column !== 2) return;
  if (row <= 3) return; 

  const origin = sheet.getRange('B1').getValue();
  const destination = e.value;

  let mileageOneWay = drivingDistanceOneWay(origin, destination);
  let mileageRoundTrip = drivingDistanceRoundTrip(origin, destination);
  let timeRoundTrip = drivingTimeRoundTrip(origin, destination);

  sheet.getRange(row,3).setValue(mileageOneWay);    // Mileage One Way
  sheet.getRange(row,4).setValue(mileageRoundTrip); // Mileage Round Trip
  sheet.getRange(row,5).setValue(timeRoundTrip);    // Time Round Trip
}

function mileageVLookup(e) {
  if (!e || !e.value) return;
  const row = e.range.getRow();
  const column = e.range.getColumn();
  const sheet = e.range.getSheet();
  const client = e.value;

  if (column !== 1) return;
  if (row <= 2) return; 

  const mileageSheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("CLIENT MILEAGE");

  const lastRow = mileageSheet.getLastRow() + 1;

  const mileageRange = mileageSheet.getRange(4, 1, lastRow, 5);
  const mileageValues = mileageRange.getValues();

  const match = mileageValues.find(row => row[0] === client);

  sheet.getRange(row, 2).setValue(match[3]);
  sheet.getRange(row, 3).setValue(match[4]);
}

function onEdit(e) {
  if (!e || !e.value) return;
  const sheet = e.range.getSheet();
  const sheetName = sheet.getName();

  if (sheetName === "CLIENT MILEAGE") {
    updateClientMileage(e);
  } else {
    mileageVLookup(e);
  }
}

function onOpen(e) {
  SpreadsheetApp.getUi()
    .createMenu('Mileage Tools')
    .addItem('Recalculate Mileage', 'calculateAllDriving')
    .addToUi();
}