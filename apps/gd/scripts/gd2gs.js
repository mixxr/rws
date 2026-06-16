// use trigger to run main() every 15 minutes, or call main() directly for testing

// in GApps Script: before running this code, enable "Drive API" (in Services) in the Google Cloud Console for your project

// Replace these with your own values
const service_account = {
  private_key: '-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0.....\n-----END PRIVATE KEY-----\n',
  client_email: '<service-account>@<project>.iam.gserviceaccount.com'
};

const getStorageService = () =>
  OAuth2.createService('FirestoreStorage')
    .setPrivateKey(service_account.private_key)
    .setIssuer(service_account.client_email)
    .setPropertyStore(PropertiesService.getUserProperties())
    .setCache(CacheService.getUserCache())
    .setTokenUrl('https://oauth2.googleapis.com/token')
    .setScope('https://www.googleapis.com/auth/devstorage.read_write');

// Replace these with your own values
// const DRIVE_FILE_ID = '1P77Wg3....a4TKZ';
const DRIVE_FOLDER_ID = '1Wr0s...jojiIF'; // the ID of the Google Drive folder you want to monitor, e.g. "1Wr0s...jojiIF"
const STORAGE_BUCKET = '<your-bucket-name>'; // the name of your Cloud Storage bucket, e.g. "my-bucket"
const FILE_PATH = '<your-folder-in-bucket>'; // literally the path in the bucket, e.g. "myfolder" or "myfolder/subfolder"

const toNdjson = (array) => {
  return array.map(obj => JSON.stringify(obj)).join("\n");
}

const uploadBlobToGCS =(filename, blob) => {
  const API = `https://www.googleapis.com/upload/storage/v1/b`;
  const location = encodeURIComponent(`${FILE_PATH}/${filename}`);
  const url = `${API}/${STORAGE_BUCKET}/o?uploadType=media&name=${location}`;

  const service = getStorageService();
  const accessToken = service.getAccessToken();

  const response = UrlFetchApp.fetch(url, {
    method: 'POST',
    contentType: blob.getContentType(),
    payload: blob.getBytes(),
    headers: { Authorization: `Bearer ${accessToken}` }
  });

  const result = JSON.parse(response.getContentText());
  Logger.log(JSON.stringify(result, null, 2));
  return result.timeCreated !== null;
}
const splitAndUploadFileToCloudStorage = (gdrive_fid) => {
  const file = DriveApp.getFileById(gdrive_fid);
  const filename = file.getName();
  const blob = file.getBlob();

  // 1. Read JSON
  const jsonText = blob.getDataAsString("utf-8");
  let json;
  try {
    json = JSON.parse(jsonText);
  } catch (e) {
    console.error("Invalid JSON:", filename, e);
    return false;
  }

  // 2. Upload original JSON file as-is
  const ok1 = uploadBlobToGCS(filename, blob);

  // 3. Extract "details" → <filename>-details.json
  if (json.details) {
    const djson = JSON.stringify(json.details, null, 2);
    const detailsBlob = Utilities.newBlob(
      djson,
      "application/json",
      filename.replace(/\.json$/i, "") + "-details.json"
    );
    var ok2 = uploadBlobToGCS(detailsBlob.getName(), detailsBlob);
  } else {
    console.warn("No 'details' section in", filename);
    var ok2 = true; // do not block processing
  }

  // 4. Extract underlyings[] → NDJSON → <filename>-tickers.json
  if (Array.isArray(json.underlyings)) {
    const ndjson = toNdjson(json.underlyings);
    const tickersBlob = Utilities.newBlob(
      ndjson,
      "application/x-ndjson",
      filename.replace(/\.json$/i, "") + "-tickers.json"
    );
    var ok3 = uploadBlobToGCS(tickersBlob.getName(), tickersBlob);
  } else {
    console.warn("No 'underlyings' array in", filename);
    var ok3 = true;
  }

  // 5. Extract ex_dates[] → NDJSON → <filename>-ex_dates.json
  if (Array.isArray(json.ex_dates)) {
    const ndjson = toNdjson(json.ex_dates);
    const eBlob = Utilities.newBlob(
      ndjson,
      "application/x-ndjson",
      filename.replace(/\.json$/i, "") + "-ex_dates.json"
    );
    var ok4 = uploadBlobToGCS(eBlob.getName(), eBlob);
  } else {
    console.warn("No 'underlyings' array in", filename);
    var ok4 = true;
  }

  return ok1 && ok2 && ok3 && ok4;
};

const uploadFileToCloudStorage = (gdrive_fid) => {
  const file = DriveApp.getFileById(gdrive_fid);
  console.log("Reading", gdrive_fid, file.getId());
  const blob = file.getBlob();
  const bytes = blob.getBytes();

  const API = `https://www.googleapis.com/upload/storage/v1/b`;
  const location = encodeURIComponent(`${FILE_PATH}/${file.getName()}`);
  const url = `${API}/${STORAGE_BUCKET}/o?uploadType=media&name=${location}`;

  const service = getStorageService();
  const accessToken = service.getAccessToken();

  const response = UrlFetchApp.fetch(url, {
    method: 'POST',
    contentLength: bytes.length,
    contentType: blob.getContentType(),
    payload: bytes,
    headers: {
      Authorization: `Bearer ${accessToken}`
    }
  });

  const result = JSON.parse(response.getContentText());
  Logger.log(JSON.stringify(result, null, 2));

  return (result.timeCreated !== null);
};

function moveFileToDone(fileId, parentFolderId) {
  // Ensure "done" subfolder exists
  const parent = DriveApp.getFolderById(parentFolderId);
  let doneFolder;
  const subfolders = parent.getFoldersByName("done");

  if (subfolders.hasNext()) {
    doneFolder = subfolders.next();
  } else {
    doneFolder = parent.createFolder("done");
  }

  const doneFolderId = doneFolder.getId();

  // Get file with parents field included
  const file = Drive.Files.get(fileId, { fields: "id, parents" });

  const previousParents = (file.parents || [])
    .map(p => p.id)
    .join(',');


  // Move file using Drive API
  Drive.Files.update(
    {},
    fileId,
    null,
    {
      addParents: doneFolderId,
      removeParents: previousParents,
      fields: "id, parents"
    }
  );
}


function checkNewFiles(gdrive_folderId) {
  console.log("=====================> Processing folder:", gdrive_folderId);
  const folder = DriveApp.getFolderById(gdrive_folderId);
  const files = folder.getFiles();
  // the cache usage is commented out for simplicity, but you can uncomment it to avoid processing the same file multiple times
  // if the script runs frequently. Just make sure to handle cache expiration appropriately.
  // in this case, the cache is commented out because the processed files are moved to a "done" subfolder, so they won't be processed again anyway.

  // const cache = CacheService.getScriptCache();
  // const known = JSON.parse(cache.get("known") || "[]");
  // const newOnes = [];

  while (files.hasNext()) {
    const f = files.next();
    console.log("=======================> Processing file:", f.getId(), f.getName());
    //if (uploadFileToCloudStorage(f.getId())) {
    if (splitAndUploadFileToCloudStorage(f.getId())) {
      moveFileToDone(f.getId(), gdrive_folderId);
    }else{
      console.error("[ERROR] when moving file:", f.getId(), f.getName());
    }
    //if (!known.includes(f.getId())) {
      //newOnes.push(f.getId());
      // Do something with the new file
      // uploadFileToCloudStorage(f.getId());
      // MailApp.sendEmail("you@example.com", "New file added", f.getName());
    //}else {
    //  console.log("No action, file in cache:", f.getId(), f.getName());
    //}
  } // while

  //cache.put("known", JSON.stringify(known.concat(newOnes)), 21600);
}

const main = () => {
  checkNewFiles(DRIVE_FOLDER_ID);
};